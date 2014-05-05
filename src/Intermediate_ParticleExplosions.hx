/*

Particle explosions in Away3D using the Adobe AIR and Adobe Flash Player logos

Demonstrates:

How to split images into particles.
How to share particle geometries and animation sets between meshes and animators.
How to manually update the playhead of a particle animator using the update() function.

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

import flash.display.*;
import flash.events.*;
import flash.geom.*;
import flash.utils.*;
import flash.Vector;
import flash.Lib;

import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.nodes.*;
import away3d.cameras.*;
import away3d.containers.*;
import away3d.controllers.*;
import away3d.core.base.*;
import away3d.debug.*;
import away3d.entities.*;
import away3d.lights.*;
import away3d.materials.*;
import away3d.materials.lightpickers.*;
import away3d.primitives.*;
import away3d.tools.helpers.*;
import away3d.utils.*;

@:bitmap("embeds/away3d.png") class Away3DImage extends BitmapData {}
@:bitmap("embeds/openfl.png") class OpenFLImage extends BitmapData {}
@:bitmap("embeds/player.png") class PlayerImage extends BitmapData {}
@:bitmap("embeds/crossplatform.png") class PlatformsImage extends BitmapData {}
@:bitmap("embeds/haxe.png") class HaxeImage extends BitmapData {}

class Intermediate_ParticleExplosions extends Sprite
{
	var PARTICLE_SIZE:Int = 3;
	var NUM_ANIMATORS:Int = 2;
			
	//engine variables
	var scene:Scene3D;
	var camera:Camera3D;
	var view:View3D;
	var cameraController:HoverController;
	
	
	//light variables
	var greenLight:PointLight;
	var blueLight:PointLight;
	var lightPicker:StaticLightPicker;
	
	//data variables
	var colorValues:Vector<Vector3D>;
	var colorPoints:Vector<Vector3D>;
	var colorPlayerSeparation:Int;
	var colorAway3DSeparation:Int;
	var colorOpenFLSeparation:Int;
	var colorPlatformsSeparation:Int;
	
	//material objects
	var colorMaterial:ColorMaterial;
	
	//particle objects
	var colorGeometry:ParticleGeometry;
	var colorAnimationSet:ParticleAnimationSet;
	
	//scene objects
	var colorParticleMesh:Mesh;
	var colorAnimators:Vector<ParticleAnimator>;
	
	//navigation variables
	var angle:Float = 0;
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
		view.scene = scene;
		view.camera = camera;
		
		//setup controller to be used on the camera
		cameraController = new HoverController(camera, null, 225, 10, 1000);
		
		addChild(view);
		
		addChild(new AwayFPS(view, 10, 10, 0xffffff));
	}
	
	/**
	 * Initialise the lights
	 */
	private function initLights()
	{
		//create a green point light
		greenLight = new PointLight();
		greenLight.color = 0x00FF00;
		greenLight.ambient = 1;
		greenLight.fallOff = 600;
		greenLight.radius = 100;
		greenLight.specular = 2;
		scene.addChild(greenLight);
		
		//create a red pointlight
		blueLight = new PointLight();
		blueLight.color = 0x0000FF;
		blueLight.fallOff = 600;
		blueLight.radius = 100;
		blueLight.specular = 2;
		scene.addChild(blueLight);
		
		//create a lightpicker for the green and red light
		lightPicker = new StaticLightPicker([greenLight, blueLight]);
	}
	
	/**
	 * Initialise the materials
	 */
	private function initMaterials()
	{
		//setup the particle material
		colorMaterial = new ColorMaterial(0xFFFFFF);
		colorMaterial.alphaPremultiplied = true;
		colorMaterial.bothSides = true;
		colorMaterial.lightPicker = lightPicker;
	}
	
	/**
	 * Initialise the particles
	 */
	private function initParticles()
	{
		var bitmapData:BitmapData;
		
		colorValues = new Vector<Vector3D>();
		colorPoints = new Vector<Vector3D>();

		// Add Away3D image
		addImage(Cast.bitmapData(Away3DImage), 0, 0, -100);

		//define where one logo stops and another starts
		colorAway3DSeparation = colorPoints.length;
		
		// Add OpenFL image
		addImage(Cast.bitmapData(OpenFLImage), -95, 0, -31);

		//define where one logo stops and another starts
		colorOpenFLSeparation = colorPoints.length;
		
		// Add Flash Player image
		addImage(Cast.bitmapData(PlayerImage), -59, 0, 81);

		//define where one logo stops and another starts
		colorPlayerSeparation = colorPoints.length;
		
		// Add Cross Platform image
		addImage(Cast.bitmapData(PlatformsImage), 59, 0, 81);

		//define where one logo stops and another starts
		colorPlatformsSeparation = colorPoints.length;
		
		// Add Haxe image
		addImage(Cast.bitmapData(HaxeImage), 95, 0, -31);
		
		var num:UInt = colorPoints.length;
		
		//setup the base geometry for one particle
		var plane:PlaneGeometry = new PlaneGeometry(PARTICLE_SIZE, PARTICLE_SIZE,1,1,false);
		
		//combine them into a list
		var colorGeometrySet:Vector<Geometry> = new Vector<Geometry>();
		for (i in 0...num)
			colorGeometrySet.push(plane);
		
		//generate the particle geometries
		colorGeometry = ParticleGeometryHelper.generateGeometry(colorGeometrySet);
		
		//define the white particle animations and init function
		colorAnimationSet = new ParticleAnimationSet();
		colorAnimationSet.addAnimation(new ParticleBillboardNode());
		colorAnimationSet.addAnimation(new ParticleBezierCurveNode(ParticlePropertiesMode.LOCAL_STATIC));
		colorAnimationSet.addAnimation(new ParticlePositionNode(ParticlePropertiesMode.LOCAL_STATIC));
		colorAnimationSet.addAnimation(new ParticleInitialColorNode(ParticlePropertiesMode.LOCAL_STATIC, true, false, new ColorTransform(0, 1, 0, 1)));
		colorAnimationSet.initParticleFunc = iniColorParticleFunc;
	}
	
	/*
	 * Add image particles to animation
	 */
	private function addImage(bitmapData:BitmapData, pX:Float, pY:Float, pZ:Float) {
		var point:Vector3D;
		var color:UInt;

		// Create particle for each pixel position
		for (i in 0...bitmapData.width) {
			for (j in 0...bitmapData.height) {
				point = new Vector3D(PARTICLE_SIZE*(i - bitmapData.width / 2 + pX), PARTICLE_SIZE*( -j + bitmapData.height / 2) + pY, PARTICLE_SIZE * pZ);
				color = bitmapData.getPixel32(i, j);
				if (((color >> 24) & 0xff) > 0xb0) {
					colorValues.push(new Vector3D(((color & 0xff0000) >> 16)/255, ((color & 0xff00) >> 8)/255, (color & 0xff)/255));
					colorPoints.push(point);
				}
			}
		}
	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects()
	{
		//initialise animators vectors
		colorAnimators = new Vector<ParticleAnimator>(NUM_ANIMATORS, true);
		
		//create the particle mesh
		colorParticleMesh = new Mesh(colorGeometry, colorMaterial);
		
		var i:Int = 0;
		for (i in 0...NUM_ANIMATORS) {
			//clone the white particle mesh
			colorParticleMesh = cast(colorParticleMesh.clone(), Mesh);
			colorParticleMesh.rotationY = 45*(i-1);
			scene.addChild(colorParticleMesh);
			
			//create and start the white particle animator
			colorAnimators[i] = new ParticleAnimator(colorAnimationSet);
			colorParticleMesh.animator = colorAnimators[i];
			scene.addChild(colorParticleMesh);
		}
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
	private function iniColorParticleFunc(properties:ParticleProperties)
	{
		properties.startTime = 0;
		properties.duration = 1;
		var degree1:Float = Math.random() * Math.PI * 2;
		var degree2:Float = Math.random() * Math.PI * 2;
		var r:Float = 250;
		
		if (properties.index < colorAway3DSeparation)
			properties.nodes.set(ParticleBezierCurveNode.BEZIER_END_VECTOR3D, new Vector3D(0, 0, -300*PARTICLE_SIZE));
		else if (properties.index < colorOpenFLSeparation)
			properties.nodes.set(ParticleBezierCurveNode.BEZIER_END_VECTOR3D, new Vector3D(-285*PARTICLE_SIZE, 0, -93*PARTICLE_SIZE));
		else if (properties.index < colorPlayerSeparation)
			properties.nodes.set(ParticleBezierCurveNode.BEZIER_END_VECTOR3D, new Vector3D(-176*PARTICLE_SIZE, 0, 243*PARTICLE_SIZE));
		else if (properties.index < colorPlatformsSeparation)
			properties.nodes.set(ParticleBezierCurveNode.BEZIER_END_VECTOR3D, new Vector3D(176*PARTICLE_SIZE, 0, 243*PARTICLE_SIZE));
		else
			properties.nodes.set(ParticleBezierCurveNode.BEZIER_END_VECTOR3D, new Vector3D(285*PARTICLE_SIZE, 0, -93*PARTICLE_SIZE));

		var rgb:Vector3D = colorValues[properties.index];
		properties.nodes.set(ParticleInitialColorNode.COLOR_INITIAL_COLORTRANSFORM, new ColorTransform(rgb.x, rgb.y, rgb.z, 1));

		properties.nodes.set(ParticleBezierCurveNode.BEZIER_CONTROL_VECTOR3D, new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2)));
		properties.nodes.set(ParticlePositionNode.POSITION_VECTOR3D, colorPoints[properties.index]);
	}
	
	/**
	 * Navigation and render loop
	 */
	private function onEnterFrame(event:Event)
	{
		//update the camera position
		cameraController.panAngle += 0.2;
		
		//update the particle animator playhead positions
		var time:Int;
		for (i in 0...NUM_ANIMATORS) {
			time = Std.int(1000*(Math.sin(Lib.getTimer()/5000 + Math.PI*i/4) + 1));
			colorAnimators[i].update(time);
		}
		
		if (move) {
			cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
			cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
		}
		
		//update the light positions
		angle += Math.PI / 180;
		greenLight.x = Math.sin(angle) * 600;
		greenLight.z = Math.cos(angle) * 600;
		blueLight.x = Math.sin(angle+Math.PI) * 600;
		blueLight.z = Math.cos(angle+Math.PI) * 600;
		
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
