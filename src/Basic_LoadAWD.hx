/*

 AWD file loading example in Away3d

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

import flash.display.Sprite;
import flash.net.URLRequest;
import flash.events.Event;
import flash.geom.Vector3D;

import away3d.containers.View3D;
import away3d.lights.DirectionalLight;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.entities.Mesh;
import away3d.primitives.SphereGeometry;
import away3d.library.Asset3DLibrary;
import away3d.loaders.parsers.AWDParser;
import away3d.events.Asset3DEvent;
import away3d.library.assets.IAsset;
import away3d.library.assets.Asset3DType;
import away3d.materials.TextureMaterial;
import away3d.debug.AwayFPS;

import openfl.Assets;

class Basic_LoadAWD extends Sprite
{
    //engine variables
    var _view:View3D;

    //light objects
    var _light:DirectionalLight;
    var _lightPicker:StaticLightPicker;
    var _direction:Vector3D;

    //scene objects
    var _suzanne:Mesh;

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
        _view = new View3D();
        this.addChild(_view);

        //set the background of the view to something suitable
        _view.backgroundColor = 0x1e2125;

        //position the camera
        _view.camera.z = -2000;
 
        this.addChild(new AwayFPS(_view, 0, 0, 0xffffff, 3));
    }

    /**
     * Initialise the lights
     */
    private function initLights():Void
    {
        //create the light for the scene
        _light = new DirectionalLight();
        _light.color = 0x683019;
        _light.direction = new Vector3D(1, 0, 0);
        _light.ambient = 0.5;
        _light.ambientColor = 0x30353b;
        _light.diffuse = 2.8;
        _light.specular = 1.8;
        _view.scene.addChild(this._light);

        //create the lightppicker for the material
        _lightPicker = new StaticLightPicker([this._light]);
    }

    /**
     * Initialise the materials
     */
    private function initMaterials():Void
    {
    }

    /**
     * Initialise the scene objects
     */
    private function initObjects():Void
    {
        _view.scene.addChild(new Mesh(new SphereGeometry(0)));
    }

    /**
     * Initialise the listeners
     */
    private function initListeners():Void
    {
        stage.addEventListener(Event.RESIZE, onResize);

        onResize();

        _view.setRenderCallback(onEnterFrame);

        Asset3DLibrary.enableParser(AWDParser);

        Asset3DLibrary.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);

        Asset3DLibrary.loadData(Assets.getBytes('embeds/suzanne.awd'));
    }

    /**
     * Navigation and render loop
     */
    private function onEnterFrame(e:Event):Void
    {
        if (_suzanne!=null)
            _suzanne.rotationY += 1;

        _view.render();
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
                var mesh:Mesh = cast(asset, Mesh);
                mesh.y = -300;
                mesh.scale(900);

                _suzanne = mesh;
                _view.scene.addChild(mesh);

            case Asset3DType.MATERIAL:
                //*
                var material:TextureMaterial = cast(asset, TextureMaterial);
                material.lightPicker = _lightPicker;
        }
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

