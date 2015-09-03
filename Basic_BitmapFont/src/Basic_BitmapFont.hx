package;

import away3d.containers.ObjectContainer3D;
import away3d.containers.View3D;
import away3d.debug.AwayFPS;
import away3d.entities.Mesh;
import away3d.textfield.BitmapFont;
import away3d.textfield.HAlign;
import away3d.textfield.TextField;
import away3d.textfield.utils.AwayFont;
import definitions.berberRevKC.BerberRevKC_260;
import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Vector3D;

#if html5
import js.Browser;
#end

class Basic_BitmapFont extends Sprite
{	
	//engine variables
	private var _view:View3D;
	
	//scene objects
	private var _plane:Mesh;
	private static var ctr:Float = 0;
	private var container:ObjectContainer3D;
	private var active:Bool = true;
	private var activeDisplay:Sprite;
	private var countMax:Int = 600;
	private var count:Int;
	private var browserType:String;
	
	/**
	 * Constructor
	 */
	public function new ()
	{
		super();
		
		count = Std.int(countMax * 0.9);
		
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
		
		var len = 14;
		for (i in 0...len) 
		{
			var textContainer = new ObjectContainer3D();
			textContainer.rotationY = i / len * 360;
			container.addChild(textContainer);
			
			var colour:UInt = Std.int(0xFFFFFF * Math.random());
			var bitmapFont:BitmapFont = AwayFont.type(BerberRevKC_260, false);
			
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
		
		browserType = getBrowserType(); 
		
		stage.addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
		stage.addEventListener(Event.MOUSE_LEAVE, OnMouseLeave);
		
		if (browserType != "MOBILE") {
			activeDisplay = new Sprite();
			activeDisplay.graphics.beginFill(0x000000, 0.8);
			activeDisplay.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			addChild(activeDisplay);	
		}
		
		// stats
		addChild(new AwayFPS(_view, 10, 10, 0xFFFFFF, 1));
	}
	
	private function OnMouseLeave(e:Event):Void 
	{
		active = false;
	}
	
	private function OnMouseMove(e:MouseEvent):Void 
	{
		active = true;
		count = 0;
	}
	
	private function Update(e:Event):Void 
	{
		if (browserType != "MOBILE") {
			if (active == false || count > 600) {
				activeDisplay.visible = true;
				return;
			}
			else {
				activeDisplay.visible = false;
			}
			count++;
		}
		
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
	
	public function getBrowserType(): String {
		var browserType: String = "Undefined";
		
		#if html5
			var browserAgent : String = Browser.navigator.userAgent;
			
			if (browserAgent != null) {
				
				if	(	browserAgent.indexOf("Android") >= 0
					||	browserAgent.indexOf("BlackBerry") >= 0
					||	browserAgent.indexOf("iPhone") >= 0
					||	browserAgent.indexOf("iPad") >= 0
					||	browserAgent.indexOf("iPod") >= 0
					||	browserAgent.indexOf("Opera Mini") >= 0
					||	browserAgent.indexOf("IEMobile") >= 0
					) {
					browserType = "MOBILE";
				}
				else {
					browserType = "DESKTOP";
				}
			}
		#end
		
		return browserType;
	}
}
