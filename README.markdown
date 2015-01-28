#Examples using Away3D for OpenFL

##Introduction
Away3D for OpenFl is a port of the Flash Away3D engine, enabling OpenFL C++ native 
builds for OSX, Windows, iOS, Android and maybe others.

##Installation

    haxelib install away3d-examples
    
Or if you would like to install a specific example use the following.

    lime create away3d      // To list all of the available examples
    lime create away3d:Basic_View      // To install the Basic_View example
    lime create away3d:Basic_View /destinationFolder  // To install the example to a specific location
    
A typical project.xml file would look as follows. Each example has it's own project.xml.

    <?xml version="1.0" encoding="utf-8"?>
    <project>
        
        <meta title="Basic View Away3D OpenFL" package="away3d.examples.BasicView" version="1.0.0" />
        <app main="Basic_View" file="Basic_View" path="Export" />
        
        <window width="1024" height="700" if="desktop"/>
        <window width="0" height="0" if="html5" />
        <window orientation="landscape" vsync="true" if="cpp"/>
        <window fps="60" hardware="true" allow-shaders="true" require-shaders="true" depth-buffer="true" stencil-buffer="true"  background="#000000"  />
            
        <source path="src" />
        
        <haxelib name="format" if="html5" />
        <haxelib name="away3d" />
        <haxelib name="openfl" />
        
        <assets path="embeds" exclude="away3d.svg" />

        <icon path="embeds/away3d.svg" />
        
        <haxedef name="source-map-content" if="html5" />
        <haxedef name="dom" if="html5" />

        <android minimum-sdk-version="10" />

    </project>
	
	
##Dependencies
Requires OpenFL 2.2.4 and the Away3D library

    haxelib install away3d
        
##License

Copyright 2014 The Away3D Team

The Away3D OpenFL port is free, open-source software under the MIT license.
