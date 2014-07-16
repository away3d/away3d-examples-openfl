/*

Terrain Lines in Away3D

Demonstrates:

Using the SegementSet and LineSegments this demo modifies the position of segments to match 
a simplex noise generated terrain which continually scrolls to give the effect of moving 
over the terrain. Three wire frame sphere are positioned and rotated to give
the appearance that they are rolling across the scrolling surface. 

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

/**
 * Created by Greg on 20/06/2014.
 */
package;

import away3d.animators.ParticleAnimationSet;
import away3d.animators.ParticleAnimator;
import away3d.animators.data.ParticleProperties;
import away3d.animators.data.ParticlePropertiesMode;
import away3d.animators.nodes.ParticleBillboardNode;
import away3d.animators.nodes.ParticleColorNode;
import away3d.animators.nodes.ParticleVelocityNode;
import away3d.containers.ObjectContainer3D;
import away3d.containers.View3D;
import away3d.core.base.Geometry;
import away3d.entities.Mesh;
import away3d.entities.SegmentSet;
import away3d.filters.MotionBlurFilter3D;
import away3d.materials.TextureMaterial;
import away3d.primitives.LineSegment;
import away3d.primitives.PlaneGeometry;
import away3d.primitives.WireframeSphere;
import away3d.primitives.data.Segment;
import away3d.tools.helpers.ParticleGeometryHelper;
import away3d.utils.Cast;

import openfl.display.Bitmap;

import openfl.display.BitmapData;
import openfl.display.BlendMode;

import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.geom.Vector3D;
import openfl.utils.ByteArray;

class Intermediate_Lines extends Sprite {

    //engine variables
    var _view:View3D;

    // grid
    var _grid:SegmentSet;
    var _gridContainer:ObjectContainer3D;

    // grid size
    var _wid:Int;
    var _hgt:Int;
    var _stepsX:Int;
    var _stepsY:Int;
    var _rot:Int;
    var _heightScale:Float;

    // Landscape
    var _landscape:BitmapData;
    var _landscapeDataV:Array<UInt>;
    var _offset:Point;
    var _offsets:Array<Point>;

    // Spheres
    var _sphere1:WireframeSphere;
    var _sphere2:WireframeSphere;
    var _sphere3:WireframeSphere;

    //particle variables
	var _particleAnimationSet:ParticleAnimationSet;
	var _particleMesh:Mesh;
	var _particleAnimator:ParticleAnimator;

    /**
  	 * Constructor
  	 */
    public function new() {
    	super();

        initEngine();
        initScene();
        initParticles();
        initListeners();
    }

    private function initEngine() {
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;

        //setup the view
        _view = new View3D();
        addChild(_view);

        //setup the camera
        _view.camera.z = -4000;
        _view.camera.lookAt(new Vector3D());
        _view.camera.lens.far = 50000;
    }

    private function initScene() {
        // Define the grid size and the grid steps
        _wid = 6000;
        _hgt = 8000;
        _stepsX = 64;
        _stepsY = 64;
        _rot = Std.int(720/_stepsY);

        _heightScale = 10;

        // Create the segment set container
        _gridContainer = new ObjectContainer3D();
        _view.scene.addChild(_gridContainer);

        // Create the vector of segment sets.
        _grid = new SegmentSet();
		_gridContainer.addChild(_grid);

        // Setup some vars for reuse
        var wBy2:Float = _wid * 0.5;
        var hBy2:Float = _hgt * 0.5;
        var wGap:Float = _wid / (_stepsX - 1);
        var hGap:Float = _hgt / _stepsY;

        var ctr=0;
        for (gY in 0..._stepsY) {
            // Populate the segment sets with line segments across the grid
            var last:Vector3D = new Vector3D(-wBy2, 0, -hBy2 + (gY * hGap) );
            var next:Vector3D = new Vector3D();

            var col:UInt = Std.int(0xA0 - (gY/_stepsY * 0xA0)) << 8;
            for (gX in 0..._stepsX) {
                next = new Vector3D(-wBy2 + (gX * wGap), 0, -hBy2 + (gY * hGap) );
                _grid.addSegment(new LineSegment(last, next, col, col, 0.75));
                ctr++;
                last = next;
            }
        }
        
        //Add rolling spheres
        _sphere1 = new WireframeSphere(200, 16, 12, 0xffffff, 0.5);
        _sphere1.x = -wBy2 * 0.4; // Off to the left a bit
        _sphere1.z = -hBy2 * 0.5;
        _gridContainer.addChild(_sphere1);

        _sphere2 = new WireframeSphere(200, 16, 12, 0xff0000, 0.5);
        _sphere2.x = wBy2 * 0.4; // Off to the right a bit
        _sphere2.z = -hBy2 * 0.5;
        _gridContainer.addChild(_sphere2);

        _sphere3 = new WireframeSphere(100, 16, 12, 0x0000ff, 0.5);
        _sphere3.z = -hBy2 * 0.5; // Off to the left a bit
        _gridContainer.addChild(_sphere3);

        // Setup scrolling offset
        _offset = new Point();

        //stats
        this.addChild(new away3d.debug.AwayFPS(_view, 10, 10, 0xffffff, 3));
    }

