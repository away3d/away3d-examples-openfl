package;

import away3d.containers.ObjectContainer3D;
import away3d.containers.View3D;
import away3d.debug.*;
import away3d.entities.Mesh;
import away3d.materials.TextureMaterial;
import away3d.primitives.PlaneGeometry;
import away3d.textfield.BitmapFont;
import away3d.textfield.HAlign;
import away3d.textfield.TextField;
import away3d.textfield.utils.AwayFont;
import away3d.utils.Cast;
import definitions.berberRevKC.BerberRevKC_260;

import openfl.display.StageScaleMode;
import openfl.display.StageAlign;
import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.events.Event;
import openfl.geom.Vector3D;
import openfl.Lib;
import haxe.Timer;

class Basic_BitmapFont extends Sprite
{	
	//engine variables
	private var _view:View3D;
	
	//scene objects
	private var _plane:Mesh;
	private static var ctr:Float = 0;
	private var container:ObjectContainer3D;
	
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
		_view.antiAlias = 0;
		
		//setup the camera
		_view.camera.z = -600;
		_view.camera.y = 200;
		_view.camera.lookAt(new Vector3D());

		//setup the scene
		container = new ObjectContainer3D();
		_view.scene.addChild(container);
		
		
		var colour:UInt = Std.int(0xFFFFFF * Math.random());
		var bitmapFont:BitmapFont = AwayFont.type(BerberRevKC_260, true);
		
		var len = 14;
		for (i in 0...len) 
		{
			var textContainer = new ObjectContainer3D();
			textContainer.rotationY = i / len * 360;
			container.addChild(textContainer);
			
			var textField:TextField = new TextField(800, 600, "THIS IS A TEST", bitmapFont, 100, colour, false, HAlign.CENTER);
			textField.x = -400;
			textField.y = -300 + (i * 60);
			textField.rotationX = 90;
			
			textContainer.addChild(textField);
		}
		
		//setup the render loop
		addEventListener(Event.ENTER_FRAME, Update);
		
		stage.addEventListener(Event.RESIZE, onResize);
		onResize();

		this.stage.frameRate = 60;
		
		// stats
		this.addChild(new away3d.debug.AwayFPS(_view, 10, 10, 0xffffff, 3));
	}
	
	private function Update(e:Event):Void 
	{
		container.rotationY += 1;
		
		_view.render();
	}
	
	/**
	 * render loop
	 */
	
	/**
	 * stage listener for resize events
	 */
	private function onResize(event:Event = null):Void
	{
		_view.width = stage.stageWidth;
		_view.height = stage.stageHeight;
	}
}
