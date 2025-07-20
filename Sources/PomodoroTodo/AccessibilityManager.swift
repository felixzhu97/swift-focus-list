import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

/// Centralized coordinator for accessibility features
@MainActor
class AccessibilityManager: ObservableObject {
    
    // MARK: - Dependencies
    
    @Published private(set) var settingsManager = AccessibilitySettingsManager()
    private let hapticFeedback = HapticFeedbackManager()
    private let labelProvider = AccessibilityLabelProvider.self
    
    // MARK: - Convenience Properties
    
    var isVoiceOverEnabled: Bool { settingsManager.isVoiceOverEnabled }
    var contentSizeCategory: ContentSizeCategory { settingsManager.contentSizeCategory }
    var isHighContrastEnabled: Bool { settingsManager.isHighContrastEnabled }
    var isReduceMotionEnabled: Bool { settingsManager.isReduceMotionEnabled }
    
    var accessibilityConfig: AccessibilityConfig {
        AccessibilityConfig(
            isVoiceOverEnabled: isVoiceOverEnabled,
            isDynamicTypeEnabled: contentSizeCategory != .medium,
            isHighContrastEnabled: isHighContrastEnabled,
            preferredContentSizeCategory: contentSizeCategory
        )
    }
    
    // MARK: - Label Generation (Delegated)
    
    /// Generates accessibility labels for timer states
    func timerAccessibilityLabel(for state: TimerState, remainingTime: TimeInterval) -> String {
        labelProvider.timerLabel(for: state, remainingTime: remainingTime)
    }
    
    /// Generates accessibility labels for todo items
    func todoAccessibilityLabel(for item: TodoItem) -> String {
        labelProvider.todoLabel(for: item)
    }
    
    /// Generates accessibility hint for interactive elements
    func accessibilityHint(for action: AccessibilityAction) -> String {
        labelProvider.actionHint(for: action)
    }
    
    /// Posts accessibility announcements for important state changes
    func announceStateChange(_ message: String) {
        guard isVoiceOverEnabled else { return }
        
        #if canImport(UIKit)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
        #endif
    }
    
    // MARK: - Dynamic Type Scaling (Delegated)
    
    /// Calculates scaled spacing based on Dynamic Type settings
    func scaledSpacing(baseSpacing: CGFloat) -> CGFloat {
        DynamicTypeScalingService.scaledSpacing(baseSpacing: baseSpacing, contentSizeCategory: contentSizeCategory)
    }
    
    /// Calculates scaled font size for custom fonts
    func scaledFontSize(baseSize: CGFloat) -> CGFloat {
        DynamicTypeScalingService.scaledFontSize(baseSize: baseSize, contentSizeCategory: contentSizeCategory)
    }
    
    /// Calculates minimum touch target size based on accessibility guidelines
    func minimumTouchTargetSize() -> CGFloat {
        DynamicTypeScalingService.minimumTouchTargetSize(contentSizeCategory: contentSizeCategory)
    }
    
    // MARK: - Enhanced Timer Display Support
    
    /// Returns a scaled monospaced font for timer display with proper Dynamic Type support
    func scaledTimerFont() -> Font {
        DynamicTypeScalingService.scaledTimerFont(contentSizeCategory: contentSizeCategory)
    }
    
    /// Returns high contrast timer text color meeting WCAG AA standards
    func highContrastTimerTextColor() -> Color {
        if isHighContrastEnabled {
            // Use maximum contrast colors for high contrast mode
            #if canImport(UIKit)
            return Color(UIColor.label) // Automatically adapts to light/dark mode with maximum contrast
            #else
            return Color.primary // macOS fallback
            #endif
        } else {
            // Use semantic primary color which automatically provides good contrast
            return ThemeManager.TextColors.primary
        }
    }
    
    /// Returns scaled kerning for monospaced timer display to improve digit alignment
    func scaledKerning() -> CGFloat {
        DynamicTypeScalingService.scaledKerning(contentSizeCategory: contentSizeCategory)
    }
    
