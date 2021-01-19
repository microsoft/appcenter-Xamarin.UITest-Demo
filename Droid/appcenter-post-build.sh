#!/usr/bin/env bash

# Environment Variables created by App Center
# $APPCENTER_SOURCE_DIRECTORY
# $APPCENTER_OUTPUT_DIRECTORY
# $APPCENTER_BRANCH

# Custom Environment Variables
# $API_KEY
# $TEAM_APP
# $DEVICE_SET

APP_PACKAGE=$(echo $APP_PACKAGE)

#echo "Start Test upload script (ac-test-run.sh)"
#sh ../ac-test-run.sh
#echo "Finish Test upload script (ac-test-run.sh)"

#echo "Start Distribute script (ac-distribute.sh)"
#sh ../ac-distribute.sh
#echo "Finish Distribute script (ac-distribute.sh)"

if test -f "$APP_PACKAGE"
then
    echo "$APP_PACKAGE exists."
else
    echo "$APP_PACKAGE doesn't exist'"
fi

echo "WC Syntax experiment"
wc -c $APP_PACKAGE

echo "end post-build script"