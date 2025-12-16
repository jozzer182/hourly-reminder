//
//  Hourly_ReminderApp.swift
//  Hourly Reminder
//
//  Created by JOSE ZARABANDA on 12/14/25.
//

import SwiftUI
import UserNotifications

@main
struct Hourly_ReminderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(StorageManager.shared)
                .environmentObject(NotificationManager.shared)
                .task {
                    _ = await NotificationManager.shared.requestAuthorization()
                    NotificationManager.shared.rescheduleAll()
                }
        }
    }
}

/// AppDelegate for handling notification callbacks
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Reschedule on foreground
        NotificationManager.shared.rescheduleAll()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear badge using modern API
        Task {
            try? await UNUserNotificationCenter.current().setBadgeCount(0)
        }
    }
}
