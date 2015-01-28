/*

Vertex animation example in Away3d using the MD2 format

Demonstrates:

How to use the AssetLibrary class to load an embedded internal md2 model.
How to clone an asset from the AssetLibrary and apply different mateirals.
How to load animations into an animation set and apply to individual meshes.

Code by Rob Bateman
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

Perelith Knight, by James Green (no email given)

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

import away3d.animators.*;
import away3d.containers.*;
import away3d.controllers.*;
import away3d.entities.*;
import away3d.events.*;
import away3d.library.*;
import away3d.library.assets.*;
import away3d.lights.*;
import away3d.loaders.parsers.*;
import away3d.materials.*;
import away3d.materials.lightpickers.*;
import away3d.materials.methods.*;
import away3d.primitives.*;
import away3d.utils.Cast;

import openfl.display.*;
import openfl.events.*;
import openfl.filters.*;
import openfl.geom.*;
import openfl.text.*;
import openfl.ui.*;
import openfl.utils.ByteArray;

import openfl.Assets;

import utils.*;

class Intermediate_PerelithKnightMD2 extends Sprite
{	
	
	//Perelith Knight model
	public static var PKnightModel:ByteArray;
	
	private var _pKnightMaterials:Array<TextureMaterial> = new Array<TextureMaterial>();
	
	//engine variables
	private var _view:View3D;
	private var _cameraController:HoverController;
		
	//info
	private var _info:TextField;
	
	//light objects
	private var _light:DirectionalLight;
	private var _lightPicker:StaticLightPicker;
	
	//material objects
	private var _floorMaterial:TextureMaterial;
	private var _shadowMapMethod:FilteredShadowMapMethod;
	
	//scene objects
	private var _floor:Mesh;
	private var _mesh:Mesh;
	
	//navigation variables
	private var _move:Bool;
	private var _lastPanAngle:Float;
	private var _lastTiltAngle:Float;
	private var _lastMouseX:Float;
	private var _lastMouseY:Float;
	private var _keyUp:Bool;
	private var _keyDown:Bool;
	private var _keyLeft:Bool;
	private var _keyRight:Bool;
	private var _lookAtPosition:Vector3D;
	private var _animationSet:VertexAnimationSet;
	
	/**
	 * Constructor
	 */
	public function new()
	{
		super();

		_move = false;
		_lookAtPosition = new Vector3D();

		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		//setup the view
		_view = new View3D();
		addChild(_view);
		
		//setup the camera for optimal rendering
		_view.camera.lens.far = 5000;
		
		//setup controller to be used on the camera
		_cameraController = new HoverController(_view.camera, null, 45, 20, 2000, 5);
		
		//setup the help text
		_info = new TextField();
		_info.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
		_info.embedFonts = true;
		_info.antiAliasType = AntiAliasType.ADVANCED;
		_info.gridFitType = GridFitType.PIXEL;
		_info.width = 240;
		_info.height = 100;
		_info.selectable = false;
		_info.mouseEnabled = false;
		_info.text = "Click and drag - rotate\n" + 
			"Cursor keys / WSAD / ZSQD - move\n" + 
			"Scroll wheel - zoom";
		
		_info.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
		
		addChild(_info);
		
		//setup the lights for the scene
		_light = new DirectionalLight(-0.5, -1, -1);
		_light.ambient = 0.4;
		_lightPicker = new StaticLightPicker([_light]);
		_view.scene.addChild(_light);
		
		//setup parser to be used on AssetLibrary
		PKnightModel = Assets.getBytes('embeds/pknight/pknight.md2');
		Asset3DLibrary.loadData(PKnightModel, null, null, new MD2Parser());
		Asset3DLibrary.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		Asset3DLibrary.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		
		//create a global shadow map method
		#if !ios
		_shadowMapMethod = new FilteredShadowMapMethod(_light);
		#end
		
		//setup floor material
		_floorMaterial = new TextureMaterial(Cast.bitmapTexture("embeds/floor_diffuse.jpg"));
		_floorMaterial.lightPicker = _lightPicker;
		_floorMaterial.specular = 0;
		_floorMaterial.ambient = 1;
		#if !ios
		_floorMaterial.shadowMethod = _shadowMapMethod;
		#end
		_floorMaterial.repeat = true;
		
		//setup Perelith Knight materials
		for (i in 0...4) {
			var knightMaterial:TextureMaterial = new TextureMaterial(Cast.bitmapTexture("embeds/pknight/pknight"+(i+1)+".png"));
			//knightMaterial.normalMap = Cast.bitmapTexture(BitmapFilterEffects.normalMap(bitmapData));
			//knightMaterial.specularMap = Cast.bitmapTexture(BitmapFilterEffects.outline(bitmapData));
			knightMaterial.lightPicker = _lightPicker;
			knightMaterial.gloss = 30;
			knightMaterial.specular = 1;
			knightMaterial.ambient = 1;
			#if !ios
			knightMaterial.shadowMethod = _shadowMapMethod;
			#end
			_pKnightMaterials.push(knightMaterial);
		}
		
		//setup the floor
		_floor = new Mesh(new PlaneGeometry(5000, 5000), _floorMaterial);
		_floor.geometry.scaleUV(5, 5);
		
		//setup the scene
		_view.scene.addChild(_floor);
				
		//add listeners
		_view.setRenderCallback(onEnterFrame);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(Event.MOUSE_LEAVE, onMouseUp);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		stage.addEventListener(Event.RESIZE, onResize);
		onResize();

        //stats
        this.addChild(new away3d.debug.AwayFPS(_view, 10, 10, 0xffffff, 3));
	}
	
	/**
	 * Navigation and render loop
	 */
	private function onEnterFrame(event:Event)
	{
		if (_move) {
			_cameraController.panAngle = 0.3*(stage.mouseX - _lastMouseX) + _lastPanAngle;
			_cameraController.tiltAngle = 0.3*(stage.mouseY - _lastMouseY) + _lastTiltAngle;
		}
		
		if (_keyUp)
			_lookAtPosition.x -= 10;
		if (_keyDown)
			_lookAtPosition.x += 10;
		if (_keyLeft)
			_lookAtPosition.z -= 10;
		if (_keyRight)
			_lookAtPosition.z += 10;
		
		_cameraController.lookAtPosition = _lookAtPosition;
		
		_view.render();
	}
	
	/**
	 * Listener function for asset complete event on loader
	 */
	private function onAssetComplete(event:Asset3DEvent)
	{
		if (event.asset.assetType == Asset3DType.MESH) {
			_mesh = cast(event.asset, Mesh);
			
			//adjust the ogre mesh
			_mesh.y = 120;
			_mesh.scale(5);
			
		} else if (event.asset.assetType == Asset3DType.ANIMATION_SET) {
			_animationSet = cast(event.asset, VertexAnimationSet);
		}
	}
	
	/**
	 * Listener function for resource complete event on loader
	 */
	private function onResourceComplete(event:LoaderEvent)
	{
		//create 20 x 20 different clones of the ogre
		var numWide:UInt = 20;
		var numDeep:UInt = 20;
		var k:UInt = 0;
		for (i in  0...numWide) {
			for (j in 0...numDeep) {
				//clone mesh
				var clone:Mesh = cast(_mesh.clone(), Mesh);
				clone.x = (i-(numWide-1)/2)*5000/numWide;
				clone.z = (j-(numDeep-1)/2)*5000/numDeep;
				clone.castsShadows = true;
				clone.material = _pKnightMaterials[Std.int(Math.random()*_pKnightMaterials.length)];
				_view.scene.addChild(clone);
				
				//create animator
				var vertexAnimator:VertexAnimator = new VertexAnimator(_animationSet);
				
				//play specified state
				vertexAnimator.play(_animationSet.animationNames[Std.int(Math.random()*_animationSet.animationNames.length)], null, Std.int(Math.random()*1000));
				clone.animator = vertexAnimator;
				k++;
			}
		}
	}

	/**
	 * Key down listener for animation
	 */
	private function onKeyDown(event:KeyboardEvent)
	{
		switch (event.keyCode) {
			case Keyboard.UP, Keyboard.W, Keyboard.Z: //fr
				_keyUp = true;
			case Keyboard.DOWN, Keyboard.S: 
				_keyDown = true;
			case Keyboard.LEFT, Keyboard.A, Keyboard.Q: //fr
				_keyLeft = true;
			case Keyboard.RIGHT, Keyboard.D: 
				_keyRight = true;
		}
	}
	
	/**
	 * Key up listener
	 */
	private function onKeyUp(event:KeyboardEvent)
	{
		switch (event.keyCode) {
			case Keyboard.UP, Keyboard.W, Keyboard.Z: //fr
				_keyUp = false;
			case Keyboard.DOWN, Keyboard.S: 
				_keyDown = false;
			case Keyboard.LEFT, Keyboard.A, Keyboard.Q: //fr
				_keyLeft = false;
			case Keyboard.RIGHT, Keyboard.D: 
				_keyRight = false;
		}
	}
	
	/**
	 * Mouse down listener for navigation
	 */
	private function onMouseDown(event:MouseEvent)
	{
		_lastPanAngle = _cameraController.panAngle;
		_lastTiltAngle = _cameraController.tiltAngle;
		_lastMouseX = stage.mouseX;
		_lastMouseY = stage.mouseY;
		_move = true;
	}
	
	/**
	 * Mouse up listener for navigation
	 */
	private function onMouseUp(event:Event)
	{
		_move = false;
	}
	
	/**
	 * Mouse wheel listener for navigation
	 */
	private function onMouseWheel(ev:MouseEvent)
	{
		_cameraController.distance -= ev.delta * 5;
		
		if (_cameraController.distance < 100)
			_cameraController.distance = 100;
		else if (_cameraController.distance > 2000)
			_cameraController.distance = 2000;
	}
	
	/**
	 * Stage listener for resize events
	 */
	private function onResize(event:Event = null)
	{
		_view.width = stage.stageWidth;
		_view.height = stage.stageHeight;
		_info.x = stage.stageWidth - 240;
	}
}

