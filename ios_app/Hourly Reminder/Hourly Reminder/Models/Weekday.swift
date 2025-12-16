//
//  Weekday.swift
//  Hourly Reminder
//
//  iOS equivalent of Android's Week.java
//

import Foundation

/// Represents days of the week for alarm/reminder scheduling
enum Weekday: Int, CaseIterable, Codable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var id: Int { rawValue }
    
    /// Short display name (Mon, Tue, etc.)
    var shortName: String {
        switch self {
        case .sunday: return NSLocalizedString("Sun", comment: "Sunday short")
        case .monday: return NSLocalizedString("Mon", comment: "Monday short")
        case .tuesday: return NSLocalizedString("Tue", comment: "Tuesday short")
        case .wednesday: return NSLocalizedString("Wed", comment: "Wednesday short")
        case .thursday: return NSLocalizedString("Thu", comment: "Thursday short")
        case .friday: return NSLocalizedString("Fri", comment: "Friday short")
        case .saturday: return NSLocalizedString("Sat", comment: "Saturday short")
        }
    }
    
    /// Single letter display (M, T, W, etc.)
    var letter: String {
        switch self {
        case .sunday: return NSLocalizedString("S", comment: "Sunday letter")
        case .monday: return NSLocalizedString("M", comment: "Monday letter")
        case .tuesday: return NSLocalizedString("T", comment: "Tuesday letter")
        case .wednesday: return NSLocalizedString("W", comment: "Wednesday letter")
        case .thursday: return NSLocalizedString("T", comment: "Thursday letter")
        case .friday: return NSLocalizedString("F", comment: "Friday letter")
        case .saturday: return NSLocalizedString("S", comment: "Saturday letter")
        }
    }
    
    /// Full day name
    var fullName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.weekdaySymbols[rawValue - 1]
    }
    
    /// Check if this is a weekday (Mon-Fri)
    var isWeekday: Bool {
        self != .saturday && self != .sunday
    }
    
    /// Check if this is a weekend day
    var isWeekend: Bool {
        self == .saturday || self == .sunday
    }
    
    /// Get current weekday from Date
    static func from(date: Date) -> Weekday {
        let calendar = Calendar.current
        let component = calendar.component(.weekday, from: date)
        return Weekday(rawValue: component) ?? .sunday
    }
    
    /// All weekdays (Mon-Fri)
    static var weekdays: Set<Weekday> {
        Set([.monday, .tuesday, .wednesday, .thursday, .friday])
    }
    
    /// Weekend days (Sat-Sun)
    static var weekend: Set<Weekday> {
        Set([.saturday, .sunday])
    }
    
    /// All days
    static var everyday: Set<Weekday> {
        Set(Weekday.allCases)
    }
    
    /// Get ordered days starting from a specific day
    static func orderedFrom(startDay: Weekday) -> [Weekday] {
        let all = Weekday.allCases
        guard let startIndex = all.firstIndex(of: startDay) else { return all }
        return Array(all[startIndex...]) + Array(all[..<startIndex])
    }
}
