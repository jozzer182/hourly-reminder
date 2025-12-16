//
//  AlarmsView.swift
//  Hourly Reminder
//
//  Main view for custom alarms tab
//

import SwiftUI

/// Main view for managing custom alarms
struct AlarmsView: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var showingAddSheet = false
    @State private var editingAlarm: Alarm?
    
    var body: some View {
        NavigationStack {
            Group {
                if storageManager.alarms.isEmpty {
                    // Empty state
                    ContentUnavailableView {
                        Label(
                            NSLocalizedString("No Alarms", comment: "Empty state title"),
                            systemImage: "alarm.waves.left.and.right"
                        )
                    } description: {
                        Text("Tap + to add a custom alarm")
                    } actions: {
                        Button {
                            addNewAlarm()
                        } label: {
                            Text("Add Alarm")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    // Alarm list
                    List {
                        ForEach($storageManager.alarms) { $alarm in
                            AlarmCardView(alarm: $alarm)
                                .onTapGesture {
                                    editingAlarm = alarm
                                }
                        }
                        .onDelete(perform: deleteAlarms)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(NSLocalizedString("Custom Alarms", comment: "Nav title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addNewAlarm()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editingAlarm) { alarm in
                AlarmDetailSheet(alarm: binding(for: alarm))
            }
        }
    }
    
    private func addNewAlarm() {
        let newAlarm = Alarm()
        storageManager.addAlarm(newAlarm)
        editingAlarm = newAlarm
        notificationManager.rescheduleAll()
    }
    
    private func deleteAlarms(at offsets: IndexSet) {
        storageManager.alarms.remove(atOffsets: offsets)
        storageManager.saveAlarms()
        notificationManager.rescheduleAll()
    }
    
    private func binding(for alarm: Alarm) -> Binding<Alarm> {
        guard let index = storageManager.alarms.firstIndex(where: { $0.id == alarm.id }) else {
            return .constant(alarm)
        }
        return $storageManager.alarms[index]
    }
}

/// Card view for a single alarm
struct AlarmCardView: View {
    @Binding var alarm: Alarm
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Enable/Disable toggle
            Toggle("", isOn: $alarm.enabled)
                .labelsHidden()
                .onChange(of: alarm.enabled) { _, _ in
                    saveAndReschedule()
                }
            
            VStack(alignment: .leading, spacing: 4) {
                // Time display
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(alarm.formatTime())
                        .font(.system(size: 42, weight: .light, design: .default))
                        .foregroundStyle(alarm.enabled ? .primary : .secondary)
                    
                    Text(alarm.amPm)
                        .font(.title3)
                        .foregroundStyle(alarm.enabled ? .secondary : .tertiary)
                }
                
                // Weekdays and snooze info
                HStack(spacing: 8) {
                    Text(alarm.weekdaysDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if alarm.isSnoozed {
                        Label(NSLocalizedString("Snoozed", comment: ""), systemImage: "moon.zzz")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private func saveAndReschedule() {
        storageManager.updateAlarm(alarm)
        notificationManager.rescheduleAll()
    }
}

/// Sheet for editing alarm details
struct AlarmDetailSheet: View {
    @Binding var alarm: Alarm
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTime: Date
    
    init(alarm: Binding<Alarm>) {
        self._alarm = alarm
        self._selectedTime = State(initialValue: alarm.wrappedValue.timeAsDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        NSLocalizedString("Time", comment: ""),
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
                
                Section(header: Text("Repeat")) {
                    Toggle(NSLocalizedString("Repeat on weekdays", comment: ""), isOn: $alarm.weekdaysCheck)
                    
                    if alarm.weekdaysCheck {
                        WeekdayPicker(selectedDays: $alarm.weekdays, weekdaysCheck: .constant(true))
                    }
                }
                
                Section(header: Text("Sound")) {
                    Toggle(NSLocalizedString("Ringtone", comment: ""), isOn: $alarm.ringtone)
                    Toggle(NSLocalizedString("Beep", comment: ""), isOn: $alarm.beep)
                }
            }
            .navigationTitle(NSLocalizedString("Edit Alarm", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("Save", comment: "")) {
                        alarm.setTime(from: selectedTime)
                        storageManager.updateAlarm(alarm)
                        notificationManager.rescheduleAll()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    AlarmsView()
        .environmentObject(StorageManager.shared)
        .environmentObject(NotificationManager.shared)
}
