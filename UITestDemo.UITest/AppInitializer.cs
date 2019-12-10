using System;
using System.IO;
using System.Linq;
using Xamarin.UITest;
using Xamarin.UITest.Queries;

namespace UITestDemo.UITest
{
    public class AppInitializer
    {
        public static IApp StartApp(Platform platform)
        {
            // TODO: If the iOS or Android app being tested is included in the solution 
            // then open the Unit Tests window, right click Test Apps, select Add App Project
            // and select the app projects that should be tested.
            //
            // The iOS project should have the Xamarin.TestCloud.Agent NuGet package
            // installed. To start the Test Cloud Agent the following code should be
            // added to the FinishedLaunching method of the AppDelegate:
            //
            //    #if ENABLE_TEST_CLOUD
            //    Xamarin.Calabash.Start();
            //    #endif
            if (platform == Platform.Android)
            {
                return ConfigureApp
                    .Android
                    // TODO: You must use .ApkFile() if: 
                    // a) runnning on Windows 
                    // b) or your Android project is not referenced by the UITest project.
                    //.ApkFile ("../../../precompiledApps/com.companyname.UITestDemo.apk")
                    .StartApp();
            }

            // Workaround for iOS simulator reset bug
            Environment.SetEnvironmentVariable("UITEST_FORCE_IOS_SIM_RESTART", "1");

            return ConfigureApp
                .iOS
                // TODO: Update this path to point to your iOS app and uncomment the
                // code if the app is not included in the solution. 
                // The .AppBundle method is only supported for iOS simulators.
                // .AppBundle ("../../../precompiledApps/UITestDemo.iOS.app")
                // 
                // .InstalledApp requires you to build an IPA using the Debug 
                // configuration & a valid provisioning profile, and preinstalling
                // it on the target device.
                // .InstalledApp("com.companyname.UITestDemo")
                .StartApp();
        }
    }
}
