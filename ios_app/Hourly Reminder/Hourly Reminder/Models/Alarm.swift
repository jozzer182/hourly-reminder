//
//  Alarm.swift
//  Hourly Reminder
//
//  iOS equivalent of Android's Alarm.java
//

import Foundation

/// Represents a custom alarm with time, weekday selection, and sound settings
/// Equivalent to Android's Alarm class extending WeekTime
struct Alarm: Identifiable, Codable, Equatable {
    let id: UUID
    var hour: Int          // 0-23
    var minute: Int        // 0-59
    var enabled: Bool
    var weekdays: Set<Weekday>
    var weekdaysCheck: Bool  // If true, only fire on selected weekdays
    
    // Sound settings
    var ringtone: Bool      // Use ringtone sound
    var ringtoneIdentifier: String?  // Sound file name or system sound
    var beep: Bool          // Use beep sound
    
    // Snooze
    var snoozedTime: Date?  // If set, alarm was snoozed to this time
    
    /// Create a new alarm with default settings
    init(hour: Int = 9, minute: Int = 0) {
        self.id = UUID()
        self.hour = hour
        self.minute = minute
        self.enabled = true
        self.weekdays = Weekday.everyday
        self.weekdaysCheck = false
        self.ringtone = true
        self.ringtoneIdentifier = nil  // Default system sound
        self.beep = false
        self.snoozedTime = nil
    }
    
    /// Copy constructor
    init(copying other: Alarm) {
        self.id = UUID()  // New ID for copy
        self.hour = other.hour
        self.minute = other.minute
        self.enabled = other.enabled
        self.weekdays = other.weekdays
        self.weekdaysCheck = other.weekdaysCheck
        self.ringtone = other.ringtone
        self.ringtoneIdentifier = other.ringtoneIdentifier
        self.beep = other.beep
        self.snoozedTime = nil
    }
    
    // MARK: - Time Formatting
    
    /// Format time as "9:00" or "09:00" depending on 12/24h preference
    func formatTime(use24Hour: Bool = false) -> String {
        if use24Hour {
            return String(format: "%02d:%02d", hour, minute)
        } else {
            let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            return String(format: "%d:%02d", displayHour, minute)
        }
    }
    
    /// Get AM/PM suffix
    var amPm: String {
        hour < 12 ? NSLocalizedString("AM", comment: "Morning") : NSLocalizedString("PM", comment: "Afternoon")
    }
    
    /// Check if alarm is snoozed
    var isSnoozed: Bool {
        snoozedTime != nil
    }
    
    // MARK: - Scheduling
    
    /// Calculate next fire date from now
    func nextFireDate(from date: Date = Date()) -> Date? {
        guard enabled else { return nil }
        
        // If snoozed, return snooze time
        if let snoozed = snoozedTime, snoozed > date {
            return snoozed
        }
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        // If weekdays check is disabled, find next occurrence
        if !weekdaysCheck {
            // Get today at alarm time
            var todayComponents = calendar.dateComponents([.year, .month, .day], from: date)
            todayComponents.hour = hour
            todayComponents.minute = minute
            todayComponents.second = 0
            
            if let alarmToday = calendar.date(from: todayComponents) {
                // If alarm time already passed today, go to tomorrow
                if alarmToday > date {
                    return alarmToday
                } else {
                    return calendar.date(byAdding: .day, value: 1, to: alarmToday)
                }
            }
        } else {
            // Find next matching weekday
            for dayOffset in 0..<8 {
                guard let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: date) else { continue }
                let weekday = Weekday.from(date: futureDate)
                
                if weekdays.contains(weekday) {
                    var targetComponents = calendar.dateComponents([.year, .month, .day], from: futureDate)
                    targetComponents.hour = hour
                    targetComponents.minute = minute
                    targetComponents.second = 0
                    
                    if let targetDate = calendar.date(from: targetComponents), targetDate > date {
                        return targetDate
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Snooze the alarm by specified minutes
    mutating func snooze(minutes: Int = 10) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let now = Date()
        snoozedTime = calendar.date(byAdding: .minute, value: minutes, to: now)
    }
    
    /// Clear snooze
    mutating func clearSnooze() {
        snoozedTime = nil
    }
    
    /// Set time from a Date object
    mutating func setTime(from date: Date) {
        let calendar = Calendar.current
        hour = calendar.component(.hour, from: date)
        minute = calendar.component(.minute, from: date)
        clearSnooze()
    }
    
    /// Get a Date representing the alarm time (today)
    var timeAsDate: Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components) ?? Date()
    }
    
    // MARK: - Display Helpers
    
    /// Human-readable weekday description
    var weekdaysDescription: String {
        if weekdays.isEmpty || !weekdaysCheck {
            return NSLocalizedString("Once", comment: "One-time alarm")
        }
        if weekdays == Weekday.everyday {
            return NSLocalizedString("Everyday", comment: "Daily alarm")
        }
        if weekdays == Weekday.weekdays {
            return NSLocalizedString("Weekdays", comment: "Mon-Fri")
        }
        if weekdays == Weekday.weekend {
            return NSLocalizedString("Weekend", comment: "Sat-Sun")
        }
        
        // Custom selection - show short names
        let sorted = weekdays.sorted { $0.rawValue < $1.rawValue }
        return sorted.map { $0.shortName }.joined(separator: ", ")
    }
}
