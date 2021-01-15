#!/usr/bin/env bash


UITEST_PATH='UITestDemo.UITest'

# Build UITest project
eval MSBuild $APPCENTER_SOURCE_DIRECTORY/$UITEST_PATH -v:q 

# DEBUGGING
echo "contents of UITest directory:" 
ls $APPCENTER_SOURCE_DIRECTORY/$UITEST_PATH

# Upload tests
App_Center_Test_Command='appcenter test run uitest --app $TEAM_APP --devices $DEVICE_SET --app-path $APPCENTER_OUTPUT_DIRECTORY/$APP_PACKAGE  --test-series "gh-$APPCENTER_BRANCH" --locale "en_US" --build-dir $APPCENTER_SOURCE_DIRECTORY/$UITEST_PATH/bin/Debug --async --token $API_TOKEN --uitest-tools-dir $APPCENTER_SOURCE_DIRECTORY/packages/Xamarin.UITest.*/tools'

echo $App_Center_Test_Command
eval $App_Center_Test_Command

# End
echo "end post-build script"
