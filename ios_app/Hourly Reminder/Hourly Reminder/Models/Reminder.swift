//
//  Reminder.swift
//  Hourly Reminder
//
//  iOS equivalent of Android's Reminder.java and ReminderSet.java combined
//

import Foundation

/// Represents a single hourly reminder time slot
struct ReminderTime: Identifiable, Codable, Equatable, Hashable {
    var id: String { key }
    let hour: Int    // 0-23
    let minute: Int  // 0 or 30 (for half-hour reminders)
    
    /// Key for storage (e.g., "08" or "0830")
    var key: String {
        if minute == 0 {
            return String(format: "%02d", hour)
        } else {
            return String(format: "%02d%02d", hour, minute)
        }
    }
    
    init(hour: Int, minute: Int = 0) {
        self.hour = hour
        self.minute = minute
    }
    
    init?(key: String) {
        if key.count == 4 {
            guard let h = Int(key.prefix(2)),
                  let m = Int(key.suffix(2)) else { return nil }
            self.hour = h
            self.minute = m
        } else if key.count == 2 {
            guard let h = Int(key) else { return nil }
            self.hour = h
            self.minute = 0
        } else {
            return nil
        }
    }
    
    /// Format for display
    func formatShort(use24Hour: Bool = false) -> String {
        let h12 = ["12", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11",
                   "12", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"]
        
        if minute == 0 {
            return use24Hour ? String(format: "%02d", hour) : h12[hour]
        } else {
            let formatted = use24Hour ? String(format: "%02d", hour) : h12[hour]
            return "\(formatted):\(String(format: "%02d", minute))"
        }
    }
}

/// Represents a set of hourly reminders with shared settings
/// Equivalent to Android's ReminderSet class
struct ReminderSet: Identifiable, Codable, Equatable {
    let id: UUID
    var enabled: Bool
    var hours: Set<Int>        // Selected hours (0-23)
    var show30Minutes: Bool    // Show half-hour options
    var repeatInterval: Int    // Repeat every X minutes (15, 30, 60)
    var weekdays: Set<Weekday>
    var weekdaysCheck: Bool
    
    // Sound settings
    var ringtone: Bool
    var ringtoneIdentifier: String?
    var beep: Bool
    var speech: Bool  // Use TTS
    
    /// Create a new reminder set with default settings
    init() {
        self.id = UUID()
        self.enabled = true
        self.hours = Set([8, 9, 10, 11, 12])  // Default hours 8 AM - 12 PM
        self.show30Minutes = false
        self.repeatInterval = 60  // Hourly by default
        self.weekdays = Weekday.everyday
        self.weekdaysCheck = false
        self.ringtone = false
        self.ringtoneIdentifier = nil
        self.beep = true
        self.speech = true
    }
    
    /// Copy constructor
    init(copying other: ReminderSet) {
        self.id = UUID()
        self.enabled = other.enabled
        self.hours = other.hours
        self.show30Minutes = other.show30Minutes
        self.repeatInterval = other.repeatInterval
        self.weekdays = other.weekdays
        self.weekdaysCheck = other.weekdaysCheck
        self.ringtone = other.ringtone
        self.ringtoneIdentifier = other.ringtoneIdentifier
        self.beep = other.beep
        self.speech = other.speech
    }
    
    // MARK: - Reminder Generation
    
    /// Generate all individual reminders based on settings
    func generateReminders() -> [Reminder] {
        guard enabled else { return [] }
        
        var reminders: [Reminder] = []
        let sortedHours = hours.sorted()
        
        for hour in sortedHours {
            // Main hour reminder
            let reminder = Reminder(reminderSet: self, hour: hour, minute: 0)
            reminders.append(reminder)
            
            // Half-hour reminder if enabled
            if show30Minutes {
                let halfReminder = Reminder(reminderSet: self, hour: hour, minute: 30)
                reminders.append(halfReminder)
            }
            
            // Interval-based reminders (15, 30 min)
            if repeatInterval < 60 {
                var currentMin = repeatInterval
                while currentMin < 60 {
                    let intervalReminder = Reminder(reminderSet: self, hour: hour, minute: currentMin)
                    reminders.append(intervalReminder)
                    currentMin += repeatInterval
                }
            }
        }
        
        return reminders
    }
    