    private function initParticles() {
		//setup the particle geometry
		var plane:Geometry = new PlaneGeometry(50, 50, 1, 1, false);
		var geometrySet:Array<Geometry> = new Array<Geometry>();
		for (i in 0...500)
			geometrySet.push(plane);

		//setup the particle animation set
		_particleAnimationSet = new ParticleAnimationSet(true, true);
		_particleAnimationSet.addAnimation(new ParticleBillboardNode());
		_particleAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.LOCAL_STATIC));
        _particleAnimationSet.addAnimation(new ParticleColorNode(ParticlePropertiesMode.GLOBAL, true, false, false, false, new ColorTransform(0, 0, 0), new ColorTransform(1, 1, 1, 1)));
		_particleAnimationSet.initParticleFunc = initParticleFunc;

		//setup the particle material
		var material:TextureMaterial = new TextureMaterial(Cast.bitmapTexture("embeds/blue.png"));
		material.blendMode = BlendMode.ADD;

		//setup the particle animator and mesh
		_particleAnimator = new ParticleAnimator(_particleAnimationSet);
		_particleMesh = new Mesh(ParticleGeometryHelper.generateGeometry(geometrySet), material);
		_particleMesh.animator = _particleAnimator;
        _particleMesh.y = 1000;
        _particleMesh.z = 5000;
		_view.scene.addChild(_particleMesh);

		//start the animation
		_particleAnimator.start();
    }

    /**
     * Initialiser function for particle properties
     */
    private function initParticleFunc(prop:ParticleProperties) {
        prop.startTime = Math.random()*10 - 10;
        prop.duration = 10;
        var degree1:Float = Math.PI * -0.5 + (Math.random() * Math.PI);
        var degree2:Float = Math.PI * -0.2 + Math.random() * Math.PI * -0.2;
        var r:Float = Math.random() * 500 + 500;
        prop.nodes.set(ParticleVelocityNode.VELOCITY_VECTOR3D, new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2)));
    }

    private function initListeners() {
        _view.setRenderCallback(onEnterFrame);
    }
   	
    private function onEnterFrame(e:Event) {

        // Scroll the landscape
        _offset.y += 1;

        // Update the camera's horizontal positioning and rotation
        var camPos:Float = Math.sin(_offset.y * 0.05);
        _view.camera.x = camPos * _wid * 0.25;
        _view.camera.rotationY = camPos * -25;

        // Extract all pixel Y coords and map to line segments
        var gX:Int;
        var gY:Int = 0;
        var lastY:Float;
        var nextY:Float;
        var lS:Segment;
        var scale:Float = 128;

        while (gY < _stepsY) {

            gX = 1;
            lastY = Simplex.noise2D(0, (gY+_offset.y)/scale, 7) * _heightScale;

            while (gX < _stepsX) {

            	// Lookup line segment
            	var pos = gY * _stepsX + gX;
            	lS = _grid.getSegment(pos);

                nextY = Simplex.noise2D(gX/scale, (gY+_offset.y)/scale, 7) * _heightScale;

                // Assign the heights for the beginning and end of the segment
                lS.start.y = lastY;
                lS.end.y = nextY;

                // Update the current segment
                _grid.updateSegment(lS);

                // Store previous height for next line segment
                lastY = nextY;

                // Increment across the line segments
                gX++;
            }

            // Increment across the rows
            gY++;
        }


        // Update sphere positions
        gY = Std.int(_stepsY*0.25) * _stepsX;
        lS = _grid.getSegment(gY + Std.int(_stepsX*0.3));
        _sphere1.y = lS.end.y + 200;
        _sphere1.rotationX += _rot;

        lS = _grid.getSegment(gY + Std.int(_stepsX*0.7));
        _sphere2.y = lS.end.y + 200;
        _sphere2.rotationX += _rot;

        lS = _grid.getSegment(gY + Std.int(_stepsX*0.5));
        _sphere3.y = lS.end.y + 100;
        _sphere3.rotationX += _rot * 1.5;

        // Update camera height
        lS = _grid.getSegment(Std.int( _stepsX * (0.5 + camPos * 0.25)));
        _view.camera.y = lS.end.y + 100;

        // Render the scene
        _view.render();
    }
}

/*
 * Implementation of a fast 2D simplex noise generator.
 */
class Simplex {

	// The gradients are the midpoints of the vertices of a cube.
	static var grad3:Array<Array<Int>> = [
	    [1,1,0], [-1,1,0], [1,-1,0], [-1,-1,0],
	    [1,0,1], [-1,0,1], [1,0,-1], [-1,0,-1],
	    [0,1,1], [0,-1,1], [0,1,-1], [0,-1,-1]
	];

