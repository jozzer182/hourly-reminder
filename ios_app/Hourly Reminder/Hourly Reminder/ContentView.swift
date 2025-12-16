//
//  ContentView.swift
//  Hourly Reminder
//
//  Created by JOSE ZARABANDA on 12/14/25.
//

import SwiftUI

/// Main app view with 3 tabs: Reminders, Alarms, Settings
struct ContentView: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Hourly Reminders
            RemindersView()
                .tabItem {
                    Label(
                        NSLocalizedString("Reminders", comment: "Reminders tab"),
                        systemImage: "clock"
                    )
                }
                .tag(0)
            
            // Tab 2: Custom Alarms
            AlarmsView()
                .tabItem {
                    Label(
                        NSLocalizedString("Alarms", comment: "Alarms tab"),
                        systemImage: "alarm"
                    )
                }
                .tag(1)
            
            // Tab 3: Settings
            SettingsView()
                .tabItem {
                    Label(
                        NSLocalizedString("Settings", comment: "Settings tab"),
                        systemImage: "gearshape"
                    )
                }
                .tag(2)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(StorageManager.shared)
        .environmentObject(NotificationManager.shared)
}

