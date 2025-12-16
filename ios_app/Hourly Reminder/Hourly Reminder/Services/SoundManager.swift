//
//  SoundManager.swift
//  Hourly Reminder
//
//  Handles audio playback for alarms and reminders
//  iOS equivalent of Android's Sound.java and Player.java
//

import Foundation
import AVFoundation
import AudioToolbox
import Combine
import UIKit
import UserNotifications

/// Manages sound playback for alarms and reminders
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var isPlaying = false
    
    // Volume settings
    @Published var volume: Float = 1.0
    @Published var increasingVolume: Bool = false
    private var volumeTimer: Timer?
    
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Play Sounds
    
    /// Play the default beep sound
    func playBeep() {
        // Use system sound for simple beep
        AudioServicesPlaySystemSound(1052) // Default notification sound
    }
    
    /// Play a custom beep with specified frequency and duration
    func playCustomBeep(frequency: Double = 880, duration: Double = 0.3) {
        // Generate a simple beep tone
        let sampleRate: Double = 44100
        let samples = Int(sampleRate * duration)
        var audioData = [Float](repeating: 0, count: samples)
        
        for i in 0..<samples {
            let t = Double(i) / sampleRate
            audioData[i] = Float(sin(2.0 * .pi * frequency * t) * 0.5)
            
            // Apply fade out
            let fadeStart = Int(Double(samples) * 0.7)
            if i > fadeStart {
                let fadeProgress = Float(i - fadeStart) / Float(samples - fadeStart)
                audioData[i] *= (1.0 - fadeProgress)
            }
        }
        
        // Play using AudioToolbox
        playBeep() // Fallback to system beep for now
    }
    
    /// Play alarm sound from bundle
    func playAlarmSound(named fileName: String = "alarm_default") {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "wav")
                ?? Bundle.main.url(forResource: fileName, withExtension: "mp3")
                ?? Bundle.main.url(forResource: fileName, withExtension: "caf") else {
            // Fallback to system alert sound
            playSystemAlertSound()
            return
        }
        
        playSound(from: url)
    }
    
    /// Play a sound from URL
    func playSound(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely for alarm
            
            if increasingVolume {
                audioPlayer?.volume = 0.1
                startVolumeRamp()
            } else {
                audioPlayer?.volume = volume
            }
            
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play sound: \(error)")
            playSystemAlertSound()
        }
    }
    
    /// Play system alert sound
    func playSystemAlertSound() {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        AudioServicesPlaySystemSound(1005) // SMS alert sound
    }
    
    /// Stop any playing sound
    func stopSound() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        volumeTimer?.invalidate()
        volumeTimer = nil
    }
    
    // MARK: - Volume Control
    
    private func startVolumeRamp() {
        audioPlayer?.volume = 0.1
        var currentVolume: Float = 0.1
        
        volumeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self, self.isPlaying else {
                timer.invalidate()
                return
            }
            
            currentVolume += 0.1
            if currentVolume >= self.volume {
                currentVolume = self.volume
                timer.invalidate()
            }
            
            self.audioPlayer?.volume = currentVolume
        }
    }
    
    // MARK: - Vibration
    
    /// Trigger haptic feedback
    func vibrate() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Trigger continuous vibration pattern
    func vibratePattern() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

// MARK: - Notification Sound Names

extension SoundManager {
    /// Available sound names for notifications (must be in bundle)
    static let availableSounds = [
        "default",
        "beep",
        "chime",
        "bell"
    ]
    
    /// Get UNNotificationSound for a sound name
    static func notificationSound(for name: String) -> UNNotificationSound {
        if name == "default" {
            return .default
        }
        return UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(name).wav"))
    }
}
