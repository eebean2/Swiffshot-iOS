//
//  AppDelegate.swift
//  Swiffshot
//
//  Created by Dmitry Kuklin on 22.11.16.
//  Copyright © 2016 Dmitry Kuklin. All rights reserved.
//

import UIKit
import Firebase
import OneSignal
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
		FIRApp.configure()
        OneSignal.initWithLaunchOptions(launchOptions, appId: "008e7d90-527f-474b-86ae-3f1851623269", handleNotificationReceived: { (notification) in
            print("Received Notification - Notification ID: \(String(describing: notification!.payload.notificationID!))")
        }, handleNotificationAction: { (result) in
            let payload: OSNotificationPayload? = result?.notification.payload
            
            var fullMessage: String? = payload?.body
            if payload?.additionalData != nil {
                var additionalData: [AnyHashable: Any]? = payload?.additionalData
                if additionalData!["actionSelected"] != nil {
                    fullMessage = fullMessage! + "\nPressed ButtonId:\(additionalData!["actionSelected"]!)"
                    if additionalData!["actionSelected"] as! String == "watch" {
                        let username = payload!.body.components(separatedBy: " ").last!
                        UserDefaults.standard.set(username, forKey: "UserAccepted")
                        NotificationCenter.default.post(name:Notification.Name(rawValue:"UserAccepted"), object: nil, userInfo: nil)
                    }
                }
            }
            print(fullMessage!)
        }, settings: [kOSSettingsKeyAutoPrompt: false,
                      kOSSettingsKeyInAppLaunchURL: true])
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification
        FIRAuth.auth()?.currentUser?.reload(completion: { (error) in
            if error != nil {
                print(error!.localizedDescription)
                SSContact.current.active = false
            }
        })
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        return handled
    }
	
    func applicationWillResignActive(_ application: UIApplication) {
        NotificationCenter.default.post(name: .UIApplicationWillResignActive, object: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) { }

    func applicationWillEnterForeground(_ application: UIApplication) { }

    func applicationDidBecomeActive(_ application: UIApplication) {
        FIRAuth.auth()?.currentUser?.reload(completion: { (error) in
            if error != nil {
                print(error!.localizedDescription)
                SSContact.current.active = false
            }
        })
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NotificationCenter.default.post(name: .UIApplicationWillTerminate, object: nil)
    }

}

