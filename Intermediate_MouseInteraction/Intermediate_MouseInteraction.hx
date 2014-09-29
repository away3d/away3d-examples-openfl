package;

import away3d.bounds.*;
import away3d.cameras.*;
import away3d.containers.*;
import away3d.controllers.*;
import away3d.core.base.*;
import away3d.core.pick.*;
import away3d.debug.*;
import away3d.entities.*;
import away3d.events.*;
import away3d.library.assets.*;
import away3d.lights.*;
import away3d.loaders.parsers.*;
import away3d.materials.*;
import away3d.materials.lightpickers.*;
import away3d.primitives.*;
import away3d.textures.*;
import away3d.library.Asset3DLibrary;

import openfl.display.*;
import openfl.events.*;
import openfl.filters.*;
import openfl.geom.*;
import openfl.text.*;
import openfl.ui.*;
import openfl.utils.ByteArray;

import openfl.Lib;
import openfl.Assets;

class Intermediate_MouseInteraction extends Sprite
{
	private var HeadAsset:ByteArray;
	
	//engine variables
	var scene:Scene3D;
	var camera:Camera3D;
	var view:View3D;
	var awayStats:AwayStats;
	var cameraController:HoverController;
	
	//light objects
	var pointLight:PointLight;
	var lightPicker:StaticLightPicker;
	
	//material objects
	var painter:Sprite;
	var blackMaterial:ColorMaterial;
	var whiteMaterial:ColorMaterial;
	var grayMaterial:ColorMaterial;
	var blueMaterial:ColorMaterial;
	var redMaterial:ColorMaterial;

	//scene objects
	var text:TextField;
	var pickingPositionTracer:Mesh;
	var scenePositionTracer:Mesh;
	var pickingNormalTracer:SegmentSet;
	var sceneNormalTracer:SegmentSet;
	var previoiusCollidingObject:PickingCollisionVO;
	var raycastPicker:RaycastPicker;
	var head:Mesh;
	var cubeGeometry:CubeGeometry;
	var sphereGeometry:SphereGeometry;
	var cylinderGeometry:CylinderGeometry;
	var torusGeometry:TorusGeometry;

	//navigation variables
	var move:Bool = false;
	var lastPanAngle:Float;
	var lastTiltAngle:Float;
	var lastMouseX:Float;
	var lastMouseY:Float;
	var tiltSpeed:Float = 4;
	var panSpeed:Float = 4;
	var distanceSpeed:Float = 4;
	var tiltIncrement:Float = 0;
	var panIncrement:Float = 0;
	var distanceIncrement:Float = 0;

	var PAINT_TEXTURE_SIZE:UInt = 1024;

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
		initText();
		initLights();
		initMaterials();
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
		
		raycastPicker = new RaycastPicker(false);

		view = new View3D();
		view.forceMouseMove = true;
		scene = view.scene;
		camera = view.camera;

		// Chose global picking method ( chose one ).
		// view.mousePicker = PickingType.SHADER; // Uses the GPU, considers gpu animations, and suffers from Stage3D's drawToBitmapData()'s bottleneck.
		// view.mousePicker = PickingType.RAYCAST_FIRST_ENCOUNTERED; // Uses the CPU, fast, but might be inaccurate with intersecting objects.
		view.mousePicker = PickingType.RAYCAST_BEST_HIT; // Uses the CPU, guarantees accuracy with a little performance cost.

		//setup controller to be used on the camera
		cameraController = new HoverController(camera, null, 180, 20, 320, 5);
		
		addChild(view);
		
