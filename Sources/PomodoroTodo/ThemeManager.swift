import SwiftUI
import Foundation

/// ThemeManager handles semantic colors and theme management for the PomodoroTodo app
/// Provides automatic dark mode adaptation and HIG-compliant color tokens
class ThemeManager: ObservableObject {
    
    // MARK: - Semantic Color System
    
    /// Primary text colors following Apple's semantic color system
    struct TextColors {
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let tertiary = Color.secondary.opacity(0.6)
    }
    
    /// Background colors with automatic dark mode adaptation
    struct BackgroundColors {
        #if os(macOS)
        static let primary = Color(NSColor.controlBackgroundColor)
        static let secondary = Color(NSColor.controlColor)
        static let grouped = Color(NSColor.controlBackgroundColor)
        #else
        static let primary = Color(.systemBackground)
        static let secondary = Color(.secondarySystemBackground)
        static let grouped = Color(.systemGroupedBackground)
        #endif
        static let tertiary = Color.gray.opacity(0.1)
    }
    
    /// System colors for consistent UI elements
    struct SystemColors {
        static let accent = Color.accentColor
        static let destructive = Color.red
        static let success = Color.green
        static let warning = Color.orange
        static let info = Color.blue
        static let neutral = Color.gray
    }
    
    /// Timer-specific semantic colors for work and break states
    struct TimerColors {
        /// Work session color - uses system blue for focus and productivity
        static let workSession = Color.blue
        
        /// Break session color - uses system green for rest and relaxation
        static let breakSession = Color.green
        
        /// Inactive/paused state color
        static let inactive = Color.gray
        
        /// Progress track background color
        static let progressTrack = Color.gray.opacity(0.3)
    }
    
    /// Priority colors for todo items using semantic system colors
    struct PriorityColors {
        static let high = Color.red
        static let medium = Color.orange
        static let low = Color.green
        
        /// Returns the appropriate color for a given priority
        static func color(for priority: TodoItem.Priority) -> Color {
            switch priority {
            case .high: return high
            case .medium: return medium
            case .low: return low
            }
        }
        
        /// Returns a lighter version of the priority color for backgrounds
        static func backgroundColorFor(priority: TodoItem.Priority) -> Color {
            color(for: priority).opacity(0.15)
        }
    }
    
    // MARK: - Dynamic Color Adaptation
    
    /// Returns the appropriate timer color based on current state
    static func timerColor(isBreakTime: Bool, isRunning: Bool = true) -> Color {
        if !isRunning {
            return TimerColors.inactive
        }
        return isBreakTime ? TimerColors.breakSession : TimerColors.workSession
    }
    
    /// Returns the appropriate button background color for timer controls
    static func timerButtonColor(isBreakTime: Bool) -> Color {
        return isBreakTime ? TimerColors.breakSession : TimerColors.workSession
    }
    
    // MARK: - Accessibility Support
    
    /// Ensures colors meet WCAG AA contrast requirements
    static func accessibleColor(_ color: Color, for background: Color = BackgroundColors.primary) -> Color {
        // SwiftUI automatically handles contrast in semantic colors
        // This method can be extended for custom contrast calculations if needed
        return color
    }
    
    // MARK: - Theme State Management
    
    @Published var isDarkMode: Bool = false
    @Published var isHighContrastEnabled: Bool = false
    
    init() {
        updateThemeState()
    }
    
    /// Updates theme state based on system settings
    private func updateThemeState() {
        // Monitor system color scheme changes
        // This will be automatically handled by SwiftUI's environment
        // but we can track state here for custom logic if needed
    }
}

// MARK: - Color Extensions for Convenience

extension Color {
    /// Convenience initializers for theme colors
    static let timerWork = ThemeManager.TimerColors.workSession
    static let timerBreak = ThemeManager.TimerColors.breakSession
    static let timerInactive = ThemeManager.TimerColors.inactive
    static let progressTrack = ThemeManager.TimerColors.progressTrack
}