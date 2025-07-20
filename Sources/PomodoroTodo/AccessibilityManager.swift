import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

/// Centralized manager for accessibility features and system settings detection
@MainActor
class AccessibilityManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether VoiceOver is currently enabled
    @Published var isVoiceOverEnabled: Bool = false
    
    /// Whether Dynamic Type is enabled and current size category
    @Published var contentSizeCategory: ContentSizeCategory = .medium
    
    /// Whether high contrast mode is enabled
    @Published var isHighContrastEnabled: Bool = false
    
    /// Whether reduce motion is enabled
    @Published var isReduceMotionEnabled: Bool = false
    
    /// Current accessibility configuration
    @Published var accessibilityConfig: AccessibilityConfig
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let hapticFeedback = HapticFeedbackManager()
    
    // MARK: - Initialization
    
    init() {
        // Initialize with current system settings
        #if canImport(UIKit)
        let voiceOverEnabled = UIAccessibility.isVoiceOverRunning
        let sizeCategory = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
        let highContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled || UIAccessibility.isInvertColorsEnabled
        let reduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        #else
        // macOS fallbacks
        let voiceOverEnabled = false
        let sizeCategory = ContentSizeCategory.medium
        let highContrastEnabled = false
        let reduceMotionEnabled = false
        #endif
        
        self.isVoiceOverEnabled = voiceOverEnabled
        self.contentSizeCategory = sizeCategory
        self.isHighContrastEnabled = highContrastEnabled
        self.isReduceMotionEnabled = reduceMotionEnabled
        
        self.accessibilityConfig = AccessibilityConfig(
            isVoiceOverEnabled: voiceOverEnabled,
            isDynamicTypeEnabled: sizeCategory != .medium,
            isHighContrastEnabled: highContrastEnabled,
            preferredContentSizeCategory: sizeCategory
        )
        
        setupAccessibilityObservers()
    }
    
    // MARK: - System Settings Detection
    
    /// Sets up observers for accessibility setting changes
    private func setupAccessibilityObservers() {
        #if canImport(UIKit)
        // VoiceOver status changes
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateVoiceOverStatus()
            }
            .store(in: &cancellables)
        
        // Dynamic Type changes
        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { [weak self] _ in
                self?.updateContentSizeCategory()
            }
            .store(in: &cancellables)
        
        // High contrast changes
        NotificationCenter.default.publisher(for: UIAccessibility.darkerSystemColorsStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateHighContrastStatus()
            }
            .store(in: &cancellables)
        
        // Reduce motion changes
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateReduceMotionStatus()
            }
            .store(in: &cancellables)
        #endif
    }
    
    private func updateVoiceOverStatus() {
        #if canImport(UIKit)
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        #endif
        updateAccessibilityConfig()
    }
    
    private func updateContentSizeCategory() {
        #if canImport(UIKit)
        contentSizeCategory = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
        #endif
        updateAccessibilityConfig()
    }
    
    private func updateHighContrastStatus() {
        #if canImport(UIKit)
        isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled || UIAccessibility.isInvertColorsEnabled
        #endif
        updateAccessibilityConfig()
    }
    
    private func updateReduceMotionStatus() {
        #if canImport(UIKit)
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        #endif
    }
    
    private func updateAccessibilityConfig() {
        accessibilityConfig = AccessibilityConfig(
            isVoiceOverEnabled: isVoiceOverEnabled,
            isDynamicTypeEnabled: contentSizeCategory != .medium,
            isHighContrastEnabled: isHighContrastEnabled,
            preferredContentSizeCategory: contentSizeCategory
        )
    }
    
    // MARK: - VoiceOver Label Management
    
    /// Generates accessibility labels for timer states in Chinese
    func timerAccessibilityLabel(for state: TimerState, remainingTime: TimeInterval) -> String {
        switch state {
        case .idle:
            return "计时器已停止"
        case .working:
            let minutes = Int(remainingTime) / 60
            let seconds = Int(remainingTime) % 60
            return "工作时间，剩余 \(minutes) 分 \(seconds) 秒"
        case .onBreak:
            let minutes = Int(remainingTime) / 60
            let seconds = Int(remainingTime) % 60
            return "休息时间，剩余 \(minutes) 分 \(seconds) 秒"
        case .paused:
            return "计时器已暂停"
        }
    }
    
    /// Generates accessibility labels for todo items in Chinese
    func todoAccessibilityLabel(for item: TodoItem) -> String {
        let priorityText = switch item.priority {
        case .high: "高优先级"
        case .medium: "中优先级"
        case .low: "低优先级"
        }
        
        let statusText = item.isCompleted ? "已完成" : "未完成"
        return "\(priorityText)任务：\(item.title)，\(statusText)"
    }
    
    /// Generates accessibility hint for interactive elements
    func accessibilityHint(for action: AccessibilityAction) -> String {
        switch action {
        case .startTimer:
            return "双击开始计时器"
        case .pauseTimer:
            return "双击暂停计时器"
        case .stopTimer:
            return "双击停止计时器"
        case .completeTodo:
            return "双击标记任务完成"
        case .editTodo:
            return "双击编辑任务"
        case .deleteTodo:
            return "双击删除任务"
        }
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
    
    // MARK: - Dynamic Type Scaling Calculations
    
    /// Calculates scaled spacing based on Dynamic Type settings
    func scaledSpacing(baseSpacing: CGFloat) -> CGFloat {
        let scaleFactor = dynamicTypeScaleFactor()
        return baseSpacing * scaleFactor
    }
    
    /// Calculates scaled font size for custom fonts
    func scaledFontSize(baseSize: CGFloat) -> CGFloat {
        let scaleFactor = dynamicTypeScaleFactor()
        return baseSize * scaleFactor
    }
    
    /// Returns the scale factor based on current Dynamic Type setting
    private func dynamicTypeScaleFactor() -> CGFloat {
        switch contentSizeCategory {
        case .extraSmall:
            return 0.8
        case .small:
            return 0.9
        case .medium:
            return 1.0
        case .large:
            return 1.1
        case .extraLarge:
            return 1.2
        case .extraExtraLarge:
            return 1.3
        case .extraExtraExtraLarge:
            return 1.4
        case .accessibilityMedium:
            return 1.6
        case .accessibilityLarge:
            return 1.8
        case .accessibilityExtraLarge:
            return 2.0
        case .accessibilityExtraExtraLarge:
            return 2.2
        case .accessibilityExtraExtraExtraLarge:
            return 2.4
        @unknown default:
            return 1.0
        }
    }
    
    /// Calculates minimum touch target size based on accessibility guidelines
    func minimumTouchTargetSize() -> CGFloat {
        // Apple recommends 44pt minimum, but increase for larger Dynamic Type
        let baseSize: CGFloat = 44
        let scaleFactor = dynamicTypeScaleFactor()
        return max(baseSize, baseSize * scaleFactor)
    }
    
    // MARK: - Enhanced Timer Display Support
    
    /// Returns a scaled monospaced font for timer display with proper Dynamic Type support
    func scaledTimerFont() -> Font {
        let baseSize: CGFloat = 48
        let scaledSize = scaledFontSize(baseSize: baseSize)
        
        // Ensure minimum readability while maintaining monospace alignment
        let clampedSize = max(24, min(scaledSize, 72))
        
        return Font.system(size: clampedSize, weight: .bold, design: .monospaced)
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
        let baseKerning: CGFloat = 0.5
        let scaleFactor = dynamicTypeScaleFactor()
        
        // Scale kerning proportionally but keep it subtle
        return baseKerning * min(scaleFactor, 1.5)
    }
    
    /// Announces time updates for VoiceOver users at appropriate intervals
    func announceTimeUpdateIfNeeded(timeRemaining: Int, isBreakTime: Bool, lastAnnouncedTime: inout Int) {
        guard isVoiceOverEnabled else { return }
        
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        let totalSeconds = timeRemaining
        
        // Announce at specific intervals to avoid overwhelming the user
        let shouldAnnounce: Bool = {
            // Announce every minute for the first 5 minutes
            if totalSeconds <= 300 && totalSeconds % 60 == 0 && totalSeconds != lastAnnouncedTime {
                return true
            }
            // Announce every 5 minutes for longer periods
            if totalSeconds > 300 && totalSeconds % 300 == 0 && totalSeconds != lastAnnouncedTime {
                return true
            }
            // Announce final countdown (last 10 seconds)
            if totalSeconds <= 10 && totalSeconds != lastAnnouncedTime {
                return true
            }
            return false
        }()
        
        if shouldAnnounce {
            let stateText = isBreakTime ? "休息时间" : "工作时间"
            let timeText: String
            
            if totalSeconds <= 10 {
                timeText = "\(totalSeconds) 秒"
            } else if minutes > 0 {
                timeText = seconds > 0 ? "\(minutes) 分 \(seconds) 秒" : "\(minutes) 分"
            } else {
                timeText = "\(seconds) 秒"
            }
            
            let announcement = "\(stateText)剩余 \(timeText)"
            announceStateChange(announcement)
            lastAnnouncedTime = timeRemaining
        }
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