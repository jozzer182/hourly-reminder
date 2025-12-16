//
//  TTSManager.swift
//  Hourly Reminder
//
//  Text-to-Speech manager for announcing the time
//  iOS equivalent of Android's TTS.java
//

import Foundation
import AVFoundation
import Combine

/// Speech format options
enum SpeechFormat: String, CaseIterable, Identifiable {
    case full = "full"          // "10:30 AM" or "10 o'clock AM"
    case hourOnly = "hour"      // "10" or "10 o'clock"
    case minutesOnly = "minutes" // "30" or "thirty minutes"
    case custom = "custom"      // User-defined template
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .full: return NSLocalizedString("Full Time", comment: "Full time speech")
        case .hourOnly: return NSLocalizedString("Hour Only", comment: "Hour only speech")
        case .minutesOnly: return NSLocalizedString("Minutes Only", comment: "Minutes only speech")
        case .custom: return NSLocalizedString("Custom", comment: "Custom format")
        }
    }
    
    var description: String {
        switch self {
        case .full: return "10:30 AM → \"Ten thirty AM\""
        case .hourOnly: return "10:30 AM → \"Ten o'clock\""
        case .minutesOnly: return "10:30 AM → \"Thirty minutes\""
        case .custom: return "Use %H, %M, %A placeholders"
        }
    }
}

/// Manages text-to-speech for time announcements
class TTSManager: ObservableObject {
    static let shared = TTSManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    // User preferences
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "tts_enabled") }
    }
    @Published var speakAmPm: Bool {
        didSet { UserDefaults.standard.set(speakAmPm, forKey: "tts_speak_ampm") }
    }
    @Published var speechFormat: SpeechFormat {
        didSet { UserDefaults.standard.set(speechFormat.rawValue, forKey: "tts_format") }
    }
    @Published var customTemplate: String {
        didSet { UserDefaults.standard.set(customTemplate, forKey: "tts_custom_template") }
    }
    @Published var volume: Float = 1.0
    @Published var rate: Float = 0.5  // 0.0 to 1.0
    
    // Language settings
    @Published var voiceIdentifier: String? = nil  // nil = default system voice
    
    private init() {
        // Load saved preferences
        self.isEnabled = UserDefaults.standard.bool(forKey: "tts_enabled")
        self.speakAmPm = UserDefaults.standard.bool(forKey: "tts_speak_ampm")
        
        if let formatRaw = UserDefaults.standard.string(forKey: "tts_format"),
           let format = SpeechFormat(rawValue: formatRaw) {
            self.speechFormat = format
        } else {
            self.speechFormat = .full
        }
        
        self.customTemplate = UserDefaults.standard.string(forKey: "tts_custom_template") ?? "%M minutes"
        
        // Default to enabled if never set
        if !UserDefaults.standard.bool(forKey: "tts_initialized") {
            UserDefaults.standard.set(true, forKey: "tts_initialized")
            self.isEnabled = true
            self.speakAmPm = true
        }
    }
    
    // MARK: - Speak Time
    
    /// Speak the current time
    func speakCurrentTime() {
        let now = Date()
        speakTime(date: now)
    }
    
    /// Speak a specific time
    func speakTime(date: Date) {
        guard isEnabled else { return }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        let text = formatTimeForSpeech(hour: hour, minute: minute)
        speak(text)
    }
    
    /// Preview how a time will sound (called from Settings)
    func previewTime(hour: Int = 10, minute: Int = 30) {
        let text = formatTimeForSpeech(hour: hour, minute: minute)
        speakForce(text)
    }
    
    /// Get preview text without speaking
    func getPreviewText(hour: Int = 10, minute: Int = 30) -> String {
        return formatTimeForSpeech(hour: hour, minute: minute)
    }
    
    /// Speak custom text
    func speak(_ text: String) {
        guard isEnabled else { return }
        speakForce(text)
    }
    
    /// Force speak (ignores isEnabled - used for preview)
    func speakForce(_ text: String) {
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Configure audio session to duck other audio (lower volume temporarily)
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .voicePrompt,
                options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Set voice
        if let voiceId = voiceIdentifier {
            utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId)
        } else {
            // Use default voice for current locale
            let langCode = Locale.current.language.languageCode?.identifier ?? "en"
            utterance.voice = AVSpeechSynthesisVoice(language: langCode)
        }
        
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rate
        utterance.volume = volume
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
        
        // Restore audio session after speech ends (with small delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if !self.synthesizer.isSpeaking {
                do {
                    try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                } catch {
                    print("Audio session deactivation error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Time Formatting
    
    /// Format time for speech based on current settings
    func formatTimeForSpeech(hour: Int, minute: Int) -> String {
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let amPm = hour < 12 ? "AM" : "PM"
        
        switch speechFormat {
        case .full:
            return formatFull(hour: displayHour, minute: minute, amPm: amPm)
        case .hourOnly:
            return formatHourOnly(hour: displayHour, amPm: amPm)
        case .minutesOnly:
            return formatMinutesOnly(minute: minute)
        case .custom:
            return formatCustom(hour: displayHour, minute: minute, amPm: amPm)
        }
    }
    
    private func formatFull(hour: Int, minute: Int, amPm: String) -> String {
        if minute == 0 {
            if speakAmPm {
                return "\(hour) o'clock \(amPm)"
            } else {
                return "\(hour) o'clock"
            }
        } else {
            let minuteText = formatMinuteText(minute)
            if speakAmPm {
                return "\(hour) \(minuteText) \(amPm)"
            } else {
                return "\(hour) \(minuteText)"
            }
        }
    }
    
    private func formatHourOnly(hour: Int, amPm: String) -> String {
        if speakAmPm {
            return "\(hour) o'clock \(amPm)"
        } else {
            return "\(hour) o'clock"
        }
    }
    
    private func formatMinutesOnly(minute: Int) -> String {
        if minute == 0 {
            return NSLocalizedString("zero minutes", comment: "Zero minutes")
        } else if minute == 1 {
            return NSLocalizedString("one minute", comment: "One minute")
        } else {
            return "\(formatMinuteText(minute)) minutes"
        }
    }
    
    private func formatCustom(hour: Int, minute: Int, amPm: String) -> String {
        var result = customTemplate
        
        // Replace placeholders
        result = result.replacingOccurrences(of: "%H", with: "\(hour)")
        result = result.replacingOccurrences(of: "%M", with: formatMinuteText(minute))
        result = result.replacingOccurrences(of: "%A", with: speakAmPm ? amPm : "")
        
        // Clean up extra spaces
        result = result.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
        
        return result
    }
    
    private func formatMinuteText(_ minute: Int) -> String {
        if minute < 10 {
            return "oh \(minute)"
        } else {
            return "\(minute)"
        }
    }
    
    // MARK: - Voice Management
    
    /// Get available voices
    static var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
    }
    
    /// Get voices for current locale
    static var localVoices: [AVSpeechSynthesisVoice] {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.hasPrefix(languageCode)
        }
    }
    
    /// Stop speaking
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    /// Check if currently speaking
    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }
}

