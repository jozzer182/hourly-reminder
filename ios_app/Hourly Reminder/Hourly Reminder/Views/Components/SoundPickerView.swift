//
//  SoundPickerView.swift
//  Hourly Reminder
//
//  Sound selection picker for alarms and reminders
//

import SwiftUI
import AVFoundation

/// Available sound types
enum SoundType: String, CaseIterable, Identifiable {
    case none = "none"
    case beep = "beep"
    case chime = "chime"
    case bell = "bell"
    case digital = "digital"
    case classic = "classic"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return NSLocalizedString("Off", comment: "No sound")
        case .beep: return NSLocalizedString("Beep", comment: "Beep sound")
        case .chime: return NSLocalizedString("Chime", comment: "Chime sound")
        case .bell: return NSLocalizedString("Bell", comment: "Bell sound")
        case .digital: return NSLocalizedString("Digital", comment: "Digital sound")
        case .classic: return NSLocalizedString("Classic", comment: "Classic alarm sound")
        }
    }
    
    var systemSoundID: SystemSoundID {
        switch self {
        case .none: return 0
        case .beep: return 1052
        case .chime: return 1005
        case .bell: return 1013
        case .digital: return 1007
        case .classic: return 1016
        }
    }
}

/// Sound picker view for selecting alarm/reminder sounds
struct SoundPickerView: View {
    @Binding var selectedSound: String?
    @Environment(\.dismiss) var dismiss
    
    @State private var currentlyPlaying: SoundType?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(SoundType.allCases) { sound in
                    HStack {
                        Text(sound.displayName)
                        
                        Spacer()
                        
                        if selectedSound == sound.rawValue || (selectedSound == nil && sound == .beep) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                        
                        // Play button
                        if sound != .none {
                            Button {
                                playPreview(sound)
                            } label: {
                                Image(systemName: currentlyPlaying == sound ? "stop.circle.fill" : "play.circle")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSound = sound.rawValue
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Select Sound", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("Done", comment: "")) {
                        stopPreview()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                stopPreview()
            }
        }
    }
    
    private func playPreview(_ sound: SoundType) {
        if currentlyPlaying == sound {
            stopPreview()
        } else {
            stopPreview()
            currentlyPlaying = sound
            AudioServicesPlaySystemSound(sound.systemSoundID)
        }
    }
    
    private func stopPreview() {
        currentlyPlaying = nil
    }
}

/// Compact sound selector button
struct SoundSelectorButton: View {
    @Binding var selectedSound: String?
    @State private var showingPicker = false
    
    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack {
                Text(NSLocalizedString("Sound", comment: ""))
                Spacer()
                Text(displayName)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            SoundPickerView(selectedSound: $selectedSound)
        }
    }
    
    private var displayName: String {
        guard let soundId = selectedSound,
              let sound = SoundType(rawValue: soundId) else {
            return SoundType.beep.displayName
        }
        return sound.displayName
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var sound: String? = "beep"
        
        var body: some View {
            SoundPickerView(selectedSound: $sound)
        }
    }
    
    return PreviewWrapper()
}
