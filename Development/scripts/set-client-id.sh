#!/bin/sh

usage ()
{
    echo "Usage: $0 <client-id>"
    exit 1
}

if [ "$#" -ne 1 ]
then
    usage
fi

plutil -replace OpenPassClientId -string "$1" Development/OpenPassDevelopmentApp/Info.plist
