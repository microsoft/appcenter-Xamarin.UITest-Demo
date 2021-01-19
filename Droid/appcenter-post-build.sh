#!/usr/bin/env bash

# Environment Variables created by App Center
# $APPCENTER_SOURCE_DIRECTORY
# $APPCENTER_OUTPUT_DIRECTORY
# $APPCENTER_BRANCH

# Custom Environment Variables
# $API_KEY
# $TEAM_APP
# $DEVICE_SET



#echo "Start Test upload script (ac-test-run.sh)"
#sh ../ac-test-run.sh
#echo "Finish Test upload script (ac-test-run.sh)"

#echo "Start Distribute script (ac-distribute.sh)"
#sh ../ac-distribute.sh
#echo "Finish Distribute script (ac-distribute.sh)"

if test -f "$APPCENTER_OUTPUT_DIRECTORY/com.appcenter.UITestDemo.apk"
then
    echo "$APPCENTER_OUTPUT_DIRECTORY/com.appcenter.UITestDemo.apk exists."
else
    echo "$APPCENTER_OUTPUT_DIRECTORY/com.appcenter.UITestDemo.apk doesn't exist'"
fi

echo "WC Syntax experiment"
wc -c $APPCENTER_OUTPUT_DIRECTORY/com.appcenter.UITestDemo.apk

echo "end post-build script"