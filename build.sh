#!/bin/bash

#########################################################
#
# Simple batch building script
# 
# Written by :
#		Greg Caldwell - Geepers Interactive Ltd. 2014
#       http://www.geepersinteractive.co.uk
#
#		Blog: http://www.geepers.co.uk
#
# Requirements:
#
#	Only tested on my MAC.
#
# Description:
#
#   Loops through the current directory which is assumed
#   to contain project folders, each with there own
#   project.xml file. Either a debug or release (non-debug
#   but not publishable build) of the each project for a 
#   specified target
#
# Usage: build.sh <target> <build-type>
#
#   target     = mac|windows|linux|html5|flash|ios|android|blackberry|tizen|emscripten|webos
# 	build-type = debug|release    : Optional and defaults to 'release'
#
#########################################################

if [ "$#" -ne 1 ] && [ "$#" -ne 2 ]
then
	echo "Usage: build.sh <target> <build-type>"
	echo
	echo "	target     = mac|windows|linux|html5|flash|ios|android|blackberry|tizen|emscripten|webos"
	echo "	build-type = debug|release    : Optional and defaults to 'release'"
	exit 1
fi

TARGET=$1
BUILD=${2:-release}

if [[ $BUILD == "debug" ]]
then
	BUILDTYPE="-debug"
else
	BUILDTYPE=""
fi


for DIR in $(find . -type d -maxdepth 1 -not -name . -not -name .git); 
do
	echo "Building $DIR for $TARGET"; 

	cd "./$DIR"
	if [ -f "./project.xml" ]
	then
		lime build $TARGET $BUILDTYPE > "$DIR.log"
	fi
	cd ..
done

echo 
echo "All builds completed."

