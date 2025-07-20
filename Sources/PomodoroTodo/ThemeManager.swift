import SwiftUI
import Foundation

/// ThemeManager handles theme state and accessibility preferences
/// Design tokens are now separated into DesignTokens for better organization
final class ThemeManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published var isHighContrastEnabled: Bool = false
    @Published var preferredColorScheme: ColorScheme?
    
    // MARK: - Initialization
    
    init() {
        updateThemeState()
        observeSystemChanges()
    }
    
    // MARK: - Theme State Management
    
    /// Updates theme state based on system settings
    private func updateThemeState() {
        #if os(iOS)
        if #available(iOS 13.0, *) {
            isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        }
        #elseif os(macOS)
        if #available(macOS 10.14, *) {
            isHighContrastEnabled = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        }
        #endif
    }
    
    /// Observes system theme changes
    private func observeSystemChanges() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemAccessibilityChanged),
            name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil
        )
        #endif
    }
    
    #if os(iOS)
    @objc private func systemAccessibilityChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateThemeState()
        }
    }
    #endif
    
    // MARK: - Accessibility Support
    
    /// Returns high contrast timer text color meeting WCAG AA standards
    func timerTextColor() -> Color {
        if isHighContrastEnabled {
            #if os(iOS)
            return Color(UIColor.label)
            #else
            return Color.primary
            #endif
        }
        return DesignTokens.TextColors.primary
    }
    
    /// Returns adaptive color based on current theme state
    func adaptiveColor(_ color: Color, highContrast: Color? = nil) -> Color {
        if isHighContrastEnabled, let highContrastColor = highContrast {
            return highContrastColor
        }
        return color
    }
    
    // MARK: - Shared Instance
    
    static let shared = ThemeManager()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Color Extensions for Convenience

extension Color {
    /// Convenience initializers for theme colors
    static let timerWork = DesignTokens.TimerColors.workSession
    static let timerBreak = DesignTokens.TimerColors.breakSession
    static let timerInactive = DesignTokens.TimerColors.inactive
    static let progressTrack = DesignTokens.TimerColors.progressTrack
}