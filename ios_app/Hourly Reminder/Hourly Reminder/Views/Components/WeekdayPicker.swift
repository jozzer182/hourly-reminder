//
//  WeekdayPicker.swift
//  Hourly Reminder
//
//  Reusable component for selecting days of the week
//

import SwiftUI

/// A horizontal row of circular buttons for selecting weekdays
struct WeekdayPicker: View {
    @Binding var selectedDays: Set<Weekday>
    @Binding var weekdaysCheck: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Toggle for weekday restriction
            Toggle(NSLocalizedString("Specific days", comment: ""), isOn: $weekdaysCheck)
                .font(.subheadline)
            
            if weekdaysCheck {
                // Day buttons
                HStack(spacing: 8) {
                    ForEach(orderedWeekdays, id: \.self) { day in
                        DayButton(
                            day: day,
                            isSelected: selectedDays.contains(day),
                            onTap: { toggleDay(day) }
                        )
                    }
                }
                
                // Quick select buttons
                HStack(spacing: 12) {
                    Button(NSLocalizedString("Weekdays", comment: "")) {
                        selectedDays = Weekday.weekdays
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button(NSLocalizedString("Weekend", comment: "")) {
                        selectedDays = Weekday.weekend
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button(NSLocalizedString("Everyday", comment: "")) {
                        selectedDays = Weekday.everyday
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .font(.caption)
            }
        }
    }
    
    private var orderedWeekdays: [Weekday] {
        // Start from Monday for display
        Weekday.orderedFrom(startDay: .monday)
    }
    
    private func toggleDay(_ day: Weekday) {
        if selectedDays.contains(day) {
            // Don't allow deselecting all days
            if selectedDays.count > 1 {
                selectedDays.remove(day)
            }
        } else {
            selectedDays.insert(day)
        }
    }
}

/// Individual day button
private struct DayButton: View {
    let day: Weekday
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(day.letter)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var days: Set<Weekday> = [.monday, .wednesday, .friday]
        @State private var check = true
        
        var body: some View {
            WeekdayPicker(selectedDays: $days, weekdaysCheck: $check)
                .padding()
        }
    }
    
    return PreviewWrapper()
}
