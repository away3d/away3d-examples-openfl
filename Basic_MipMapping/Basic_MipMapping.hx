/*

3D Mip-mapping example in Away3d

Demonstrates:

How to enable/disable mip-mapping and the effect on textures

Code by Greg Caldwell
greg@geepers.co.uk
http://www.geepers.co.uk
http://www.geepersinteractive.co.uk

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

import away3d.containers.View3D;
import away3d.entities.Mesh;
import away3d.materials.TextureMaterial;
import away3d.primitives.PlaneGeometry;
import away3d.textures.BitmapTexture;
import away3d.textures.Anisotropy;
import away3d.utils.Cast;

import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Vector3D;
import openfl.text.TextField;
import openfl.text.TextFormat;

import openfl.Assets;
import openfl.Lib;

class Basic_MipMapping extends Sprite {

	// Engine variables
	var _view : View3D;
	
	// Materials
	var _planeTex : BitmapTexture;
	var _planeMat : TextureMaterial;

	// Scene objects
	var _planeGeom : PlaneGeometry;
	var _plane : Mesh;

	// UI
	var _text : TextField;

	var _state : MipmapState;
	var _lastTimer : UInt;

	/**
	 * Constructor
	 */
	public function new () {
		
		super();

		_state = MipmapState.NO_MIPMAPPING;

		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;

		_lastTimer = Lib.getTimer();

		initScene();
		initUI();
	}

	private function initScene() {
		// Setup the view
		_view = new View3D();
		this.addChild(_view);
		
		// Setup the camera
		_view.camera.z = 0;
		_view.camera.y = 25;
		_view.camera.lookAt(new Vector3D(0, -500, 2000));

		// Setup the texture
		_planeTex = new BitmapTexture(Assets.getBitmapData("embeds/floor_diffuse.jpg"), true);
		
		// Setup the material 
		_planeMat = new TextureMaterial(_planeTex);
		_planeMat.repeat = true;
		_planeMat.mipmap = false;
		_planeMat.anisotropy = Anisotropy.NONE;

		// Setup the geometry
		_planeGeom = new PlaneGeometry(20000, 20000);
		_planeGeom.scaleUV(150, 150);

		// Create the mesh
		_plane = new Mesh( _planeGeom, _planeMat );
		_view.scene.addChild(_plane);
		
		//setup the render loop
		_view.setRenderCallback(_onEnterFrame);
		
		stage.addEventListener(Event.RESIZE, onResize);
		onResize();

		// stats
		this.addChild(new away3d.debug.AwayFPS(_view, 10, 10, 0xffffff, 3));

		stage.addEventListener( MouseEvent.CLICK, onClick );
	}

	private function initUI() {
		var clickText = new TextField();
		clickText.x = 300;
		clickText.y = 50;
		clickText.defaultTextFormat = new TextFormat("_sans", 32, 0xffffff);
		clickText.width = Lib.current.stage.stageWidth - 200;
		clickText.text = "Click anywhere to change";
		addChild(clickText);

		_text = new TextField();
		_text.x = 300;
		_text.y = 100;
		_text.defaultTextFormat = new TextFormat("_sans", 24, 0x2222ff);
		_text.width = Lib.current.stage.stageWidth - 200;
		addChild(_text);

		_text.text = "No Mip-mapping";
	}

	/*
	 * Detect key presses to cycle mip-mapping
	 */
	private function onClick( e:MouseEvent ) {
		switch ( _state ) {
			case NO_MIPMAPPING :
				_state = MIPMAPPING;
				_planeMat.mipmap = true;
				_planeMat.anisotropy = Anisotropy.NONE;
				_text.text = "Mip-mapping with no anisotropic filtering";

			case MIPMAPPING :
				_state = MIPMAPPING_WITH_ANISOTROPIC_2;
				_planeMat.mipmap = true;
				_planeMat.anisotropy = Anisotropy.ANISOTROPIC2X;
				_text.text = "Mip-mapping with 2X anisotropic filtering";

			case MIPMAPPING_WITH_ANISOTROPIC_2 :
				_state = MIPMAPPING_WITH_ANISOTROPIC_4;
				_planeMat.mipmap = true;
				_planeMat.anisotropy = Anisotropy.ANISOTROPIC4X;
				_text.text = "Mip-mapping with 4X anisotropic filtering";

			case MIPMAPPING_WITH_ANISOTROPIC_4 :
				_state = MIPMAPPING_WITH_ANISOTROPIC_8;
				_planeMat.mipmap = true;
				_planeMat.anisotropy = Anisotropy.ANISOTROPIC8X;
				_text.text = "Mip-mapping with 8X anisotropic filtering";

			case MIPMAPPING_WITH_ANISOTROPIC_8 :
				_state = MIPMAPPING_WITH_ANISOTROPIC_16;
				_planeMat.mipmap = true;
				_planeMat.anisotropy = Anisotropy.ANISOTROPIC16X;
				_text.text = "Mip-mapping with 16X anisotropic filtering";

			case MIPMAPPING_WITH_ANISOTROPIC_16 :
				_state = NO_MIPMAPPING;
				_planeMat.mipmap = false;
				_planeMat.anisotropy = Anisotropy.NONE;
				_text.text = "No Mip-mapping";
		}
	}
	
	/**
	 * Render loop
	 */
	private function _onEnterFrame( e:Event ) {
		var delta = Lib.getTimer() - _lastTimer;
		_plane.rotationY += delta / 50;
		
		_lastTimer = Lib.getTimer();
		
		_view.render();
	}
	
	/**
	 * Stage listener for resize events
	 */
	private function onResize( event:Event = null ) {
		_view.width = stage.stageWidth;
		_view.height = stage.stageHeight;
	}
}

enum MipmapState {
	NO_MIPMAPPING;
	MIPMAPPING;
	MIPMAPPING_WITH_ANISOTROPIC_2;
	MIPMAPPING_WITH_ANISOTROPIC_4;
	MIPMAPPING_WITH_ANISOTROPIC_8;
	MIPMAPPING_WITH_ANISOTROPIC_16;
}
