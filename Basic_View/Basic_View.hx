/*

3D Tweening example in Away3d

Demonstrates:

How to use Tweener within a 3D coordinate system.
How to create a 3D mouse event listener on a scene object.
How to return the scene coordinates of a mouse click on the surface of a scene object.

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

import away3d.containers.View3D;
import away3d.debug.*;
import away3d.entities.Mesh;
import away3d.materials.TextureMaterial;
import away3d.primitives.PlaneGeometry;
import away3d.utils.Cast;

import openfl.display.StageScaleMode;
import openfl.display.StageAlign;
import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.events.Event;
import openfl.geom.Vector3D;
import openfl.Lib;
import haxe.Timer;

class Basic_View extends Sprite
{	
	//engine variables
	private var _view:View3D;
	
	//scene objects
	private var _plane:Mesh;

	/**
	 * Constructor
	 */
	public function new ()
	{
		super();

		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;

		//setup the view
		_view = new View3D();
		this.addChild(_view);
		
		//setup the camera
		_view.camera.z = -600;
		_view.camera.y = 200;
		_view.camera.lookAt(new Vector3D());

		//setup the scene
		_plane = new Mesh(new PlaneGeometry(700, 700), new TextureMaterial(Cast.bitmapTexture("embeds/floor_diffuse.jpg")));
		_view.scene.addChild(_plane);
		
		//setup the render loop
		_view.setRenderCallback(_onEnterFrame);
		
		stage.addEventListener(Event.RESIZE, onResize);
		onResize();

		// stats
		this.addChild(new away3d.debug.AwayFPS(_view, 10, 10, 0xffffff, 3));
	}
	
	/**
	 * render loop
	 */
	private static var ctr:Float = 0;
	private function _onEnterFrame(e:Event):Void
	{
		_plane.rotationY += 1;
		
		_view.render();
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
