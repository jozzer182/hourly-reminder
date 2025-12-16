//
//  RemindersView.swift
//  Hourly Reminder
//
//  Main view for hourly reminders tab
//

import SwiftUI

/// Main view for managing hourly reminders
struct RemindersView: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if storageManager.reminderSets.isEmpty {
                    // Empty state
                    ContentUnavailableView {
                        Label(
                            NSLocalizedString("No Reminders", comment: "Empty state title"),
                            systemImage: "clock.badge.xmark"
                        )
                    } description: {
                        Text("Tap + to add hourly reminders")
                    } actions: {
                        Button {
                            addNewReminder()
                        } label: {
                            Text("Add Reminder")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    // Reminder list
                    List {
                        ForEach($storageManager.reminderSets) { $reminderSet in
                            ReminderCardView(reminderSet: $reminderSet)
                        }
                        .onDelete(perform: deleteReminders)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(NSLocalizedString("Hourly Reminders", comment: "Nav title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addNewReminder()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func addNewReminder() {
        let newReminder = ReminderSet()
        storageManager.addReminderSet(newReminder)
        notificationManager.rescheduleAll()
    }
    
    private func deleteReminders(at offsets: IndexSet) {
        storageManager.reminderSets.remove(atOffsets: offsets)
        storageManager.saveReminderSets()
        notificationManager.rescheduleAll()
    }
}

/// Card view for a single reminder set
struct ReminderCardView: View {
    @Binding var reminderSet: ReminderSet
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row with toggle and time info
            HStack {
                // Enable/Disable toggle
                Toggle("", isOn: $reminderSet.enabled)
                    .labelsHidden()
                    .onChange(of: reminderSet.enabled) { _, _ in
                        saveAndReschedule()
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    // Hours display
                    Text(reminderSet.hoursDisplay)
                        .font(.headline)
                        .foregroundStyle(reminderSet.enabled ? .primary : .secondary)
                    
                    // Interval and weekdays
                    HStack(spacing: 8) {
                        Text(reminderSet.repeatIntervalText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .foregroundStyle(.secondary)
                        
                        Text(reminderSet.weekdaysDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Expand button
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Expanded content
            if isExpanded {
                Divider()
                
                // Hour selection grid
                HourGridView(selectedHours: $reminderSet.hours)
                    .onChange(of: reminderSet.hours) { _, _ in
                        saveAndReschedule()
                    }
                
                // Interval picker
                Picker(NSLocalizedString("Repeat", comment: "Interval picker"), selection: $reminderSet.repeatInterval) {
                    Text(NSLocalizedString("Hourly", comment: "")).tag(60)
                    Text(NSLocalizedString("Every 30 min", comment: "")).tag(30)
                    Text(NSLocalizedString("Every 15 min", comment: "")).tag(15)
                }
                .pickerStyle(.segmented)
                .onChange(of: reminderSet.repeatInterval) { _, _ in
                    saveAndReschedule()
                }
                
                // Weekday selection
                WeekdayPicker(selectedDays: $reminderSet.weekdays, weekdaysCheck: $reminderSet.weekdaysCheck)
                    .onChange(of: reminderSet.weekdays) { _, _ in
                        saveAndReschedule()
                    }
                    .onChange(of: reminderSet.weekdaysCheck) { _, _ in
                        saveAndReschedule()
                    }
                
                // Sound options
                HStack {
                    Toggle(NSLocalizedString("Beep", comment: ""), isOn: $reminderSet.beep)
                        .onChange(of: reminderSet.beep) { _, _ in
                            saveAndReschedule()
                        }
                    
                    Toggle(NSLocalizedString("Speech", comment: ""), isOn: $reminderSet.speech)
                        .onChange(of: reminderSet.speech) { _, _ in
                            saveAndReschedule()
                        }
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func saveAndReschedule() {
        storageManager.updateReminderSet(reminderSet)
        notificationManager.rescheduleAll()
    }
}

#Preview {
    RemindersView()
        .environmentObject(StorageManager.shared)
        .environmentObject(NotificationManager.shared)
}
