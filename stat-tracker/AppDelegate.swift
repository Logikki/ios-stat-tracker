//
//  AppDelegate.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Custom setup when the app finishes launching
        print("App has launched")
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Handle events when the app is about to enter the foreground
        print("App will enter foreground")
    }
}
