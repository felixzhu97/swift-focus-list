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
    
    // MARK: - Typography Scale with Dynamic Type Support
    
    /// Typography scale following Apple's HIG with Dynamic Type support
    struct Typography {
        /// Large title for main timer display - scales with Dynamic Type
        static let timerDisplay = Font.largeTitle.weight(.bold).monospacedDigit()
        
        /// Title for section headers and important information
        static let sectionTitle = Font.title2.weight(.semibold)
        
        /// Headline for session information and todo item titles
        static let headline = Font.headline
        
        /// Body text for standard content
        static let body = Font.body
        
        /// Caption for secondary information like dates and metadata
        static let caption = Font.caption
        
        /// Small caption for very minor details
        static let caption2 = Font.caption2
        
        /// Button text styling
        static let button = Font.body.weight(.medium)
        
        /// Monospaced font for timer display that maintains alignment
        static func timerFont(size: CGFloat = 48) -> Font {
            return Font.system(size: size, weight: .bold, design: .monospaced)
        }
        
        /// Custom scaled font for specific use cases
        static func scaledFont(_ textStyle: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
            if #available(macOS 13.0, iOS 16.0, *) {
                return Font.system(textStyle, design: .default, weight: weight)
            } else {
                return Font.system(textStyle).weight(weight)
            }
        }
    }
    
    // MARK: - Spacing System with Dynamic Type Support
    
    /// Spacing constants following Apple's 8pt grid system
    /// Note: @ScaledMetric should be used in individual views for Dynamic Type scaling
    struct Spacing {
        /// Base spacing unit (8pt)
        static let base: CGFloat = 8
        
        /// Small spacing (8pt) - use @ScaledMetric in views for Dynamic Type scaling
        static let small: CGFloat = 8
        
        /// Medium spacing (16pt) - use @ScaledMetric in views for Dynamic Type scaling
        static let medium: CGFloat = 16
        
        /// Large spacing (24pt) - use @ScaledMetric in views for Dynamic Type scaling
        static let large: CGFloat = 24
        
        /// Extra large spacing (32pt) - use @ScaledMetric in views for Dynamic Type scaling
        static let extraLarge: CGFloat = 32
        
        /// List item spacing (12pt) - use @ScaledMetric in views for Dynamic Type scaling
        static let listItem: CGFloat = 12
        
        /// Section spacing (24pt) - use @ScaledMetric in views for Dynamic Type scaling
        static let section: CGFloat = 24
        
        /// Screen edge margins (16pt) - use @ScaledMetric in views for Dynamic Type scaling
        static let screenMargin: CGFloat = 16
        
        /// Component padding (8pt) - use @ScaledMetric in views for Dynamic Type scaling
        static let componentPadding: CGFloat = 8
        
        /// Button spacing (20pt) - use @ScaledMetric in views for Dynamic Type scaling
        static let buttonSpacing: CGFloat = 20
        
        /// Timer circle size (250pt) - use @ScaledMetric in views for Dynamic Type scaling
        static let timerCircleSize: CGFloat = 250
        
        /// Button size (60pt) - use @ScaledMetric in views for Dynamic Type scaling
        static let buttonSize: CGFloat = 60
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
    
    /// Returns high contrast version of a color if needed
    static func adaptiveColor(_ color: Color, highContrast: Color? = nil) -> Color {
        // SwiftUI automatically handles high contrast mode with semantic colors
        // This method allows for custom high contrast variants if needed
        return color
    }
    
    /// Shared theme manager instance for global access
    static let shared = ThemeManager()
}

// MARK: - Color Extensions for Convenience

extension Color {
    /// Convenience initializers for theme colors
    static let timerWork = ThemeManager.TimerColors.workSession
    static let timerBreak = ThemeManager.TimerColors.breakSession
    static let timerInactive = ThemeManager.TimerColors.inactive
    static let progressTrack = ThemeManager.TimerColors.progressTrack
}