import SwiftUI
import Foundation
import UserNotifications

#if canImport(UIKit)
import UIKit
#endif

@MainActor
class PomodoroTimer: ObservableObject {
    @Published var timeRemaining: Int = 25 * 60 // 25分钟
    @Published var isRunning = false
    @Published var currentSession = 1
    @Published var isBreakTime = false
    
    private var timer: Timer?
    private let workDuration = 25 * 60 // 25分钟工作
    private let shortBreakDuration = 5 * 60 // 5分钟短休息
    private let longBreakDuration = 15 * 60 // 15分钟长休息
    
    // Background task management
    #if canImport(UIKit)
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    #endif
    
    // State persistence for background/foreground transitions
    private var backgroundStartTime: Date?
    private var wasRunningWhenBackgrounded = false
    
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
    
    private func invalidateTimer() {
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
        guard !isRunning else { return }
        
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.tick()
            }
        }
    }
    
    func pauseTimer() {
        isRunning = false
        invalidateTimer()
    }
    
    func resetTimer() {
        pauseTimer()
        timeRemaining = isBreakTime ? 
            (currentSession % 4 == 0 ? longBreakDuration : shortBreakDuration) : 
            workDuration
    }
    
    private func tick() async {
        guard isRunning else { return }
        
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            await completeSession()
        }
    }
    
    private func completeSession() async {
        pauseTimer()
        
        // Trigger completion haptic feedback
        accessibilityManager?.triggerHapticFeedback(for: .timerComplete)
        
        // Send completion notification if app is in background
        await sendTimerCompletionNotification()
        
        if isBreakTime {
            // 休息结束，开始工作
            isBreakTime = false
            timeRemaining = workDuration
            currentSession += 1
            
            // Announce break completion and new work session
            let sessionText = "休息结束，开始第 \(currentSession) 个工作番茄"
            accessibilityManager?.announceStateChange(sessionText)
        } else {
            // 工作结束，开始休息
            isBreakTime = true
            let isLongBreak = currentSession % 4 == 0
            timeRemaining = isLongBreak ? longBreakDuration : shortBreakDuration
            
            // Announce work completion and break type
            let breakType = isLongBreak ? "长休息" : "短休息"
            let sessionText = "第 \(currentSession) 个工作番茄完成，开始 \(breakType)"
            accessibilityManager?.announceStateChange(sessionText)
        }
    }
    
    // MARK: - Background Task Management
    
    /// Called when app enters background - starts background task and saves state
    func handleAppDidEnterBackground() {
        guard isRunning else { return }
        
        wasRunningWhenBackgrounded = true
        backgroundStartTime = Date()
        saveTimerState()
        startBackgroundTask()
    }
    
    /// Called when app enters foreground - restores state and calculates elapsed time
    func handleAppWillEnterForeground() {
        endBackgroundTask()
        
        guard wasRunningWhenBackgrounded,
              let backgroundStart = backgroundStartTime else {
            return
        }
        
        let elapsedTime = Int(Date().timeIntervalSince(backgroundStart))
        restoreTimerState(elapsedTime: elapsedTime)
        
        // Reset background state
        wasRunningWhenBackgrounded = false
        backgroundStartTime = nil
    }
    
    /// Starts a background task to continue timer execution
    private func startBackgroundTask() {
        #if canImport(UIKit)
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "PomodoroTimer") { [weak self] in
            Task { @MainActor in
                await self?.handleBackgroundTaskExpiration()
            }
        }
        #endif
    }
    
    /// Ends the background task
    private func endBackgroundTask() {
        #if canImport(UIKit)
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        #endif
    }
    
    /// Handles background task expiration by saving state and scheduling notification
    private func handleBackgroundTaskExpiration() async {
        guard isRunning else { return }
        
        // Calculate remaining time and schedule notification
        await scheduleBackgroundExpirationNotification()
        
        // Save current state
        saveTimerState()
        
        // End background task
        endBackgroundTask()
    }
    
    // MARK: - State Persistence
    
    /// Saves current timer state to UserDefaults
    private func saveTimerState() {
        let state = PersistentTimerState(
            timeRemaining: timeRemaining,
            isRunning: isRunning,
            currentSession: currentSession,
            isBreakTime: isBreakTime,
            backgroundStartTime: backgroundStartTime
        )
        
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: "PomodoroTimerState")
        }
    }
    
    /// Restores timer state accounting for elapsed background time
    private func restoreTimerState(elapsedTime: Int) {
        guard let data = UserDefaults.standard.data(forKey: "PomodoroTimerState"),
              let savedState = try? JSONDecoder().decode(PersistentTimerState.self, from: data) else {
            return
        }
        
        // Calculate new remaining time
        let newTimeRemaining = max(0, savedState.timeRemaining - elapsedTime)
        
        // Restore state
        timeRemaining = newTimeRemaining
        currentSession = savedState.currentSession
        isBreakTime = savedState.isBreakTime
        
        // If timer should have completed while in background
        if newTimeRemaining <= 0 && savedState.isRunning {
            Task {
                await completeSession()
            }
        } else if savedState.isRunning {
            // Resume timer if it was running
            startTimer()
        }
        
        // Clear saved state
        UserDefaults.standard.removeObject(forKey: "PomodoroTimerState")
    }
    
    // MARK: - Notifications
    
    /// Sends notification when timer completes
    private func sendTimerCompletionNotification() async {
        #if os(iOS)
        let content = UNMutableNotificationContent()
        
        if isBreakTime {
            content.title = "休息时间结束"
            content.body = "准备开始第 \(currentSession + 1) 个工作番茄"
        } else {
            let isLongBreak = currentSession % 4 == 0
            let breakType = isLongBreak ? "长休息" : "短休息"
            content.title = "工作时间结束"
            content.body = "第 \(currentSession) 个番茄完成，开始\(breakType)"
        }
        
        content.sound = .default
        content.categoryIdentifier = "TIMER_COMPLETE"
        
        let request = UNNotificationRequest(
            identifier: "timer_complete_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate delivery
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        #endif
    }
    
    /// Schedules notification for background task expiration
    private func scheduleBackgroundExpirationNotification() async {
        #if os(iOS)
        let content = UNMutableNotificationContent()
        content.title = "番茄钟暂停"
        content.body = "应用在后台运行时间过长，计时器已暂停。请重新打开应用继续。"
        content.sound = .default
        content.categoryIdentifier = "BACKGROUND_EXPIRATION"
        
        // Schedule for immediate delivery
        let request = UNNotificationRequest(
            identifier: "background_expiration_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        #endif
    }
}

// MARK: - Timer State Model

/// Codable struct for persisting timer state during background transitions
private struct PersistentTimerState: Codable {
    let timeRemaining: Int
    let isRunning: Bool
    let currentSession: Int
    let isBreakTime: Bool
    let backgroundStartTime: Date?
}