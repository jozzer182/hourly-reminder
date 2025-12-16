//
//  SettingsView.swift
//  Hourly Reminder
//
//  Settings tab view with all app preferences
//

import SwiftUI

/// Main settings view with grouped preferences
struct SettingsView: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    // Settings state
    @AppStorage(StorageKeys.volumeReduce) private var volumeReduce: Double = 1.0
    @AppStorage(StorageKeys.increasingVolume) private var increasingVolume: Int = 0
    @AppStorage(StorageKeys.vibrate) private var vibrateEnabled: Bool = true
    @AppStorage(StorageKeys.wakeScreen) private var wakeScreen: Bool = true
    @AppStorage(StorageKeys.exactTime) private var exactTime: Bool = true
    @AppStorage(StorageKeys.snoozeDelay) private var snoozeDelay: Int = 10
    @AppStorage(StorageKeys.snoozeAfter) private var snoozeAfter: Int = 0
    @AppStorage(StorageKeys.ttsEnabled) private var ttsEnabled: Bool = true
    @AppStorage(StorageKeys.speakAmPm) private var speakAmPm: Bool = true
    @AppStorage(StorageKeys.silenceDuringCalls) private var silenceDuringCalls: Bool = true
    @AppStorage(StorageKeys.silenceDuringMusic) private var silenceDuringMusic: Bool = false
    @AppStorage(StorageKeys.weekStart) private var weekStart: String = "Sun"
    @AppStorage(StorageKeys.notifications) private var notificationsEnabled: Bool = true
    
    // TTS Preview state
    @State private var ttsFormat: SpeechFormat = TTSManager.shared.speechFormat
    @State private var customTemplate: String = TTSManager.shared.customTemplate
    @State private var previewHour: Int = 10
    @State private var previewMinute: Int = 30
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Sound Settings
                Section {
                    // Volume slider
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString("Volume", comment: ""))
                        Slider(value: $volumeReduce, in: 0...1, step: 0.1)
                    }
                    
                    // Increasing volume
                    Picker(NSLocalizedString("Increasing Volume", comment: ""), selection: $increasingVolume) {
                        Text(NSLocalizedString("Off", comment: "")).tag(0)
                        Text("1 sec").tag(1)
                        Text("2 sec").tag(2)
                        Text("3 sec").tag(3)
                        Text("4 sec").tag(4)
                        Text("5 sec").tag(5)
                    }
                } header: {
                    Text(NSLocalizedString("Sounds", comment: ""))
                }
                
                // MARK: - Reminder Settings
                Section {
                    Toggle(NSLocalizedString("Wake Up Screen", comment: ""), isOn: $wakeScreen)
                    Toggle(NSLocalizedString("Exact on Time", comment: ""), isOn: $exactTime)
                } header: {
                    Text(NSLocalizedString("Reminders", comment: ""))
                } footer: {
                    Text("Wake up screen on reminders. Exact time uses alarm event type.")
                }
                
                // MARK: - Alarm Settings
                Section {
                    // Snooze duration
                    Picker(NSLocalizedString("Snooze Duration", comment: ""), selection: $snoozeDelay) {
                        Text("1 min").tag(1)
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("15 min").tag(15)
                        Text("20 min").tag(20)
                    }
                    
                    // Auto snooze after
                    Picker(NSLocalizedString("Auto Snooze After", comment: ""), selection: $snoozeAfter) {
                        Text(NSLocalizedString("Off", comment: "")).tag(0)
                        Text("1 sec").tag(1)
                        Text("3 sec").tag(3)
                        Text("5 sec").tag(5)
                        Text("30 sec").tag(30)
                        Text("1 min").tag(60)
                        Text("5 min").tag(300)
                    }
                } header: {
                    Text(NSLocalizedString("Alarms", comment: ""))
                }
                
                // MARK: - Speech (TTS) Settings
                Section {
                    Toggle(NSLocalizedString("Speak Time", comment: ""), isOn: $ttsEnabled)
                    
                    if ttsEnabled {
                        // Format picker
                        Picker(NSLocalizedString("Speech Format", comment: ""), selection: $ttsFormat) {
                            ForEach(SpeechFormat.allCases) { format in
                                Text(format.displayName).tag(format)
                            }
                        }
                        .onChange(of: ttsFormat) { _, newValue in
                            TTSManager.shared.speechFormat = newValue
                        }
                        
                        // Custom template (only if custom format selected)
                        if ttsFormat == .custom {
                            HStack {
                                Text(NSLocalizedString("Template", comment: ""))
                                Spacer()
                                TextField("%M minutes", text: $customTemplate)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 150)
                                    .onChange(of: customTemplate) { _, newValue in
                                        TTSManager.shared.customTemplate = newValue
                                    }
                            }
                            
                            Text("Use %H for hour, %M for minutes, %A for AM/PM")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Toggle(NSLocalizedString("Speak AM/PM", comment: ""), isOn: $speakAmPm)
                            .onChange(of: speakAmPm) { _, newValue in
                                TTSManager.shared.speakAmPm = newValue
                            }
                        
                        // Preview section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(NSLocalizedString("Preview", comment: ""))
                                Spacer()
                                Button {
                                    TTSManager.shared.previewTime(hour: previewHour, minute: previewMinute)
                                } label: {
                                    HStack {
                                        Image(systemName: "play.circle.fill")
                                        Text(NSLocalizedString("Test", comment: ""))
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                            
                            // Time pickers for preview
                            HStack {
                                Picker("Hour", selection: $previewHour) {
                                    ForEach(0..<24, id: \.self) { h in
                                        Text("\(h)").tag(h)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 70)
                                
                                Text(":")
                                
                                Picker("Minute", selection: $previewMinute) {
                                    ForEach([0, 5, 10, 15, 30, 45], id: \.self) { m in
                                        Text(String(format: "%02d", m)).tag(m)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 70)
                                
                                Spacer()
                            }
                            
                            // Preview text
                            Text("→ \"\(TTSManager.shared.getPreviewText(hour: previewHour, minute: previewMinute))\"")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .italic()
                        }
                    }
                } header: {
                    Text(NSLocalizedString("Speech", comment: ""))
                } footer: {
                    Text("Configure how the time is announced via text-to-speech")
                }
                
                // MARK: - Haptic Settings
                Section {
                    Toggle(NSLocalizedString("Vibrate", comment: ""), isOn: $vibrateEnabled)
                } header: {
                    Text(NSLocalizedString("Haptics", comment: ""))
                }
                
                // MARK: - Silence Settings
                Section {
                    Toggle(NSLocalizedString("Silence During Calls", comment: ""), isOn: $silenceDuringCalls)
                    Toggle(NSLocalizedString("Silence During Music", comment: ""), isOn: $silenceDuringMusic)
                } header: {
                    Text(NSLocalizedString("Silence", comment: ""))
                }
                
                // MARK: - Application Settings
                Section {
                    // Theme selection
                    ThemePickerView()
                    
                    Picker(NSLocalizedString("Week Starts On", comment: ""), selection: $weekStart) {
                        Text(NSLocalizedString("Saturday", comment: "")).tag("Sat")
                        Text(NSLocalizedString("Sunday", comment: "")).tag("Sun")
                        Text(NSLocalizedString("Monday", comment: "")).tag("Mon")
                    }
                    
                    // Notification permission status
                    HStack {
                        Text(NSLocalizedString("Notifications", comment: ""))
                        Spacer()
                        if notificationManager.isAuthorized {
                            Text(NSLocalizedString("Enabled", comment: ""))
                                .foregroundStyle(.secondary)
                        } else {
                            Button(NSLocalizedString("Enable", comment: "")) {
                                openNotificationSettings()
                            }
                            .foregroundStyle(.blue)
                        }
                    }
                } header: {
                    Text(NSLocalizedString("Application", comment: ""))
                }
                
                // MARK: - About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle(NSLocalizedString("Settings", comment: "Nav title"))
        }
    }
    
    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(StorageManager.shared)
        .environmentObject(NotificationManager.shared)
}
