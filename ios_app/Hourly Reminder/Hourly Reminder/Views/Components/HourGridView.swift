//
//  HourGridView.swift
//  Hourly Reminder
//
//  Grid of 24 hours for selecting which hours to enable reminders
//

import SwiftUI

/// A grid of toggleable hour buttons (00-23)
struct HourGridView: View {
    @Binding var selectedHours: Set<Int>
    
    @AppStorage("use_24_hour") private var use24Hour: Bool = true
    
    // Layout: 4 rows of 6 columns
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 12h/24h toggle
            HStack {
                Text(NSLocalizedString("Hours", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Picker("", selection: $use24Hour) {
                    Text("12h").tag(false)
                    Text("24h").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
            
            // Hour grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<24, id: \.self) { hour in
                    HourButton(
                        hour: hour,
                        use24Hour: use24Hour,
                        isSelected: selectedHours.contains(hour),
                        onTap: { toggleHour(hour) }
                    )
                }
            }
            
            // Quick select buttons
            HStack(spacing: 12) {
                Button(NSLocalizedString("AM", comment: "Morning hours")) {
                    selectedHours = Set(0..<12)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(NSLocalizedString("PM", comment: "Afternoon hours")) {
                    selectedHours = Set(12..<24)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(NSLocalizedString("Work", comment: "9-5 hours")) {
                    selectedHours = Set(9...17)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(NSLocalizedString("All", comment: "All hours")) {
                    selectedHours = Set(0..<24)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(NSLocalizedString("Clear", comment: "Clear selection")) {
                    if selectedHours.count > 1 {
                        selectedHours = Set([selectedHours.first ?? 8])
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .font(.caption)
        }
    }
    
    private func toggleHour(_ hour: Int) {
        if selectedHours.contains(hour) {
            // Don't allow deselecting all hours
            if selectedHours.count > 1 {
                selectedHours.remove(hour)
            }
        } else {
            selectedHours.insert(hour)
        }
    }
}

/// Individual hour button
private struct HourButton: View {
    let hour: Int
    let use24Hour: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(displayText)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private var displayText: String {
        if use24Hour {
            return String(format: "%02d", hour)
        } else {
            let h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            let suffix = hour < 12 ? "a" : "p"
            return "\(h12)\(suffix)"
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var hours: Set<Int> = [8, 9, 10, 11, 12]
        
        var body: some View {
            HourGridView(selectedHours: $hours)
                .padding()
        }
    }
    
    return PreviewWrapper()
}
