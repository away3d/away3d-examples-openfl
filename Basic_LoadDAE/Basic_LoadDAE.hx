/*

 DAE file loading example in Away3d

 Demonstrates:

 How to use the Loader3D object to load an embedded internal DAE model.

 Code by Greg Caldwell
 greg.caldwell@geepersinteractive.co.uk
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

import openfl.display.Sprite;
import openfl.net.URLRequest;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Vector3D;

import away3d.containers.View3D;
import away3d.lights.DirectionalLight;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.materials.methods.SoftShadowMapMethod;
import away3d.containers.ObjectContainer3D;
import away3d.controllers.HoverController;
import away3d.primitives.PlaneGeometry;
import away3d.primitives.CubeGeometry;
import away3d.library.Asset3DLibrary;
import away3d.loaders.parsers.DAEParser;
import away3d.loaders.misc.AssetLoaderContext;
import away3d.events.Asset3DEvent;
import away3d.entities.Mesh;
import away3d.library.assets.IAsset;
import away3d.library.assets.Asset3DType;
import away3d.materials.SinglePassMaterialBase;
import away3d.utils.Cast;
import away3d.textures.BitmapCubeTexture;
import away3d.materials.TextureMaterial;
import openfl.display.BitmapData;

import openfl.Assets;
import openfl.Lib;

class Basic_LoadDAE extends Sprite
{
    //engine variables
    var _view:View3D;
    var _cameraController:HoverController;

    //light objects
    var _light:DirectionalLight;
    var _lightPicker:StaticLightPicker;
    var _direction:Vector3D;
    var _shadow:SoftShadowMapMethod;

    //scene objects and materials
    var _carpetMat:TextureMaterial;
    var _roomMat:TextureMaterial;
    var _carpet:Mesh;
    var _room:Mesh;
    var _rockingHorse:Mesh;

    //animation vars
    var _counter:Float;
    var _rockingPoint:Vector3D;

    //navigation variables
    var _move:Bool;
    var _lastPanAngle:Float;
    var _lastTiltAngle:Float;
    var _lastMouseX:Float;
    var _lastMouseY:Float;

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
    private function init():Void
    {
        initEngine();
        initLights();
        initMaterials();
        initObjects();
        initListeners();
   }

    /**
     * Initialise the engine
     */
    private function initEngine():Void
    {
        _counter = 0;

        _view = new View3D();
        _view.camera.z = 1000;
        this.addChild(_view);

        //set the background of the view to something suitable
        _view.backgroundColor = 0x1e2125;
 
        var target = new ObjectContainer3D();
        target.y = 250;
        
        //setup controller to be used on the camera
        _cameraController = new HoverController( _view.camera, target );
        _cameraController.distance = 1000;
        _cameraController.minTiltAngle = 0;
        _cameraController.maxTiltAngle = 45;
        _cameraController.panAngle = 15;
        _cameraController.tiltAngle = 10;

        //stats
        this.addChild(new away3d.debug.AwayFPS(_view, 10, 10, 0xffffff, 3));
    }

    /**
     * Initialise the lights
     */
    private function initLights():Void
    {
        //create the light for the scene
        _light = new DirectionalLight();
        _light.color = 0x808080;
        _light.direction = new Vector3D(0.4, -0.3, -0.4);
        _light.ambient = 0.75;
        _light.ambientColor = 0x60657b;
        _light.diffuse = 2.2;
        _light.specular = 0.8;
        _view.scene.addChild(this._light);

        //create the lightppicker for the material
        _lightPicker = new StaticLightPicker( [ this._light ] );
    }

    /**
     * Initialise the materials
     */
    private function initMaterials():Void
    {
        #if !ios
        _shadow = new SoftShadowMapMethod(_light, 15, 10);
        _shadow.epsilon = 0.2;
        #end

        _carpetMat = new TextureMaterial(Cast.bitmapTexture("embeds/carpet.jpg"));
        #if !ios
        _carpetMat.shadowMethod = _shadow;
        #end
        _carpetMat.specular = 0;
        _carpetMat.lightPicker = _lightPicker;
        _carpetMat.repeat = true;

        _roomMat = new TextureMaterial(Cast.bitmapTexture("embeds/wallpaper.jpg"));
        _roomMat.specular = 0;
        _roomMat.lightPicker = _lightPicker;
        _roomMat.repeat = true;
    }

    /**
     * Initialise the scene objects
     */
    private function initObjects():Void
    {
        _carpet = new Mesh(new PlaneGeometry(2500, 2500), _carpetMat);
        _carpet.castsShadows = false;
        _view.scene.addChild(_carpet);

        var wall = new Mesh(new PlaneGeometry(2500, 2500), _roomMat);
        wall.castsShadows = false;
        wall.rotationX = -90;
        wall.y = 1250;
        
        var wall1 = wall.clone();
        wall1.x = -1250;
        wall1.rotationY = -90;
        _view.scene.addChild(wall1);

        var wall2 = wall.clone();
        wall2.x = 1250;
        wall2.rotationY = 90;
        _view.scene.addChild(wall2);

        var wall3 = wall.clone();
        wall3.z = 1250;
        _view.scene.addChild(wall3);

        var wall4 = wall.clone();
        wall4.z = -1250;
        wall4.rotationY = 180;
        _view.scene.addChild(wall4);
    }

    /**
     * Initialise the listeners
     */
    private function initListeners():Void
    {
        // setup render loop
        _view.setRenderCallback(onEnterFrame);

        // add mouse and resize events
        stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        onResize();

        //setup the url map for textures in the 3ds file
        var assetLoaderContext:AssetLoaderContext = new AssetLoaderContext();
        assetLoaderContext.mapUrlToData("../images/Material1noCulling.jpg", Assets.getBitmapData("embeds/Material1noCulling.jpg"));
        assetLoaderContext.mapUrlToData("../images/Color_009noCulling.jpg", Assets.getBitmapData("embeds/Color_009noCulling.jpg"));
        
        Asset3DLibrary.enableParser(DAEParser);
        Asset3DLibrary.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
        Asset3DLibrary.loadData(Assets.getBytes('embeds/hobbelpaard.dae'), assetLoaderContext);
    }

    /**
     * Listener function for asset complete event on loader
     */
    private function onAssetComplete (event:Asset3DEvent)
    {
        var asset:IAsset = event.asset;

        switch (asset.assetType)
        {
            case Asset3DType.MESH :
                _rockingHorse = cast(asset, Mesh);
                _rockingPoint = _rockingHorse.pivotPoint.clone();
                _view.scene.addChild(_rockingHorse);

            case Asset3DType.MATERIAL:
                var material:SinglePassMaterialBase = cast(asset, SinglePassMaterialBase);
                material.ambientColor = 0xffffff;
                material.lightPicker = _lightPicker;
        }
    }


    /**
     * Navigation and render loop
     */
    private function onEnterFrame(e:Event):Void
    {
        if (_move) {
            _cameraController.panAngle = 0.3*(stage.mouseX - _lastMouseX) + _lastPanAngle;
            _cameraController.tiltAngle = 0.3*(stage.mouseY - _lastMouseY) + _lastTiltAngle;
        }

        _counter = Lib.getTimer() / 500;

        if (_rockingHorse!=null) {
            _rockingHorse.rotationZ = Math.sin(_counter) * 15;

            var position = Math.sin(_counter) * -25;
            _rockingHorse.pivotPoint = _rockingPoint.add( new Vector3D(position, 0, 0) );
            _rockingHorse.x = position;
            _rockingHorse.y = Math.abs(position * 0.5) + 10;
        }

        _view.render();
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

