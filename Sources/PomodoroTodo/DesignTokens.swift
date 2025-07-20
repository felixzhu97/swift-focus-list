import SwiftUI
import Foundation

/// Design tokens for consistent styling across the app
/// Separated from ThemeManager for better organization
enum DesignTokens {
    
    // MARK: - Color System
    
    /// Primary text colors following Apple's semantic color system
    enum TextColors {
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let tertiary = Color.secondary.opacity(0.6)
    }
    
    /// Background colors with automatic dark mode adaptation
    enum BackgroundColors {
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
    enum SystemColors {
        static let accent = Color.accentColor
        static let destructive = Color.red
        static let success = Color.green
        static let warning = Color.orange
        static let info = Color.blue
        static let neutral = Color.gray
    }
    
    /// Timer-specific semantic colors for work and break states
    enum TimerColors {
        static let workSession = Color.blue
        static let breakSession = Color.green
        static let inactive = Color.gray
        static let progressTrack = Color.gray.opacity(0.3)
        
        /// Returns the appropriate timer color based on current state
        static func color(isBreakTime: Bool, isRunning: Bool = true) -> Color {
            guard isRunning else { return inactive }
            return isBreakTime ? breakSession : workSession
        }
    }
    
    /// Priority colors for todo items using semantic system colors
    enum PriorityColors {
        static let high = Color.red
        static let medium = Color.orange
        static let low = Color.green
        
        static func color(for priority: TodoItem.Priority) -> Color {
            switch priority {
            case .high: return high
            case .medium: return medium
            case .low: return low
            }
        }
        
        static func backgroundColor(for priority: TodoItem.Priority) -> Color {
            color(for: priority).opacity(0.15)
        }
    }
    
    // MARK: - Typography System
    
    /// Typography scale following Apple's HIG with Dynamic Type support
    enum Typography {
        static let timerDisplay = Font.largeTitle.weight(.bold).monospacedDigit()
        static let sectionTitle = Font.title2.weight(.semibold)
        static let headline = Font.headline
        static let body = Font.body
        static let caption = Font.caption
        static let caption2 = Font.caption2
        static let button = Font.body.weight(.medium)
        
        static func timerFont(size: CGFloat = 48) -> Font {
            Font.system(size: size, weight: .bold, design: .monospaced)
                .monospacedDigit()
        }
        
        static func scaledFont(_ textStyle: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
            if #available(macOS 13.0, iOS 16.0, *) {
                return Font.system(textStyle, design: .default, weight: weight)
            } else {
                return Font.system(textStyle).weight(weight)
            }
        }
        
        /// Calculates optimal kerning for monospaced timer display
        static func timerKerning(for fontSize: CGFloat) -> CGFloat {
            fontSize * 0.01 // 1% of font size for subtle improvement
        }
    }
    
    // MARK: - Spacing System
    
    /// Spacing constants following Apple's 8pt grid system
    enum Spacing {
        static let base: CGFloat = 8
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
        static let listItem: CGFloat = 12
        static let section: CGFloat = 24
        static let screenMargin: CGFloat = 16
        static let componentPadding: CGFloat = 8
        static let buttonSpacing: CGFloat = 16
        static let timerCircleSize: CGFloat = 250
        static let buttonSize: CGFloat = 60
    }
}