		awayStats = new AwayStats(view);
		addChild(awayStats);
	}
	
	/**
	 * Create an instructions overlay
	 */
	private function initText()
	{
		text = new TextField();
		text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
		text.width = 1000;
		text.height = 200;
		text.x = 25;
		text.y = 50;
		text.selectable = false;
		text.mouseEnabled = false;
		text.text = "Camera controls -----\n";
		text.text = "  Click and drag on the stage to rotate camera.\n";
		text.appendText("  Keyboard arrows and WASD also rotate camera and Z and X zoom camera.\n");
		text.appendText("Picking ----- \n");
		text.appendText("  Click on the head model to draw on its texture. \n");
		text.appendText("  Red objects have triangle picking precision. \n" );
		text.appendText("  Blue objects have bounds picking precision. \n" );
		text.appendText("  Gray objects are disabled for picking but occlude picking on other objects. \n" );
		text.appendText("  Black objects are completely ignored for picking. \n" );
		text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
		addChild(text);
	}
	
	/**
	 * Initialise the lights
	 */
	private function initLights()
	{
		//create a light for the camera
		pointLight = new PointLight();
		scene.addChild(pointLight);
		lightPicker = new StaticLightPicker([pointLight]);
	}
	
	/**
	 * Initialise the material
	 */
	private function initMaterials()
	{
		// uv painter
		painter = new Sprite();
		painter.graphics.beginFill( 0xFF0000 );
		painter.graphics.drawCircle( 0, 0, 10 );
		painter.graphics.endFill();

		// locator materials
		whiteMaterial = new ColorMaterial( 0xFFFFFF );
		whiteMaterial.lightPicker = lightPicker;
		blackMaterial = new ColorMaterial( 0x333333 );
		blackMaterial.lightPicker = lightPicker;
		grayMaterial = new ColorMaterial( 0xCCCCCC );
		grayMaterial.lightPicker = lightPicker;
		blueMaterial = new ColorMaterial( 0x0000FF );
		blueMaterial.lightPicker = lightPicker;
		redMaterial = new ColorMaterial( 0xFF0000 );
		redMaterial.lightPicker = lightPicker;
	}
	
	/**
	 * Initialise the scene objects
	 */
	private function initObjects()
	{
		// To trace mouse hit position.
		pickingPositionTracer = new Mesh( new SphereGeometry( 2 ), new ColorMaterial( 0x00FF00, 0.5 ) );
		pickingPositionTracer.visible = false;
		pickingPositionTracer.mouseEnabled = false;
		pickingPositionTracer.mouseChildren = false;
		scene.addChild(pickingPositionTracer);
		
		scenePositionTracer = new Mesh( new SphereGeometry( 2 ), new ColorMaterial( 0x0000FF, 0.5 ) );
		scenePositionTracer.visible = false;
		scenePositionTracer.mouseEnabled = false;
		scene.addChild(scenePositionTracer);
		
		
		// To trace picking normals.
		pickingNormalTracer = new SegmentSet();
		pickingNormalTracer.mouseEnabled = pickingNormalTracer.mouseChildren = false;
		var lineSegment1:LineSegment = new LineSegment( new Vector3D(), new Vector3D(), 0xFFFFFF, 0xFFFFFF, 3 );
		pickingNormalTracer.addSegment( lineSegment1 );
		pickingNormalTracer.visible = false;
		view.scene.addChild( pickingNormalTracer );
		
		sceneNormalTracer = new SegmentSet();
		sceneNormalTracer.mouseEnabled = sceneNormalTracer.mouseChildren = false;
		var lineSegment2:LineSegment = new LineSegment( new Vector3D(), new Vector3D(), 0xFFFFFF, 0xFFFFFF, 3 );
		sceneNormalTracer.addSegment( lineSegment2 );
		sceneNormalTracer.visible = false;
		view.scene.addChild( sceneNormalTracer );
		
		
		// Load a head model that we will be able to paint on on mouse down.
		HeadAsset = Assets.getBytes("embeds/head.obj");
		Asset3DLibrary.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		Asset3DLibrary.loadData(HeadAsset, null, null, new OBJParser(25));
		
		// Produce a bunch of objects to be around the scene.
		createABunchOfObjects();
		
		raycastPicker.setIgnoreList([sceneNormalTracer, scenePositionTracer]);
		raycastPicker.onlyMouseEnabled = false;
	}

	private function onAssetComplete( event:Asset3DEvent ) {
		if( event.asset.assetType == Asset3DType.MESH ) {
			initializeHeadModel( cast( event.asset, Mesh) );
		}
	}

	private function initializeHeadModel( model:Mesh ) {

		head = model;

		// Apply a bitmap material that can be painted on.
		var bmd:BitmapData = new BitmapData( PAINT_TEXTURE_SIZE, PAINT_TEXTURE_SIZE, false, 0x888888 );
		#if html5
		// No perlin noise on html5 target
		for (i in 0...100) {
			var grey = Std.int(Math.random()*0xff);
			bmd.fillRect( new Rectangle( Math.random()*PAINT_TEXTURE_SIZE, Math.random()*PAINT_TEXTURE_SIZE, Math.random()*PAINT_TEXTURE_SIZE, Math.random()*PAINT_TEXTURE_SIZE), grey<<16 | grey<<8 | grey );
		}
		#else
		bmd.perlinNoise( 50, 50, 8, 1, false, true, 7, true );
		#end
		var bitmapTexture:BitmapTexture = new BitmapTexture( bmd );
		var textureMaterial:TextureMaterial = new TextureMaterial( bitmapTexture );
		textureMaterial.lightPicker = lightPicker;
		model.material = textureMaterial;

		// Set up a ray picking collider.
		// Due to the number of triangles Flash used PixelBender to calculate the hit however on all other targets
		// PixelBender is not available so has been removed.
		model.pickingCollider = PickingColliderType.BEST_HIT;
		
		// Apply mouse interactivity.
		model.mouseEnabled = model.mouseChildren = model.shaderPickingDetails = true;
		enableMeshMouseListeners( model );

		view.scene.addChild( model );
	}

	private function createABunchOfObjects() {

		cubeGeometry = new CubeGeometry( 25, 25, 25 );
		sphereGeometry = new SphereGeometry( 12 );
		cylinderGeometry = new CylinderGeometry( 12, 12, 25 );
		torusGeometry = new TorusGeometry( 12, 12 );

		for ( i in 0...40 ) {

			// Create object.
			var object:Mesh = createSimpleObject();

			// Random orientation.
			object.rotationX = 360 * Math.random();
			object.rotationY = 360 * Math.random();
			object.rotationZ = 360 * Math.random();

			// Random position.
			var r:Float = 200 + 100 * Math.random();
			var azimuth:Float = 2 * Math.PI * Math.random();
			var elevation:Float = 0.25 * Math.PI * Math.random();
			object.x = r * Math.cos(elevation) * Math.sin(azimuth);
			object.y = r * Math.sin(elevation);
			object.z = r * Math.cos(elevation) * Math.cos(azimuth);
		}
	}

	private function createSimpleObject():Mesh {

		var geometry:Geometry;
		var bounds:BoundingVolumeBase = null;
		
		// Chose a random geometry.
		var randGeometry:Float = Math.random();
		if( randGeometry > 0.75 ) {
			geometry = cubeGeometry;
		}
		else if( randGeometry > 0.5 ) {
			geometry = sphereGeometry;
			bounds = new BoundingSphere(); // better on spherical meshes with bound picking colliders
		}
		else if( randGeometry > 0.25 ) {
			geometry = cylinderGeometry;
			
		}
		else {
			geometry = torusGeometry;
		}
		
		var mesh:Mesh = new Mesh(geometry);
		
		if (bounds != null)
			mesh.bounds = bounds;

		// For shader based picking.
		mesh.shaderPickingDetails = true;

		// Randomly decide if the mesh has a triangle collider.
		var usesTriangleCollider:Bool = Math.random() > 0.5;
		if( usesTriangleCollider ) {
			mesh.pickingCollider = PickingColliderType.FIRST_ENCOUNTERED;
		}

		// Enable mouse interactivity?
		var isMouseEnabled:Bool = Math.random() > 0.25;
		mesh.mouseEnabled = mesh.mouseChildren = isMouseEnabled;

		// Enable mouse listeners?
		var listensToMouseEvents:Bool = Math.random() > 0.25;
		if( isMouseEnabled && listensToMouseEvents ) {
			enableMeshMouseListeners( mesh );
		}

		// Apply material according to the random setup of the object.
		choseMeshMaterial( mesh );

		// Add to scene and store.
		view.scene.addChild( mesh );

		return mesh;
	}

	private function choseMeshMaterial( mesh:Mesh ) {
		if( !mesh.mouseEnabled ) {
			mesh.material = blackMaterial;
		}
		else {
			if( !mesh.hasEventListener( MouseEvent3D.MOUSE_MOVE ) ) {
				mesh.material = grayMaterial;
			}
			else {
				if( mesh.pickingCollider != PickingColliderType.BOUNDS_ONLY ) {
					mesh.material = redMaterial;
				}
				else {
					mesh.material = blueMaterial;
				}
			}
		}
	}

	/**
	 * Initialise the listeners
	 */
	private function initListeners()
	{
		view.setRenderCallback(onEnterFrame);
		view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(Event.RESIZE, onResize);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		onResize();
	}
	
	/**
	 * Navigation and render loop
	 */
	private function onEnterFrame(event:Event)
	{
		// Update camera.
		if (move) {
			cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
			cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
		}
		cameraController.panAngle += panIncrement;
		cameraController.tiltAngle += tiltIncrement;
		cameraController.distance += distanceIncrement;

		// Move light with camera.
		pointLight.position = camera.position;
		
		var collidingObject:PickingCollisionVO = raycastPicker.getSceneCollision(camera.position, view.camera.forwardVector, view.scene);
		//var mesh:Mesh;
		
		if (previoiusCollidingObject != null && previoiusCollidingObject != collidingObject) { //equivalent to mouse out
			scenePositionTracer.visible = sceneNormalTracer.visible = false;
			scenePositionTracer.position = new Vector3D();
		}
		
		if (collidingObject != null) {
			// Show tracers.
			scenePositionTracer.visible = sceneNormalTracer.visible = true;
			
			// Update position tracer.
			scenePositionTracer.position = collidingObject.entity.sceneTransform.transformVector(collidingObject.localPosition);
			
			// Update normal tracer.
			sceneNormalTracer.position = scenePositionTracer.position;
			var normal:Vector3D = collidingObject.entity.sceneTransform.deltaTransformVector(collidingObject.localNormal);
			normal.normalize();
			normal.scaleBy( 25 );
			var lineSegment:LineSegment = cast sceneNormalTracer.getSegment( 0 );
			lineSegment.end = normal.clone();
		}
		
		
		previoiusCollidingObject = collidingObject;
		
		// Render 3D.
		view.render();
	}
	
	/**
	 * Key down listener for camera control
	 */
	private function onKeyDown(event:KeyboardEvent)
	{
		switch (event.keyCode) {
			case Keyboard.UP, Keyboard.W:
				tiltIncrement = tiltSpeed;
			case Keyboard.DOWN, Keyboard.S:
				tiltIncrement = -tiltSpeed;
			case Keyboard.LEFT, Keyboard.A:
				panIncrement = panSpeed;
			case Keyboard.RIGHT, Keyboard.D:
				panIncrement = -panSpeed;
			case Keyboard.Z:
				distanceIncrement = distanceSpeed;
			case Keyboard.X:
				distanceIncrement = -distanceSpeed;
		}
	}
	
	/**
	 * Key up listener for camera control
	 */
	private function onKeyUp(event:KeyboardEvent)
	{
		switch (event.keyCode) {
			case Keyboard.UP, Keyboard.W, Keyboard.DOWN, Keyboard.S:
				tiltIncrement = 0;
			case Keyboard.LEFT, Keyboard.A, Keyboard.RIGHT, Keyboard.D:
				panIncrement = 0;
			case Keyboard.Z, Keyboard.X:
				distanceIncrement = 0;
		}
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
		awayStats.x = stage.stageWidth - awayStats.width;
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
	 * Mouse down listener for navigation
	 */
	private function onMouseDown(event:MouseEvent)
	{
		move = true;
		lastPanAngle = cameraController.panAngle;
		lastTiltAngle = cameraController.tiltAngle;
		lastMouseX = stage.mouseX;
		lastMouseY = stage.mouseY;
		stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}

	// ---------------------------------------------------------------------
	// 3D mouse event handlers.
	// ---------------------------------------------------------------------

	private function enableMeshMouseListeners( mesh:Mesh ) {
		mesh.addEventListener( MouseEvent3D.MOUSE_OVER, onMeshMouseOver );
		mesh.addEventListener( MouseEvent3D.MOUSE_OUT, onMeshMouseOut );
		mesh.addEventListener( MouseEvent3D.MOUSE_MOVE, onMeshMouseMove );
		mesh.addEventListener( MouseEvent3D.MOUSE_DOWN, onMeshMouseDown );
	}

	/**
	 * mesh listener for mouse down interaction
	 */
	private function onMeshMouseDown( event:MouseEvent3D ) {
		var mesh:Mesh = cast event.object;
		// Paint on the head's material.
		if( mesh == head ) {
			var uv:Point = event.uv;
			var textureMaterial:TextureMaterial = cast ( cast( event.object,Mesh ) ).material;
			var bmd:BitmapData = cast( textureMaterial.texture, BitmapTexture ).bitmapData;
			var x = Std.int( PAINT_TEXTURE_SIZE * uv.x );
			var y = Std.int( PAINT_TEXTURE_SIZE * uv.y );
			var matrix:Matrix = new Matrix();
			matrix.translate( x, y );
			bmd.draw( painter, matrix );
			cast( textureMaterial.texture, BitmapTexture ).invalidateContent();
		}
	}

	/**
	 * mesh listener for mouse over interaction
	 */
	private function onMeshMouseOver(event:MouseEvent3D)
	{
		var mesh:Mesh = cast event.object;
		mesh.showBounds = true;
		if( mesh != head ) mesh.material = whiteMaterial;
		pickingPositionTracer.visible = pickingNormalTracer.visible = true;
		onMeshMouseMove(event);
	}

	/**
	 * mesh listener for mouse out interaction
	 */
	private function  onMeshMouseOut(event:MouseEvent3D)
	{
		var mesh:Mesh = cast event.object;
		mesh.showBounds = false;
		if( mesh != head ) choseMeshMaterial( mesh );
		pickingPositionTracer.visible = pickingNormalTracer.visible = false;
		pickingPositionTracer.position = new Vector3D();
	}

	/**
	 * mesh listener for mouse move interaction
	 */
	private function  onMeshMouseMove(event:MouseEvent3D)
	{
		// Show tracers.
		pickingPositionTracer.visible = pickingNormalTracer.visible = true;

		// Update position tracer.
		pickingPositionTracer.position = event.scenePosition;

		// Update normal tracer.
		pickingNormalTracer.position = pickingPositionTracer.position;
		var normal:Vector3D = event.sceneNormal.clone();
		normal.scaleBy( 25 );
		var lineSegment:LineSegment = cast pickingNormalTracer.getSegment( 0 );
		lineSegment.end = normal.clone();
	}
}
