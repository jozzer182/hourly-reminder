//
//  NotificationManager.swift
//  Hourly Reminder
//
//  Handles scheduling and managing local notifications for alarms and reminders
//  iOS equivalent of Android's AlarmManager + AlarmService
//

import Foundation
import UserNotifications
import AVFoundation
import Combine

/// Notification category identifiers
enum NotificationCategory {
    static let alarm = "ALARM_CATEGORY"
    static let reminder = "REMINDER_CATEGORY"
}

/// Notification action identifiers
enum NotificationAction {
    static let snooze = "SNOOZE_ACTION"
    static let dismiss = "DISMISS_ACTION"
}

/// Manages local notifications for alarms and reminders
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private let center = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        center.delegate = self
        setupCategories()
    }
    
    // MARK: - Authorization
    
    /// Request notification permission
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]
            let granted = try await center.requestAuthorization(options: options)
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    /// Check current authorization status
    func checkAuthorization() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }
    
    // MARK: - Categories Setup
    
    private func setupCategories() {
        // Alarm category with Snooze and Dismiss actions
        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze,
            title: NSLocalizedString("Snooze", comment: "Snooze button"),
            options: []
        )
        
        let dismissAction = UNNotificationAction(
            identifier: NotificationAction.dismiss,
            title: NSLocalizedString("Dismiss", comment: "Dismiss button"),
            options: [.destructive]
        )
        
        let alarmCategory = UNNotificationCategory(
            identifier: NotificationCategory.alarm,
            actions: [snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Reminder category with just Dismiss
        let reminderCategory = UNNotificationCategory(
            identifier: NotificationCategory.reminder,
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([alarmCategory, reminderCategory])
    }
    
    // MARK: - Schedule Alarm
    
    /// Schedule a notification for an alarm
    func scheduleAlarm(_ alarm: Alarm) {
        guard alarm.enabled else { return }
        guard let fireDate = alarm.nextFireDate() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Alarm", comment: "Alarm notification title")
        content.body = alarm.formatTime() + " " + alarm.amPm
        content.categoryIdentifier = NotificationCategory.alarm
        content.userInfo = ["alarmId": alarm.id.uuidString, "type": "alarm"]
        
        // Use custom sound or default alarm sound
        if let soundName = alarm.ringtoneIdentifier {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
        } else {
            content.sound = UNNotificationSound.defaultCritical
        }
        
        // Create trigger based on fire date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "alarm_\(alarm.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling alarm notification: \(error)")
            } else {
                print("Scheduled alarm for \(fireDate)")
            }
        }
    }
    
    /// Cancel alarm notification
    func cancelAlarm(_ alarm: Alarm) {
        center.removePendingNotificationRequests(withIdentifiers: ["alarm_\(alarm.id.uuidString)"])
    }
    
    // MARK: - Schedule Reminder
    
    /// Schedule a notification for a reminder
    func scheduleReminder(_ reminder: Reminder, from reminderSet: ReminderSet) {
        guard let fireDate = reminder.nextFireDate() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Reminder", comment: "Reminder notification title")
        content.body = formatTimeForSpeech(hour: reminder.hour, minute: reminder.minute)
        content.categoryIdentifier = NotificationCategory.reminder
        content.userInfo = [
            "reminderId": reminder.id.uuidString,
            "reminderSetId": reminderSet.id.uuidString,
            "type": "reminder"
        ]
        
        // Use pre-recorded audio based on minute (for when app is in background)
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundFileName(for: reminder.minute)))
        
        // Create trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "reminder_\(reminder.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling reminder notification: \(error)")
            }
        }
    }
    
    // MARK: - Schedule All
    
    /// Reschedule all alarms and reminders
    func rescheduleAll() {
        // Cancel existing
        center.removeAllPendingNotificationRequests()
        
        let storage = StorageManager.shared
        
        // Schedule alarms
        for alarm in storage.alarms where alarm.enabled {
            scheduleAlarm(alarm)
        }
        
        // Schedule reminders
        for reminderSet in storage.reminderSets where reminderSet.enabled {
            for reminder in reminderSet.generateReminders() {
                scheduleReminder(reminder, from: reminderSet)
            }
        }
        
        // Update pending list
        Task {
            await updatePendingList()
        }
    }
    
    /// Update the list of pending notifications
    func updatePendingList() async {
        let requests = await center.pendingNotificationRequests()
        await MainActor.run {
            self.pendingNotifications = requests
        }
    }
    
    // MARK: - Helpers
    
    /// Format time for speech/display
    private func formatTimeForSpeech(hour: Int, minute: Int, speakAmPm: Bool = true) -> String {
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let amPm = hour < 12 ? "AM" : "PM"
        
        if minute == 0 {
            return speakAmPm ? "\(displayHour) o'clock \(amPm)" : "\(displayHour) o'clock"
        } else {
            return speakAmPm ? "\(displayHour):\(String(format: "%02d", minute)) \(amPm)" : "\(displayHour):\(String(format: "%02d", minute))"
        }
    }
    
    /// Get the pre-recorded sound file name based on the minute
    private func soundFileName(for minute: Int) -> String {
        switch minute {
        case 0:  return "minute_00.caf"
        case 15: return "minute_15.caf"
        case 30: return "minute_30.caf"
        case 45: return "minute_45.caf"
        default: return "minute_00.caf"  // Fallback to "en punto"
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        
        // Speak the time when notification fires (for reminders)
        if userInfo["type"] as? String == "reminder" {
            // Small delay to let the notification sound play first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                TTSManager.shared.speakCurrentTime()
            }
        }
        
        // Show banner and play sound even when app is foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle notification action (Snooze, Dismiss)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionId = response.actionIdentifier
        
        // Handle reminder notifications - speak the time when tapped
        if userInfo["type"] as? String == "reminder" {
            TTSManager.shared.speakCurrentTime()
        }
        
        if let alarmIdString = userInfo["alarmId"] as? String,
           let alarmId = UUID(uuidString: alarmIdString) {
            handleAlarmAction(alarmId: alarmId, action: actionId)
        }
        
        completionHandler()
    }
    
    private func handleAlarmAction(alarmId: UUID, action: String) {
        let storage = StorageManager.shared
        
        guard var alarm = storage.alarms.first(where: { $0.id == alarmId }) else { return }
        
        switch action {
        case NotificationAction.snooze:
            alarm.snooze(minutes: storage.snoozeMinutes)
            storage.updateAlarm(alarm)
            scheduleAlarm(alarm)
            
        case NotificationAction.dismiss, UNNotificationDismissActionIdentifier:
            alarm.clearSnooze()
            // If one-time alarm, disable it
            if !alarm.weekdaysCheck {
                alarm.enabled = false
            }
            storage.updateAlarm(alarm)
            // Schedule next occurrence if repeating
            if alarm.enabled {
                scheduleAlarm(alarm)
            }
            
        default:
            break
        }
    }
}
