//
//  AlarmFiringView.swift
//  Hourly Reminder
//
//  Full screen view displayed when an alarm fires
//  iOS equivalent of Android's AlarmActivity
//

import SwiftUI
import Combine

/// Full screen view displayed when an alarm is firing
struct AlarmFiringView: View {
    let alarm: Alarm
    let onSnooze: () -> Void
    let onDismiss: () -> Void
    
    @State private var currentTime = Date()
    @State private var animationScale: CGFloat = 1.0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Alarm icon with pulsing animation
                Image(systemName: "alarm.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                    .scaleEffect(animationScale)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                        value: animationScale
                    )
                
                // Current time
                Text(timeString)
                    .font(.system(size: 72, weight: .light, design: .default))
                    .foregroundStyle(.white)
                
                // Alarm time label
                Text(NSLocalizedString("Alarm", comment: ""))
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
                
                Text(alarm.formatTime() + " " + alarm.amPm)
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                
                if alarm.isSnoozed {
                    Label(NSLocalizedString("Snoozed", comment: ""), systemImage: "moon.zzz")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 60) {
                    // Snooze button
                    VStack(spacing: 8) {
                        Button(action: onSnooze) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 32))
                                .frame(width: 80, height: 80)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                                .foregroundStyle(.white)
                        }
                        
                        Text(NSLocalizedString("Snooze", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    // Dismiss button
                    VStack(spacing: 8) {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 32, weight: .bold))
                                .frame(width: 80, height: 80)
                                .background(Color.red.opacity(0.8))
                                .clipShape(Circle())
                                .foregroundStyle(.white)
                        }
                        
                        Text(NSLocalizedString("Dismiss", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            animationScale = 1.2
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }
}

/// Coordinator to show alarm firing view
class AlarmFiringCoordinator: ObservableObject {
    static let shared = AlarmFiringCoordinator()
    
    @Published var activeAlarm: Alarm?
    @Published var isPresented = false
    
    private init() {}
    
    func showAlarm(_ alarm: Alarm) {
        activeAlarm = alarm
        isPresented = true
        
        // Play alarm sound
        SoundManager.shared.playAlarmSound()
        
        // Speak time if TTS enabled
        TTSManager.shared.speakCurrentTime()
        
        // Vibrate
        if StorageManager.shared.vibrateEnabled {
            SoundManager.shared.vibratePattern()
        }
    }
    
    func snoozeAlarm() {
        guard var alarm = activeAlarm else { return }
        
        alarm.snooze(minutes: StorageManager.shared.snoozeMinutes)
        StorageManager.shared.updateAlarm(alarm)
        NotificationManager.shared.scheduleAlarm(alarm)
        
        SoundManager.shared.stopSound()
        isPresented = false
        activeAlarm = nil
    }
    
    func dismissAlarm() {
        guard var alarm = activeAlarm else { return }
        
        alarm.clearSnooze()
        if !alarm.weekdaysCheck {
            alarm.enabled = false
        }
        StorageManager.shared.updateAlarm(alarm)
        
        // Schedule next occurrence if repeating
        if alarm.enabled {
            NotificationManager.shared.scheduleAlarm(alarm)
        }
        
        SoundManager.shared.stopSound()
        isPresented = false
        activeAlarm = nil
    }
}

#Preview {
    AlarmFiringView(
        alarm: Alarm(hour: 7, minute: 30),
        onSnooze: {},
        onDismiss: {}
    )
}
