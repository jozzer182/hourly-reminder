# Hourly Reminder - iOS

A simple and elegant iOS app that announces the time at regular intervals using Text-to-Speech. Perfect for staying aware of time without constantly checking your device.

## Features

- ⏰ **Customizable Reminders** - Set reminders at 15, 30, 45, or 60-minute intervals
- 🗣️ **Text-to-Speech** - Announces the time in your preferred language
- 🔔 **Smart Notifications** - Works even when the app is in the background with pre-recorded audio
- 🎵 **Audio Ducking** - Music automatically lowers while the time is announced, then resumes
- 🌙 **Theme Support** - Light and dark mode
- 🌍 **Localization** - English and Spanish support

## Requirements

- iOS 17.0+
- iPhone or iPad

## Installation

1. Clone this repository
2. Open `ios_app/Hourly Reminder/Hourly Reminder.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Build and run on your device

## How It Works

### When App is in Foreground
The app uses iOS Text-to-Speech (AVSpeechSynthesizer) to announce the current time with your configured settings.

### When App is in Background
Since iOS doesn't allow TTS in background, the app uses pre-recorded audio files as notification sounds:
- `:00` → "en punto"
- `:15` → "y quince"
- `:30` → "y media"
- `:45` → "y cuarenta y cinco"

## Project Structure

```
ios_app/
└── Hourly Reminder/
    └── Hourly Reminder/
        ├── Models/           # Data models (Alarm, Reminder, ReminderSet)
        ├── Views/            # SwiftUI views
        ├── Services/         # Core services
        │   ├── TTSManager.swift           # Text-to-Speech
        │   ├── NotificationManager.swift  # Local notifications
        │   ├── StorageManager.swift       # Data persistence
        │   ├── SoundManager.swift         # Audio playback
        │   ├── ThemeManager.swift         # Theme handling
        │   └── TimezoneObserver.swift     # Timezone changes
        ├── Resources/
        │   ├── Sounds/       # Pre-recorded audio files
        │   └── Localization/ # en.lproj, es.lproj
        └── Assets.xcassets/  # App icons and colors
```

## Privacy

This app:
- ✅ Works completely offline
- ✅ Does not collect any personal data
- ✅ Does not require internet connection
- ✅ Only uses local notifications

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for full details.

## License

MIT License - Feel free to use, modify, and distribute.

## Author

José Zarabanda
