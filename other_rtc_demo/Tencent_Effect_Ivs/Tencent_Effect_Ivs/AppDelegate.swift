//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

import UIKit
import YTCommonXMagic

private let kTELicenseURL = "please set your license url"
private let kTELicenseKey = "please set your license key"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        TEBeautyKit.setTELicense(kTELicenseURL, key: kTELicenseKey){ authresult, errorMsg in
            if authresult == 0{
                print("+> license check success")
            }else{
                print("+> license check failed")
            }
        }
        return true
    }

}

