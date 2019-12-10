# Build Status Badges
- iOS App (simulator build) (master branch) - [![Build status](https://build.appcenter.ms/v0.1/apps/0165f989-7687-45c4-8495-fd1f3e22a728/branches/master/badge)](https://appcenter.ms)

# Overview (Xamarin.UITest - Cross-Platform)
This sample is designed for use in Visual Studio & includes the sourcecode for a Xamarin.Forms app on Android & iOS platforms & a Xamarin.UITest project. It also includes a precompiled APK & IPA incase you want to try only building, running and uploading Xamarin.UITest.

# Building & running locally
You can either build the entire solution, or you can just build the Xamarin.UITest project. 

## Windows users
Compared to running on Mac, Xamarin.UITests have additional requirements and limitations as follows:
- Xamarin.UITest cannot be run locally against iOS apps in Windows, even if using a paired Mac capable of building iOS apps.
- NUnitTestAdapter 2.1.1 is required to run tests locally in Windows. It is not required to run tests in Mac or tests submitted to Visual Studio App Center Test.
- You must set the ANDROID_HOME enviroment variable to the main folder of your Android SDK. You can create this variable as follows:
    1. Go to **Control Panel > System > Advanced System Settings > Environment Variables > System Variables* > New…** 
    2. Name the variable `ANDROID_HOME` and set it to your Android SDK path. (For example `C:\Program Files (x86)\Android\android-sdk`, your location may vary.)
    3. Close all instances of Visual Studio and reopen for the updated `ANDROID_HOME` to take effect.
- You must use the `.ApkFile()` method to [point to the APK](UITestDemo.UITest/AppInitializer.cs#L30).

## Running locally without building the Android/iOS apps
You can run the UITest project locally without building the app projects by using precompiled files:

1. Open "UITestDemo.UITest > AppInitializer.cs"
2. Point to the app files:
- To use the precompiled APK, uncomment the line for '.ApkFile' 
- To use the precompiled iOS simulator .app, unzip the app & uncomment the line for '.AppBundle'
(You cannot use the precompiled IPA for local testing because it will not be signed for one of your devices. If you build the IPA for the project first though, you can install it on the device and point to it using '.InstalledApp'.)

3. Build the Xamarin.UITest project.
4. Running the tests differs slightly if you're using Visual Studio for Mac or Visual Studio on Windows:
   - **VS for Mac** - Go to **View > Pads > Unit Tests > Run All** 
   - **VS for Windows** - Go to **Test > Windows > Test Explorer > Run All**. When testing on Windows, only Android is supported.


## Running locally with building the Android/iOS apps
1. You can build individual projects or the entire solution by right-clicking them in the solution pad and selecting "Build [Project/Solution Name]." 

2. Be aware of the following considerations for using Xamarin.UITest with these built projects:
   - 'UITestDemo.Droid' must be built using a "Release" configuration. This is because by default a "Debug" build of a Xamarin.Android project includes the "Shared Mono Runtime" which is not compatible with Xamarin.UITest.
   - 'UITestDemo.iOS' must be built using a "Debug" configuration. This is because by default iOS apps built for distrbution are rejected from the iOS app store if they contain 'Calabash' the testing framework which allows Xamarin.UITest to interact with iOS apps. 
   - Android APKs can be run on either a physical Android device or emulator interchangably. iOS must use a '.app' build to run on an iOS simulator & an '.IPA' with a valid signing identity to run on an iOS device.

3. Running the tests differs slightly if you're using Visual Studio for Mac or Visual Studio on Windows:
   - **VS for Mac** - Go to **View > Pads > Unit Tests > Run All** 
   - **VS for Windows** - Go to **Test > Windows > Test Explorer > Run All**. When testing on Windows, only Android is supported; and you must also set the [`.ApkFile()` path in the AppInitializer.cs ConfigureApp statement](/Xamarin.UITest/UITestDemo/UITestDemo.UITest/AppInitializer.cs#L31)

# Uploading tests
1. Build the Xamarin.UITest project.
2. Generate a command line for upload: [Directions](/../../#upload-commands)
3. Update the upload command with project-specific arguments:
   - **OS X** paste your command as the value for 'AppCenter_Test_Command' in 'android.sh' or 'ios.sh' depending on the platform. You can run these files using 'sh android.sh' or 'sh ios.sh'.
   - **Windows** The '.sh' files are not technically compatible with Windows, however it shows how to modify the generated command to upload this sample manually.

#### See Also   
- Android upload script: [android.sh](android.sh)
- iOS upload script: [ios.sh](ios.sh)

# Building in App Center
Documentation reference: https://docs.microsoft.com/en-us/appcenter/build/
This blog also details most of the steps required, though a few details are out of date: https://tomsoderling.github.io/AppCenter-Automated-UI-tests-on-build/

**To build apps in App Center, you must own the repository you wish to build from. For example, to use the samples in this repo, you have to fork this repository.**

## Integrating Test Suite on Android
If you have the build working on it's own in App Center Build, then there just a few more steps to enable Test support. These steps are handled by the script called [appcenter-post-build.sh](Droid/appcenter-post-build.sh) in the "Droid" project folder. 

1. For this example, Add the Custom Environment Varaibles to your build settings in App Center:
   - `$API_KEY` - You can use an existing API key or generate a new one (https://intercom.help/appcenter/articles/1841885-how-to-use-app-center-s-api)
   - `$TEAM_APP` - This is the argument given to the `--app` flag in your Test upload command. 
   - `$DEVICE_SET` - This is the argument given to the `--devices` flag in your Test upload command. 

2. Make sure the first time you use the script to manually select "Save & Build" in the App Center Build dialog. Otherwise the build script will be ignored. 

### Background Info on how the script works
To use this script note the following:
- Technically all of the commented sections & 'echo' statements are just there to help you understand what the script is doing; the script would work if reduced only to declaring the variables & evaluating statements. 

- It's important to build the Xamarin.UITest project in the command line; as that is not handled automatically as part of the Android app project build. This is handled by the `MSBuild` command in the script.

- Your App Center upload command will require a few extra arguments compared to a typical upload:
   - `--aync` - This prevents your build from waiting for the test results and timing out. 
   - `--token` - Setting an API token since the Cloud Build machine is not logged in to your App Center identity. 
   - `--uitest-tools-dir` - Explicitly pointing to the Xamarin.UITest package tools folder. (Usually in a local system this is found automatically.)   

- There are 3 types of environment variables used to help the script:
   1. Variables created by App Center, which can be accessed directly by your script. These variables behave similarly to variables set universally on a local system. (Documentation: https://docs.microsoft.com/en-us/appcenter/build/custom/scripts/#app-center-variables)
   2. Variables created in your Build configuration settings. These will automatically be set for you on the Build VM, and can be used to store secure data such as login information; or even data that's tedious to manage within the script itself. (Documentation: https://docs.microsoft.com/en-us/appcenter/build/custom/variables/)
   3. Variables defined in the script itself. These are usually optional, but can make it easier to consistently handle particular actions or point to certain paths. In the sample post-build script, these include `UITEST_PATH` & `App_Center_Test_Command`


