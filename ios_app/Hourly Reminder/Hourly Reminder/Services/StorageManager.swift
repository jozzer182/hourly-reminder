//
//  StorageManager.swift
//  Hourly Reminder
//
//  Handles persistence of alarms and reminders using UserDefaults
//  iOS equivalent of Android's SharedPreferences storage in HourlyApplication
//

import Foundation
import Combine
import SwiftUI

/// Keys for UserDefaults storage
enum StorageKeys {
    // Alarms
    static let alarms = "hourly_reminder_alarms"
    static let reminders = "hourly_reminder_reminders"
    
    // Settings - Sounds
    static let volumeReduce = "pref_volume"
    static let increasingVolume = "pref_increasing_volume"
    static let customBeep = "pref_beep"
    
    // Settings - Reminders
    static let wakeScreen = "pref_wakeup"
    static let exactTime = "pref_alarm"
    static let show30Minutes = "pref_show30"
    
    // Settings - Alarms
    static let snoozeDelay = "pref_snooze_delay"
    static let snoozeAfter = "pref_snooze_after"
    
    // Settings - Speech (TTS)
    static let ttsEnabled = "pref_tts_enabled"
    static let ttsLanguage = "pref_tts_language"
    static let speakAmPm = "pref_tts_ampm"
    static let speakCustom = "pref_speak_custom"
    static let customSpeakText = "pref_speak_custom_text"
    
    // Settings - Haptics
    static let vibrate = "pref_vibrate"
    
    // Settings - Application
    static let theme = "pref_theme"
    static let weekStart = "pref_weekstart"
    static let notifications = "pref_notifications"
    static let silenceDuringCalls = "pref_call_silence"
    static let silenceDuringMusic = "pref_music_silence"
    static let lowSoundProfile = "pref_phone_silence"
}

/// Manages saving and loading of app data
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Published properties for reactive updates
    @Published var alarms: [Alarm] = []
    @Published var reminderSets: [ReminderSet] = []
    
    private init() {
        loadAll()
    }
    
    // MARK: - Alarms
    
    func saveAlarms() {
        do {
            let data = try encoder.encode(alarms)
            defaults.set(data, forKey: StorageKeys.alarms)
        } catch {
            print("Error saving alarms: \(error)")
        }
    }
    
    func loadAlarms() -> [Alarm] {
        guard let data = defaults.data(forKey: StorageKeys.alarms) else { return [] }
        do {
            return try decoder.decode([Alarm].self, from: data)
        } catch {
            print("Error loading alarms: \(error)")
            return []
        }
    }
    
    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        saveAlarms()
    }
    
    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            saveAlarms()
        }
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
    }
    
    func deleteAlarm(at offsets: IndexSet) {
        alarms.remove(atOffsets: offsets)
        saveAlarms()
    }
    
    // MARK: - Reminder Sets
    
    func saveReminderSets() {
        do {
            let data = try encoder.encode(reminderSets)
            defaults.set(data, forKey: StorageKeys.reminders)
        } catch {
            print("Error saving reminder sets: \(error)")
        }
    }
    
    func loadReminderSets() -> [ReminderSet] {
        guard let data = defaults.data(forKey: StorageKeys.reminders) else { return [] }
        do {
            return try decoder.decode([ReminderSet].self, from: data)
        } catch {
            print("Error loading reminder sets: \(error)")
            return []
        }
    }
    
    func addReminderSet(_ reminderSet: ReminderSet) {
        reminderSets.append(reminderSet)
        saveReminderSets()
    }
    
    func updateReminderSet(_ reminderSet: ReminderSet) {
        if let index = reminderSets.firstIndex(where: { $0.id == reminderSet.id }) {
            reminderSets[index] = reminderSet
            saveReminderSets()
        }
    }
    
    func deleteReminderSet(_ reminderSet: ReminderSet) {
        reminderSets.removeAll { $0.id == reminderSet.id }
        saveReminderSets()
    }
    
    func deleteReminderSet(at offsets: IndexSet) {
        reminderSets.remove(atOffsets: offsets)
        saveReminderSets()
    }
    
    // MARK: - Generate All Reminders
    
    /// Generate all individual reminders from all reminder sets
    func generateAllReminders() -> [Reminder] {
        reminderSets.filter { $0.enabled }.flatMap { $0.generateReminders() }
    }
    
    // MARK: - Load All
    
    func loadAll() {
        alarms = loadAlarms()
        reminderSets = loadReminderSets()
    }
    
    // MARK: - Settings Helpers
    
    var snoozeMinutes: Int {
        get { defaults.integer(forKey: StorageKeys.snoozeDelay).nonZero ?? 10 }
        set { defaults.set(newValue, forKey: StorageKeys.snoozeDelay) }
    }
    
    var vibrateEnabled: Bool {
        get { defaults.bool(forKey: StorageKeys.vibrate) }
        set { defaults.set(newValue, forKey: StorageKeys.vibrate) }
    }
    
    var ttsEnabled: Bool {
        get { defaults.bool(forKey: StorageKeys.ttsEnabled) }
        set { defaults.set(newValue, forKey: StorageKeys.ttsEnabled) }
    }
    
    var speakAmPm: Bool {
        get { defaults.bool(forKey: StorageKeys.speakAmPm) }
        set { defaults.set(newValue, forKey: StorageKeys.speakAmPm) }
    }
    
    var wakeScreen: Bool {
        get { defaults.bool(forKey: StorageKeys.wakeScreen) }
        set { defaults.set(newValue, forKey: StorageKeys.wakeScreen) }
    }
}

// MARK: - Extensions

private extension Int {
    var nonZero: Int? {
        self == 0 ? nil : self
    }
}
