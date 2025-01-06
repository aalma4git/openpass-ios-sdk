#!/bin/sh

usage ()
{
    echo "Usage: $0 <test-plan>"
    exit 1
}

if [ "$#" -ne 1 ]
then
    usage
fi

TESTPLAN=$1 #e.g. OpenPassDevelopmentAppUITests-Mobile

xcodebuild build-for-testing \
    -project Development/OpenPassDevelopmentApp.xcodeproj \
    -scheme OpenPassDevelopmentApp \
    -testPlan "$TESTPLAN" \
    -derivedDataPath build/derived-data
cd build/derived-data/Build/Products/Debug-iphoneos
cp ../*"$TESTPLAN"*.xctestrun ./
zip --symlinks -r "$TESTPLAN".zip OpenPassDevelopmentAppUITests-Runner.app ./*.xctestrun
rm ./*.xctestrun
cd -
