#!/bin/sh

xcodebuild archive \
    -project Development/OpenPassDevelopmentApp.xcodeproj \
    -scheme OpenPassDevelopmentApp \
    -destination 'generic/platform=iOS' \
    -derivedDataPath build/derived-data \
    -archivePath build/OpenPassDevelopmentApp.xcarchive

xcodebuild -exportArchive \
    -archivePath "build/OpenPassDevelopmentApp.xcarchive" \
    -exportPath "build" \
    -exportOptionsPlist ExportOptions.plist
