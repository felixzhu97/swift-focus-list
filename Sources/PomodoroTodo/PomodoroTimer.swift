import SwiftUI
import Foundation

class PomodoroTimer: ObservableObject {
    @Published var timeRemaining: Int = 25 * 60 // 25分钟
    @Published var isRunning = false
    @Published var currentSession = 1
    @Published var isBreakTime = false
    
    private var timer: Timer?
    private let workDuration = 25 * 60 // 25分钟工作
    private let shortBreakDuration = 5 * 60 // 5分钟短休息
    private let longBreakDuration = 15 * 60 // 15分钟长休息
    
    // Accessibility manager for announcements - using weak to prevent retain cycles
    weak var accessibilityManager: AccessibilityManager?
    
    // MARK: - Initialization
    
    init(accessibilityManager: AccessibilityManager? = nil) {
        self.accessibilityManager = accessibilityManager
    }
    
    /// Sets the accessibility manager for announcements and haptic feedback
    func setAccessibilityManager(_ manager: AccessibilityManager) {
        self.accessibilityManager = manager
    }
    
    // MARK: - Lifecycle
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        let totalTime = isBreakTime ? 
            (currentSession % 4 == 0 ? longBreakDuration : shortBreakDuration) : 
            workDuration
        return 1.0 - Double(timeRemaining) / Double(totalTime)
    }
    
    func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.completeSession()
            }
        }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func resetTimer() {
        pauseTimer()
        if isBreakTime {
            timeRemaining = currentSession % 4 == 0 ? longBreakDuration : shortBreakDuration
        } else {
            timeRemaining = workDuration
        }
    }
    
    private func completeSession() {
        pauseTimer()
        
        // Trigger completion haptic feedback on main actor
        Task { @MainActor in
            accessibilityManager?.triggerHapticFeedback(for: .timerComplete)
        }
        
        if isBreakTime {
            // 休息结束，开始工作
            isBreakTime = false
            timeRemaining = workDuration
            currentSession += 1
            
            // Announce break completion and new work session
            let sessionText = "休息结束，开始第 \(currentSession) 个工作番茄"
            Task { @MainActor in
                accessibilityManager?.announceStateChange(sessionText)
            }
        } else {
            // 工作结束，开始休息
            isBreakTime = true
            let isLongBreak = currentSession % 4 == 0
            timeRemaining = isLongBreak ? longBreakDuration : shortBreakDuration
            
            // Announce work completion and break type
            let breakType = isLongBreak ? "长休息" : "短休息"
            let sessionText = "第 \(currentSession) 个工作番茄完成，开始 \(breakType)"
            Task { @MainActor in
                accessibilityManager?.announceStateChange(sessionText)
            }
        }
    }
}