    /// Get display text for repeat interval
    var repeatIntervalText: String {
        switch repeatInterval {
        case 15: return NSLocalizedString("Every 15 min", comment: "15 minute interval")
        case 30: return NSLocalizedString("Every 30 min", comment: "30 minute interval")
        case 60: return NSLocalizedString("Hourly", comment: "60 minute interval (hourly)")
        default: return "\(repeatInterval) min"
        }
    }
    
    /// Human-readable weekday description
    var weekdaysDescription: String {
        if weekdays.isEmpty || !weekdaysCheck {
            return NSLocalizedString("Everyday", comment: "Daily reminder")
        }
        if weekdays == Weekday.everyday {
            return NSLocalizedString("Everyday", comment: "Daily reminder")
        }
        if weekdays == Weekday.weekdays {
            return NSLocalizedString("Weekdays", comment: "Mon-Fri")
        }
        if weekdays == Weekday.weekend {
            return NSLocalizedString("Weekend", comment: "Sat-Sun")
        }
        
        let sorted = weekdays.sorted { $0.rawValue < $1.rawValue }
        return sorted.map { $0.shortName }.joined(separator: ", ")
    }
    
    /// Get hours display (e.g., "8, 9, 10, 11, 12")
    var hoursDisplay: String {
        guard !hours.isEmpty else { return NSLocalizedString("No hours selected", comment: "") }
        let sorted = hours.sorted()
        return sorted.map { String($0) }.joined(separator: ", ")
    }
}

/// Represents a single reminder instance (generated from ReminderSet)
/// Equivalent to Android's Reminder class
struct Reminder: Identifiable, Codable, Equatable {
    let id: UUID
    let reminderSetId: UUID
    let hour: Int
    let minute: Int
    var weekdays: Set<Weekday>
    var weekdaysCheck: Bool
    
    init(reminderSet: ReminderSet, hour: Int, minute: Int) {
        self.id = UUID()
        self.reminderSetId = reminderSet.id
        self.hour = hour
        self.minute = minute
        self.weekdays = reminderSet.weekdays
        self.weekdaysCheck = reminderSet.weekdaysCheck
    }
    
    /// Check if reminder should sound at the given time
    func shouldSound(at date: Date) -> Bool {
        let calendar = Calendar.current
        let dateHour = calendar.component(.hour, from: date)
        let dateMinute = calendar.component(.minute, from: date)
        
        guard hour == dateHour && minute == dateMinute else { return false }
        
        if weekdaysCheck {
            let weekday = Weekday.from(date: date)
            return weekdays.contains(weekday)
        }
        
        return true
    }
    
    /// Calculate next fire date
    func nextFireDate(from date: Date = Date()) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        for dayOffset in 0..<8 {
            guard let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: date) else { continue }
            
            if weekdaysCheck {
                let weekday = Weekday.from(date: futureDate)
                guard weekdays.contains(weekday) else { continue }
            }
            
            var targetComponents = calendar.dateComponents([.year, .month, .day], from: futureDate)
            targetComponents.hour = hour
            targetComponents.minute = minute
            targetComponents.second = 0
            
            if let targetDate = calendar.date(from: targetComponents), targetDate > date {
                return targetDate
            }
        }
        
        return nil
    }
    
    /// Format time for display
    func formatTime(use24Hour: Bool = false) -> String {
        if use24Hour {
            return String(format: "%02d:%02d", hour, minute)
        } else {
            let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            return String(format: "%d:%02d", displayHour, minute)
        }
    }
    
    /// AM/PM suffix
    var amPm: String {
        hour < 12 ? "AM" : "PM"
    }
}
