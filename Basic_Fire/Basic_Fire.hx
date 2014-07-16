/*

Creating fire effects with particles in Away3D

Demonstrates:

How to setup a particle geometry and particle animationset in order to simulate fire.
How to stagger particle animation instances with different animator objects running on different timers.
How to apply fire lighting to a floor mesh using a multipass material.

Code by Rob Bateman & Liao Cheng
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
liaocheng210@126.com

This code is distributed under the MIT License

Copyright (c) The Away Foundation http://www.theawayfoundation.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

package;

import openfl.display.*;
import openfl.events.*;
import openfl.geom.*;
import openfl.utils.*;

import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.nodes.*;
import away3d.cameras.*;
import away3d.containers.*;
import away3d.controllers.*;
import away3d.core.base.*;
import away3d.entities.*;
import away3d.lights.*;
import away3d.materials.*;
import away3d.materials.lightpickers.*;
import away3d.primitives.*;
import away3d.tools.helpers.*;
import away3d.utils.*;

class Basic_Fire extends Sprite
{
	private static var NUM_FIRES:UInt = 10;
	
	//engine variables
	var scene:Scene3D;
	var camera:Camera3D;
	var view:View3D;
	var cameraController:HoverController;
			
	//material objects
	var planeMaterial:TextureMultiPassMaterial;
	var particleMaterial:TextureMaterial;
	
	//light objects
	var directionalLight:DirectionalLight;
	var lightPicker:StaticLightPicker;
	
	//particle objects
	var fireAnimationSet:ParticleAnimationSet;
	var particleGeometry:ParticleGeometry;
	var timer:Timer;
	
	//scene objects
	var plane:Mesh;
	var fireObjects:Array<FireVO>;
	
	//navigation variables
	var move:Bool = false;
	var lastPanAngle:Float;
	var lastTiltAngle:Float;
	var lastMouseX:Float;
	var lastMouseY:Float;
	
	/**
	 * Constructor
	 */
	public function new()
	{
		super();
		init();
	}
	
	/**
	 * Global initialise function
	 */
	private function init()
	{
		initEngine();
		initLights();
		initMaterials();
		initParticles();
		initObjects();
		initListeners();
	}
	
	/**
	 * Initialise the engine
	 */
	private function initEngine()
	{
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		scene = new Scene3D();
		
		camera = new Camera3D();
		
		view = new View3D();
		view.antiAlias = 4;
		view.scene = scene;
		view.camera = camera;
		
		//setup controller to be used on the camera
		cameraController = new HoverController(camera);
		cameraController.distance = 1000;
		cameraController.minTiltAngle = 0;
		cameraController.maxTiltAngle = 90;
		cameraController.panAngle = 45;
		cameraController.tiltAngle = 20;
		
		addChild(view);
					
        //stats
        this.addChild(new away3d.debug.AwayFPS(view, 10, 10, 0xffffff, 3));
	}
	
	/**
	 * Initialise the lights
	 */
	private function initLights()
	{
		directionalLight = new DirectionalLight(0, -1, 0);
		directionalLight.castsShadows = false;
		directionalLight.color = 0xeedddd;
		directionalLight.diffuse = .5;
		directionalLight.ambient = .5;
		directionalLight.specular = 0;
		directionalLight.ambientColor = 0x808090;
		view.scene.addChild(directionalLight);
		
		lightPicker = new StaticLightPicker([directionalLight]);
	}
	
	/**
	 * Initialise the materials
	 */
	private function initMaterials()
	{
		planeMaterial = new TextureMultiPassMaterial(Cast.bitmapTexture("embeds/floor_diffuse.jpg"));
		planeMaterial.specularMap = Cast.bitmapTexture("embeds/floor_specular.jpg");
		planeMaterial.normalMap = Cast.bitmapTexture("embeds/floor_normal.jpg");
		planeMaterial.lightPicker = lightPicker;
		planeMaterial.repeat = true;
		planeMaterial.mipmap = false;
		planeMaterial.specular = 10;
		
		particleMaterial = new TextureMaterial(Cast.bitmapTexture("embeds/blue.png"));
		particleMaterial.blendMode = BlendMode.ADD;
	}
	
	/**
	 * Initialise the particles
	 */
	private function initParticles()
	{
		
		//create the particle animation set
		fireAnimationSet = new ParticleAnimationSet(true, true);
		
		//add some animations which can control the particles:
		//the global animations can be set directly, because they influence all the particles with the same factor
		fireAnimationSet.addAnimation(new ParticleBillboardNode());
		fireAnimationSet.addAnimation(new ParticleScaleNode(ParticlePropertiesMode.GLOBAL, false, false, 2.5, 0.5));
		fireAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.GLOBAL, new Vector3D(0, 80, 0)));
		fireAnimationSet.addAnimation(new ParticleColorNode(ParticlePropertiesMode.GLOBAL, true, true, false, false, new ColorTransform(0, 0, 0, 1, 0xFF, 0x33, 0x01), new ColorTransform(0, 0, 0, 1, 0x99)));
		
		//no need to set the local animations here, because they influence all the particle with different factors.
		fireAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.LOCAL_STATIC));
		
		//set the initParticleFunc. It will be invoked for the local static property initialization of every particle
		fireAnimationSet.initParticleFunc = initParticleFunc;
		
		//create the original particle geometry
		var particle:Geometry = new PlaneGeometry(10, 10, 1, 1, false);
		
		//combine them into a list
		var geometrySet:Array<Geometry> = new Array<Geometry>();
		for (i in 0...500)
			geometrySet.push(particle);
		
		particleGeometry = ParticleGeometryHelper.generateGeometry(geometrySet);
	}
	
	/**
	 * Initialise the scene objects
	 */
	private function initObjects()
	{
		fireObjects = new Array<FireVO>();

		plane = new Mesh(new PlaneGeometry(1000, 1000), planeMaterial);
		plane.geometry.scaleUV(2, 2);
		plane.y = -20;
		
		scene.addChild(plane);
		
		//create fire object meshes from geomtry and material, and apply particle animators to each
		for (i in 0...NUM_FIRES) {
			var particleMesh:Mesh = new Mesh(particleGeometry, particleMaterial);
			var animator:ParticleAnimator = new ParticleAnimator(fireAnimationSet);
			particleMesh.animator = animator;
			
			//position the mesh
			var degree:Float = i / NUM_FIRES * Math.PI * 2;
			particleMesh.x = Math.sin(degree) * 400;
			particleMesh.z = Math.cos(degree) * 400;
			particleMesh.y = 5;
			
			//create a fire object and add it to the fire object vector
			fireObjects.push(new FireVO(particleMesh, animator));
			view.scene.addChild(particleMesh);
		}
		
		//setup timer for triggering each particle aniamtor
		timer = new Timer(1000, fireObjects.length);
		timer.addEventListener(TimerEvent.TIMER, onTimer);
		timer.start();
	}
	
	/**
	 * Initialise the listeners
	 */
	private function initListeners()
	{
		view.setRenderCallback(onEnterFrame);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(Event.RESIZE, onResize);
		onResize();
	}
	
	/**
	 * Initialiser function for particle properties
	 */
	private function initParticleFunc(prop:ParticleProperties)
	{
		prop.startTime = Math.random()*5;
		prop.duration = Math.random() * 4 + 0.1;
		
		var degree1:Float = Math.random() * Math.PI * 2;
		var degree2:Float = Math.random() * Math.PI * 2;
		var r:Float = 15;
		prop.nodes.set(ParticleVelocityNode.VELOCITY_VECTOR3D, new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2)));
	}
	
	/**
	 * Returns an array of active lights in the scene
	 */
	private function getAllLights():Array<LightBase>
	{
		var lights:Array<LightBase> = new Array<LightBase>();
		
		lights.push(directionalLight);
		
		var fireVO:FireVO;
		for (fireVO in fireObjects)
			if (fireVO.light != null)
				lights.push(fireVO.light);
		
		return lights;
	}
	
	/**
	 * Timer event handler
	 */
	private function onTimer(e:TimerEvent)
	{
		var fireObject:FireVO = fireObjects[timer.currentCount-1];
		
		//start the animator
		fireObject.animator.start();
		
		//create the lightsource
		var light:PointLight = new PointLight();
		light.color = 0xFF3301;
		light.diffuse = 0;
		light.specular = 0;
		light.position = fireObject.mesh.position;
		
		//add the lightsource to the fire object
		fireObject.light = light;
		
		//update the lightpicker
		lightPicker.lights = getAllLights();
	}
	
	/**
	 * Navigation and render loop
	 */
	private function onEnterFrame(event:Event)
	{
		if (move) {
			cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
			cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
		}
		
		//animate lights
		var fireVO:FireVO;
		for (fireVO in fireObjects) {
			//update flame light
			var light : PointLight = fireVO.light;
			
			if (light==null)
				continue;
			
			if (fireVO.strength < 1)
				fireVO.strength += 0.1;
			
			light.fallOff = 380+Math.random()*20;
			light.radius = 200+Math.random()*30;
			light.diffuse = light.specular = fireVO.strength+Math.random()*.2;
		}
		
		view.render();
	}
	
	/**
	 * Mouse down listener for navigation
	 */
	private function onMouseDown(event:MouseEvent)
	{
		lastPanAngle = cameraController.panAngle;
		lastTiltAngle = cameraController.tiltAngle;
		lastMouseX = stage.mouseX;
		lastMouseY = stage.mouseY;
		move = true;
		stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
	
	/**
	 * Mouse up listener for navigation
	 */
	private function onMouseUp(event:MouseEvent)
	{
		move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
	
	/**
	 * Mouse stage leave listener for navigation
	 */
	private function onStageMouseLeave(event:Event)
	{
		move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
	
	/**
	 * stage listener for resize events
	 */
	private function onResize(event:Event = null)
	{
		view.width = stage.stageWidth;
		view.height = stage.stageHeight;
	}
}

/**
* Data class for the fire objects
*/
class FireVO
{
public var mesh : Mesh;
public var animator : ParticleAnimator;
public var light : PointLight;
public var strength : Float = 0;

public function new(mesh:Mesh, animator:ParticleAnimator)
{
	this.mesh = mesh;
	this.animator = animator;
}
}