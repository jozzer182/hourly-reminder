//
//  TimezoneObserver.swift
//  Hourly Reminder
//
//  Observes timezone changes and reschedules alarms
//

import Foundation
import Combine
import UIKit

/// Observes system timezone changes and triggers alarm rescheduling
class TimezoneObserver: ObservableObject {
    static let shared = TimezoneObserver()
    
    @Published var currentTimezone: TimeZone = TimeZone.current
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe timezone changes via NotificationCenter
        NotificationCenter.default.publisher(for: NSNotification.Name.NSSystemTimeZoneDidChange)
            .sink { [weak self] _ in
                self?.handleTimezoneChange()
            }
            .store(in: &cancellables)
        
        // Also observe significant time changes (e.g., daylight saving time)
        NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)
            .sink { [weak self] _ in
                self?.handleSignificantTimeChange()
            }
            .store(in: &cancellables)
    }
    
    private func handleTimezoneChange() {
        let newTimezone = TimeZone.current
        
        print("Timezone changed from \(currentTimezone.identifier) to \(newTimezone.identifier)")
        
        currentTimezone = newTimezone
        
        // Reschedule all notifications with new timezone
        NotificationManager.shared.rescheduleAll()
        
        // Recalculate alarm times
        recalculateAlarmTimes()
    }
    
    private func handleSignificantTimeChange() {
        print("Significant time change detected")
        
        // Reschedule all notifications
        NotificationManager.shared.rescheduleAll()
    }
    
    private func recalculateAlarmTimes() {
        let storage = StorageManager.shared
        
        // Update any snoozed alarms that might be affected
        for (index, alarm) in storage.alarms.enumerated() {
            if alarm.isSnoozed {
                // Check if snoozed time is still valid
                if let snoozedTime = alarm.snoozedTime, snoozedTime < Date() {
                    // Snooze time has passed, clear it
                    var updatedAlarm = alarm
                    updatedAlarm.clearSnooze()
                    storage.alarms[index] = updatedAlarm
                }
            }
        }
        
        storage.saveAlarms()
    }
}
