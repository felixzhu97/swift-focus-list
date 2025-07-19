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
        
        if isBreakTime {
            // 休息结束，开始工作
            isBreakTime = false
            timeRemaining = workDuration
            currentSession += 1
        } else {
            // 工作结束，开始休息
            isBreakTime = true
            timeRemaining = currentSession % 4 == 0 ? longBreakDuration : shortBreakDuration
        }
    }
}