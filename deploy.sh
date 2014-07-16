#!/bin/bash

#########################################################
#
# Simple deployment script for android and ios targets
# 
# Written by :
#		Greg Caldwell - Geepers Interactive Ltd. 2014
#       http://www.geepersinteractive.co.uk
#
#		Blog: http://www.geepers.co.uk
#
# Requirements:
#
#	Only tested on my MAC and requires the Android SDK to 
#   be installed with 'adb' in the current path. For iOS
#   deployment, 'ios-deploy' is utilised and can be found
#   at https://github.com/openfl/ios-deploy.
#
# Description:
#
#   Deploy an built application from within a project folder
#   simply by providing the destination target, either iOS or
#   android and the folder name. This is only appropriate for
#   non final release builds
#
# Usage:
#        deploy.sh devices
#        deploy.sh <ios|android> <application folder>
#
#########################################################

function usage {
	echo "Usage:"
	echo "       deploy.sh devices"
	echo "       deploy.sh <ios release|ios debug|android>"
	echo "       deploy.sh <ios release|ios debug|android> <application folder>"
	echo
	echo "When specifying a target but no application folder, all folders within the"
	echo "current project are deployed if they contain the project's target files."
	exit 1
}
 
if [ "$#" -ne 1 ] && [ "$#" -ne 2 ] && [ "$#" -ne 3 ]
then
	usage
fi

TARGET=$1
TYPE=$([[ "$2" == "debug" ]] && echo "Debug" || echo "Release")
IOSAPP=$3
ANDROIDAPP=$2

if [[ $TARGET == "devices" ]]
then
	echo "IOS devices currently attached"
	echo "----------------------------------"
	system_profiler SPUSBDataType | sed -n -e '/iPad/,/Serial/p' -e '/iPhone/,/Serial/p' | grep "Serial Number:" | awk -F ": " '{print $2}'
	echo
	echo "Android devices currently attached"
	echo "----------------------------------"
	adb devices
else

	if [[ $TARGET != "ios" ]] && [[ $TARGET != "android" ]]
	then
		echo "ERROR: Invalid target or command specified"
		echo "-------------------------------------------------------"
		usage
	fi

	if [[ $TARGET == "ios" ]] && [[ $2 != "debug" ]] && [[ $2 != "release" ]]
	then
		echo "ERROR: Invalid iOS target build type: debug or release"
		echo "-------------------------------------------------------"
		usage
	fi


	echo "DEPLOY LOG" > deploy.log
	echo "----------" >> deploy.log
	echo >> deploy.log

	if [[ $TARGET == "ios" ]]
	then

		if [ "$#" -eq 2 ]
		then
			DEVID=$(system_profiler SPUSBDataType | sed -n -e '/iPad/,/Serial/p' -e '/iPhone/,/Serial/p' | grep "Serial Number:" | awk -F ": " '{print $2}')
			for DIR in $(find . -type d -maxdepth 1 -not -name . -not -name .git); 
			do
				if [ -d "${DIR}/Export/ios/build/${TYPE}-iphoneos/${DIR}.app" ]
				then
					echo "Deploying $DIR (${TYPE}) to iOS device: ${DEVID}";
					echo "Deploying $DIR (${TYPE}) to iOS device: ${DEVID}" >> deploy.log;
					ios-deploy -i $DEVID -b "${DIR}/Export/ios/build/${TYPE}-iphoneos/${DIR}.app" >> deploy.log;
				fi
			done 

		else
			
			if [ -d "${IOSAPP}/Export/ios/build/${TYPE}-iphoneos/${IOSAPP}.app" ]
			then
				DEVID=$(system_profiler SPUSBDataType | sed -n -e '/iPad/,/Serial/p' -e '/iPhone/,/Serial/p' | grep "Serial Number:" | awk -F ": " '{print $2}')
				echo "Deploying ${IOSAPP} (${TYPE}) to iOS device: ${DEVID}"
				echo "---------------------------------------------------------------"
				echo "ios-deploy -i ${DEVID} -b \"${IOSAPP}/Export/ios/build/${TYPE}-iphoneos/${IOSAPP}.app\""
				ios-deploy -i $DEVID -b "${IOSAPP}/Export/ios/build/${TYPE}-iphoneos/${IOSAPP}.app"
			fi

		fi
	
	else

		if [ "$#" -eq 1 ]
		then
			for DIR in $(find . -type d -maxdepth 1 -not -name . -not -name .git); 
			do
				if [ -f "${DIR}/Export/android/bin/bin/${DIR}-debug.apk" ]
				then
					echo "Deploying $DIR to Android device";
					echo "Deploying $DIR to Android device" >> deploy.log;
					adb install -r "${DIR}/Export/android/bin/bin/${DIR}-debug.apk" >> deploy.log;
				fi
			done 
		else
			if [ -f "${ANDROIDAPP}/Export/android/bin/bin/${ANDROIDAPP}-debug.apk" ]
			then
				echo "Deploying ${ANDROIDAPP} to Android device"
				echo "---------------------------------------------------------------"
				adb install -r "${ANDROIDAPP}/Export/android/bin/bin/${ANDROIDAPP}-debug.apk"
			fi
		fi
	fi
fi

