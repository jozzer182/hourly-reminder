//
//  ThemeManager.swift
//  Hourly Reminder
//
//  Manages app theme (light/dark/system)
//

import SwiftUI
import Combine

/// Available theme options
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return NSLocalizedString("System", comment: "Follow system theme")
        case .light: return NSLocalizedString("Light", comment: "Light theme")
        case .dark: return NSLocalizedString("Dark", comment: "Dark theme")
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Manages the app's visual theme
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("app_theme") private var storedTheme: String = AppTheme.system.rawValue
    
    @Published var currentTheme: AppTheme = .system
    
    private init() {
        if let theme = AppTheme(rawValue: storedTheme) {
            currentTheme = theme
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        storedTheme = theme.rawValue
    }
    
    var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }
}

/// View modifier to apply the current theme
struct ThemeModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
    }
}

extension View {
    func applyTheme() -> some View {
        modifier(ThemeModifier())
    }
}

/// Theme picker for settings
struct ThemePickerView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        Picker(NSLocalizedString("Theme", comment: ""), selection: $themeManager.currentTheme) {
            ForEach(AppTheme.allCases) { theme in
                Text(theme.displayName).tag(theme)
            }
        }
        .onChange(of: themeManager.currentTheme) { _, newTheme in
            themeManager.setTheme(newTheme)
        }
    }
}
