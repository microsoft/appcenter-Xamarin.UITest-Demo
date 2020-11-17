#!/usr/bin/env bash

# Comments
echo "app center version info to output folder"
cp $HOME/systeminfo.md $APPCENTER_OUTPUT_DIRECTORY/systeminfo.md

#echo "list home contents"
#eval ls $HOME

echo "contents of hostedtoolcache"
eval ls $HOME/hostedtoolcache