	// Permutation table.  The same list is repeated twice.
	static var  perm:Array<Int> = [
	    151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,
	    8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,
	    35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,
	    134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,
	    55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208, 89,
	    18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,
	    250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,
	    189,28,42,223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,
	    172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,
	    228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,
	    107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,
	    138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,

	    151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,
	    8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,
	    35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,
	    134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,
	    55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208, 89,
	    18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,
	    250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,
	    189,28,42,223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,
	    172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,
	    228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,
	    107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,
	    138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
	];


	public static function noise2D( x:Float, y:Float, octaves:Int = 4, persistence:Float = 0.5, scale:Float = 1 ) : Int {
	    var total:Float = 0;
	    var frequency:Float = scale;
	    var amplitude:Float = 1;

	    // We have to keep track of the largest possible amplitude,
	    // because each octave adds more, and we need a value in [-1, 1].
	    var maxAmplitude:Float = 0;

	    for (i in 0...octaves) {
	        total += raw_noise_2d( x * frequency, y * frequency ) * amplitude;

	        frequency *= 2;
	        maxAmplitude += amplitude;
	        amplitude *= persistence;
	    }

	    return Std.int(((total / maxAmplitude)+1) * 128);
	}

	private static function raw_noise_2d( x:Float, y:Float ) : Float {
	    // Noise contributions from the three corners
	    var n0, n1, n2;

	    // Skew the input space to determine which simplex cell we're in
	    var F2 = 0.5 * (Math.sqrt(3.0) - 1.0);
	    
	    // Hairy factor for 2D
	    var s:Float = (x + y) * F2;
	    var i:Int = fastfloor( x + s );
	    var j:Int = fastfloor( y + s );

	    var G2:Float = (3.0 - Math.sqrt(3.0)) / 6.0;
	    var t:Float = (i + j) * G2;
	    
	    // Unskew the cell origin back to (x,y) space
	    var X0:Float = i-t;
	    var Y0:Float = j-t;
	    
	    // The x,y distances from the cell origin
	    var x0:Float = x-X0;
	    var y0:Float = y-Y0;

	    // For the 2D case, the simplex shape is an equilateral triangle.
	    // Determine which simplex we are in.
	    var i1:Int, j1:Int; // Offsets for second (middle) corner of simplex in (i,j) coords
	    if(x0>y0) {i1=1; j1=0;} // lower triangle, XY order: (0,0)->(1,0)->(1,1)
	    else {i1=0; j1=1;} // upper triangle, YX order: (0,0)->(0,1)->(1,1)

	    // A step of (1,0) in (i,j) means a step of (1-c,-c) in (x,y), and
	    // a step of (0,1) in (i,j) means a step of (-c,1-c) in (x,y), where
	    // c = (3-sqrt(3))/6
	    var x1 = x0 - i1 + G2; // Offsets for middle corner in (x,y) unskewed coords
	    var y1 = y0 - j1 + G2;
	    var x2 = x0 - 1.0 + 2.0 * G2; // Offsets for last corner in (x,y) unskewed coords
	    var y2 = y0 - 1.0 + 2.0 * G2;

	    // Work out the hashed gradient indices of the three simplex corners
	    var ii:Int = i & 255;
	    var jj:Int = j & 255;
	    var gi0:Int = perm[ii+perm[jj]] % 12;
	    var gi1:Int = perm[ii+i1+perm[jj+j1]] % 12;
	    var gi2:Int = perm[ii+1+perm[jj+1]] % 12;

	    // Calculate the contribution from the three corners
	    var t0 = 0.5 - x0*x0-y0*y0;
	    if(t0<0) n0 = 0.0;
	    else {
	        t0 *= t0;
	        n0 = t0 * t0 * dot(grad3[gi0], x0, y0); // (x,y) of grad3 used for 2D gradient
	    }

	    var t1 = 0.5 - x1*x1-y1*y1;
	    if(t1<0) n1 = 0.0;
	    else {
	        t1 *= t1;
	        n1 = t1 * t1 * dot(grad3[gi1], x1, y1);
	    }

	    var t2 = 0.5 - x2*x2-y2*y2;
	    if(t2<0) n2 = 0.0;
	    else {
	        t2 *= t2;
	        n2 = t2 * t2 * dot(grad3[gi2], x2, y2);
	    }

	    // Add contributions from each corner to get the final noise value.
	    // The result is scaled to return values in the interval [-1,1].
	    return 70.0 * (n0 + n1 + n2);
	}

	private static function fastfloor( x:Float ) { return x > 0 ? Std.int(x) : Std.int(x - 1); }

	private static function dot( g:Array<Int>, x:Float, y:Float ):Float { return g[0]*x + g[1]*y; }
}
