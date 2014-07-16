/*

3ds file loading example in Away3d

Demonstrates:

How to use the Loader3D object to load an embedded internal 3ds model.
How to map an external asset reference inside a file to an internal embedded asset.
How to extract material data and use it to set custom material properties on a model.

Code by Rob Bateman
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

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

import away3d.containers.*;
import away3d.controllers.*;
import away3d.entities.*;
import away3d.events.*;
import away3d.library.assets.*;
import away3d.lights.*;
import away3d.loaders.*;
import away3d.loaders.misc.*;
import away3d.loaders.parsers.*;
import away3d.materials.*;
import away3d.materials.lightpickers.*;
import away3d.materials.methods.*;
import away3d.primitives.*;
import away3d.utils.*;

import openfl.display.*;
import openfl.events.*;
import openfl.geom.*;
import openfl.utils.*;

import openfl.Lib;

import openfl.Assets;

class Basic_Load3DS extends Sprite
{
	//engine variables
	private var _view:View3D;
	private var _cameraController:HoverController;
	
	//light objects
	private var _light:DirectionalLight;
	private var _lightPicker:StaticLightPicker;
	private var _direction:Vector3D;
	
	//material objects
	private var _groundMaterial:TextureMaterial;
	
	//scene objects
	private var _loader:Loader3D;
	private var _ground:Mesh;
	
	//navigation variables
	private var _move:Bool = false;
	private var _lastPanAngle:Float;
	private var _lastTiltAngle:Float;
	private var _lastMouseX:Float;
	private var _lastMouseY:Float;

	/**
	 * Constructor
	 */
	public function new()
	{
		super();

		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;

		//setup the view
		_view = new View3D();
		this.addChild(_view);
		
		//setup the camera for optimal shadow rendering
		_view.camera.lens.far = 2100;
		
		//setup controller to be used on the camera
		_cameraController = new HoverController(_view.camera, null, 45, 20, 1000, 10);
		
		//setup the lights for the scene
		_light = new DirectionalLight(-1, -1, 1);
		_direction = new Vector3D(-1, -1, 1);
		_lightPicker = new StaticLightPicker([_light]);
		_view.scene.addChild(_light);
		
		//setup materials
		_groundMaterial = new TextureMaterial(Cast.bitmapTexture("embeds/CoarseRedSand.jpg"));
		#if !ios
		_groundMaterial.shadowMethod = new SoftShadowMapMethod( _light, 10, 5 );
		_groundMaterial.shadowMethod.epsilon = 0.2;
		#end
		_groundMaterial.lightPicker = _lightPicker;
		_groundMaterial.specular = 0;
		_ground = new Mesh(new PlaneGeometry(1000, 1000), _groundMaterial);
		_ground.castsShadows =false;
		_view.scene.addChild(_ground);
		
		//setup parser to be used on Loader3D
		Parsers.enableAllBundled();
		
		//setup the url map for textures in the 3ds file
		var assetLoaderContext:AssetLoaderContext = new AssetLoaderContext();
		assetLoaderContext.mapUrlToData("texture.jpg", Assets.getBitmapData("embeds/soldier_ant.jpg"));
		
		//setup the scene
		_loader = new Loader3D();
		_loader.scale(300);
		_loader.z = -200;
		_loader.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		_loader.loadData( Assets.getBytes("embeds/soldier_ant.3ds"), assetLoaderContext);
		_view.scene.addChild(_loader);
		
		//add listeners
		_view.setRenderCallback(onEnterFrame);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(Event.RESIZE, onResize);
		onResize();

		// stats
		this.addChild(new away3d.debug.AwayFPS(_view, 10, 10, 0xffffff, 3));
	}
	
	/**
	 * Navigation and render loop
	 */
	private function onEnterFrame(event:Event):Void
	{
		if (_move) {
			_cameraController.panAngle = 0.3*(stage.mouseX - _lastMouseX) + _lastPanAngle;
			_cameraController.tiltAngle = 0.3*(stage.mouseY - _lastMouseY) + _lastTiltAngle;
		}
		
		_direction.x = -Math.sin(Lib.getTimer()/4000);
		_direction.z = -Math.cos(Lib.getTimer()/4000);	
		_light.direction = _direction;
		
		_view.render();
	}
	
	/**
	 * Listener function for asset complete event on loader
	 */
	private function onAssetComplete(e:Event):Void
	{
        var event:Asset3DEvent = cast(e, Asset3DEvent);
		if (event.asset.assetType == away3d.library.assets.Asset3DType.MESH) {
			var mesh:Mesh = cast(event.asset, Mesh);
			//mesh.castsShadows = true;
		} else if (event.asset.assetType == away3d.library.assets.Asset3DType.MATERIAL) {
			var material:TextureMaterial = cast(event.asset, TextureMaterial);
			#if !ios
			material.shadowMethod = new SoftShadowMapMethod( _light, 10, 5 );
			material.shadowMethod.epsilon = 0.2;
			#end
			material.lightPicker = _lightPicker;
			material.gloss = 30;
			material.specular = 1;
			material.ambientColor = 0x303040;
			material.ambient = 1;
		}
	}
	
	/**
	 * Mouse down listener for navigation
	 */
	private function onMouseDown(event:MouseEvent):Void
	{
		_lastPanAngle = _cameraController.panAngle;
		_lastTiltAngle = _cameraController.tiltAngle;
		_lastMouseX = stage.mouseX;
		_lastMouseY = stage.mouseY;
		_move = true;
		stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}

	/**
	 * Mouse up listener for navigation
	 */
	private function onMouseUp(event:MouseEvent):Void
	{
		_move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
	
	/**
	 * Mouse stage leave listener for navigation
	 */
	private function onStageMouseLeave(event:Event):Void
	{
		_move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
	
	/**
	 * stage listener for resize events
	 */
	private function onResize(event:Event = null):Void
	{
		_view.width = stage.stageWidth;
		_view.height = stage.stageHeight;
	}
}

