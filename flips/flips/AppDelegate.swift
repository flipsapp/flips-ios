//
// Copyright 2014 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let BUGSENSE_KEY = "2b57f78e"
    private let FLURRY_KEY = "7CCBCSMWJQ395RJKDP5Y"
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        NetworkReachabilityHelper.sharedInstance.startMonitoring()

        // Registering for BugSense
        Mint.sharedInstance().initAndStartSession(BUGSENSE_KEY)
        
        Flurry.startSession(FLURRY_KEY)
        
        // Registering for receive messages
        MessageReceiver.sharedInstance.startListeningMessages()
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        CoreDataHandler.sharedInstance.setupDatabase()
    
        if (launchOptions != nil) {
            if let pushNotificationPayload = launchOptions![UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary {
                self.onNotificationReceived(application, withUserInfo: pushNotificationPayload)
            } else {
                openSplashScreen()
            }
        } else {
            openSplashScreen()
        }
        
        NavigationHandler.sharedInstance.registerForNotifications()
        
        // register for push notifications
        
        if (DeviceHelper.sharedInstance.systemVersion() >= 8.0) {
            application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: (UIUserNotificationType.Alert | UIUserNotificationType.Sound | UIUserNotificationType.Badge), categories: nil))
            application.registerForRemoteNotifications()
        } else {
            application.registerForRemoteNotificationTypes(UIRemoteNotificationType.Alert | UIRemoteNotificationType.Sound | UIRemoteNotificationType.Badge)
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            TempFiles.clearTempFiles()
        })
        
        return true;
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String, annotation: AnyObject?) -> Bool {
        return FBAppCall.handleOpenURL(url, sourceApplication: sourceApplication)
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        FBAppCall.handleDidBecomeActive()
    }

    func applicationWillTerminate(application: UIApplication) {
        MagicalRecord.cleanUp()
    }
    
    func application(application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: String) -> Bool {
        return extensionPointIdentifier != "com.apple.keyboard-service"
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        if let loggedUser = User.loggedUser() {
            application.applicationIconBadgeNumber = loggedUser.countUnreadMessages()
        }
    }
    
    // MARK: - Notification Methods
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        var token = deviceToken.description.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<>"))
        token = token.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        println("token: \(token)")
        DeviceHelper.sharedInstance.saveDeviceToken(token)
        DeviceHelper.sharedInstance.saveDeviceTokenAsNsData(deviceToken)
        PubNubService.sharedInstance.enablePushNotificationOnMyChannels()
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        if (identifier == "declineAction") {
            println("User did not allow to receive push notifications")
        } else if (identifier == "answerAction") {
            println("User allowed to receive push notifications")
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        self.incrementBadgeCounter()
        self.onNotificationReceived(application, withUserInfo: userInfo)
        completionHandler(UIBackgroundFetchResult.NewData)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        println(error.description)
    }
    
    // MARK: - Badge functions
    
    func incrementBadgeCounter() -> Int {
        var newValue = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
        UIApplication.sharedApplication().applicationIconBadgeNumber = newValue
        return newValue
    }
    
    // MARK: - private functions
    
    private func openSplashScreen(roomID: String? = nil, andFlipMessageID flipMessageID: String? = nil) {
        let splashScreenViewController = SplashScreenViewController(roomID: roomID, flipMessageID: flipMessageID)
        let navigationViewControler = UINavigationController(rootViewController: splashScreenViewController)
        self.window?.rootViewController = navigationViewControler
        self.window?.makeKeyAndVisible()
    }
  
    private func onNotificationReceived(application: UIApplication, withUserInfo userInfo: [NSObject : AnyObject]) {
        if let loggedUser = User.loggedUser() {
            if let roomId = (userInfo[NOTIFICATION_ROOM_KEY] as? String) {
                let flipMessageId: String = userInfo[NOTIFICATION_FLIP_MESSAGE_KEY] as String
                if (UIApplication.sharedApplication().keyWindow == nil)  {
                    self.openSplashScreen(roomID: roomId, andFlipMessageID: flipMessageId)
                } else if (application.applicationState != UIApplicationState.Active) {
                    NavigationHandler.sharedInstance.showThreadScreenForRoomId(roomId, andFlipMessageID: flipMessageId)
                }
            }
        }
    }
    

}