    /// Announces time updates for VoiceOver users at appropriate intervals
    func announceTimeUpdateIfNeeded(timeRemaining: Int, isBreakTime: Bool, lastAnnouncedTime: inout Int) {
        guard isVoiceOverEnabled else { return }
        
        if shouldAnnounceTime(timeRemaining: timeRemaining, lastAnnouncedTime: lastAnnouncedTime) {
            let announcement = labelProvider.timeAnnouncement(timeRemaining: timeRemaining, isBreakTime: isBreakTime)
            announceStateChange(announcement)
            lastAnnouncedTime = timeRemaining
        }
    }
    
    /// Determines if time should be announced based on interval rules
    private func shouldAnnounceTime(timeRemaining: Int, lastAnnouncedTime: Int) -> Bool {
        guard timeRemaining != lastAnnouncedTime else { return false }
        
        // Announce every minute for the first 5 minutes
        if timeRemaining <= 300 && timeRemaining % 60 == 0 {
            return true
        }
        
        // Announce every 5 minutes for longer periods
        if timeRemaining > 300 && timeRemaining % 300 == 0 {
            return true
        }
        
        // Announce final countdown (last 10 seconds)
        if timeRemaining <= 10 {
            return true
        }
        
        return false
    }
    
    // MARK: - Haptic Feedback Coordination
    
    /// Triggers haptic feedback for various user interactions
    func triggerHapticFeedback(for type: HapticFeedbackType) {
        hapticFeedback.trigger(type)
    }
}

// MARK: - Supporting Types

/// Configuration struct for accessibility settings
struct AccessibilityConfig {
    var isVoiceOverEnabled: Bool
    var isDynamicTypeEnabled: Bool
    var isHighContrastEnabled: Bool
    var preferredContentSizeCategory: ContentSizeCategory
}

/// Timer states for accessibility labeling
enum TimerState {
    case idle
    case working
    case onBreak
    case paused
    
    /// Creates a timer state from PomodoroTimer properties
    static func from(isRunning: Bool, isBreakTime: Bool, timeRemaining: TimeInterval) -> TimerState {
        if !isRunning && timeRemaining > 0 {
            return .paused
        } else if timeRemaining <= 0 {
            return .idle
        } else if isBreakTime {
            return .onBreak
        } else {
            return .working
        }
    }
}

/// Accessibility actions for hint generation
enum AccessibilityAction {
    case startTimer
    case pauseTimer
    case stopTimer
    case completeTodo
    case editTodo
    case deleteTodo
}

/// Types of haptic feedback
enum HapticFeedbackType {
    case buttonTap
    case timerStart
    case timerComplete
    case todoComplete
    case error
    case success
}

/// Manages haptic feedback generation
class HapticFeedbackManager {
    
    #if canImport(UIKit)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    #endif
    
    init() {
        #if canImport(UIKit)
        // Prepare generators for better performance
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notificationFeedback.prepare()
        #endif
    }
    
    func trigger(_ type: HapticFeedbackType) {
        #if canImport(UIKit)
        // Respect system haptic settings
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        
        switch type {
        case .buttonTap:
            lightImpact.impactOccurred()
        case .timerStart:
            mediumImpact.impactOccurred()
        case .timerComplete:
            notificationFeedback.notificationOccurred(.success)
        case .todoComplete:
            notificationFeedback.notificationOccurred(.success)
        case .error:
            notificationFeedback.notificationOccurred(.error)
        case .success:
            notificationFeedback.notificationOccurred(.success)
        }
        #endif
    }
}

// MARK: - ContentSizeCategory Extension

#if canImport(UIKit)
extension ContentSizeCategory {
    init(_ uiContentSizeCategory: UIContentSizeCategory) {
        switch uiContentSizeCategory {
        case .extraSmall:
            self = .extraSmall
        case .small:
            self = .small
        case .medium:
            self = .medium
        case .large:
            self = .large
        case .extraLarge:
            self = .extraLarge
        case .extraExtraLarge:
            self = .extraExtraLarge
        case .extraExtraExtraLarge:
            self = .extraExtraExtraLarge
        case .accessibilityMedium:
            self = .accessibilityMedium
        case .accessibilityLarge:
            self = .accessibilityLarge
        case .accessibilityExtraLarge:
            self = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge:
            self = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge:
            self = .accessibilityExtraExtraExtraLarge
        default:
            self = .medium
        }
    }
}
#endif