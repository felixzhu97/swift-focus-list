import Foundation

/// Provides localized accessibility labels and hints
struct AccessibilityLabelProvider {
    
    // MARK: - Timer Labels
    
    static func timerLabel(for state: TimerState, remainingTime: TimeInterval) -> String {
        switch state {
        case .idle:
            return "计时器已停止"
        case .working:
            let (minutes, seconds) = formatTime(remainingTime)
            return "工作时间，剩余 \(minutes) 分 \(seconds) 秒"
        case .onBreak:
            let (minutes, seconds) = formatTime(remainingTime)
            return "休息时间，剩余 \(minutes) 分 \(seconds) 秒"
        case .paused:
            return "计时器已暂停"
        }
    }
    
    // MARK: - Todo Labels
    
    static func todoLabel(for item: TodoItem) -> String {
        let priorityText = priorityText(for: item.priority)
        let statusText = item.isCompleted ? "已完成" : "未完成"
        return "\(priorityText)任务：\(item.title)，\(statusText)"
    }
    
    // MARK: - Action Hints
    
    static func actionHint(for action: AccessibilityAction) -> String {
        switch action {
        case .startTimer: return "双击开始计时器"
        case .pauseTimer: return "双击暂停计时器"
        case .stopTimer: return "双击停止计时器"
        case .completeTodo: return "双击标记任务完成"
        case .editTodo: return "双击编辑任务"
        case .deleteTodo: return "双击删除任务"
        }
    }
    
    // MARK: - Time Announcements
    
    static func timeAnnouncement(timeRemaining: Int, isBreakTime: Bool) -> String {
        let stateText = isBreakTime ? "休息时间" : "工作时间"
        let timeText = formatTimeForAnnouncement(timeRemaining)
        return "\(stateText)剩余 \(timeText)"
    }
    
    // MARK: - Private Helpers
    
    private static func priorityText(for priority: TodoItem.Priority) -> String {
        switch priority {
        case .high: return "高优先级"
        case .medium: return "中优先级"
        case .low: return "低优先级"
        }
    }
    
    private static func formatTime(_ timeInterval: TimeInterval) -> (minutes: Int, seconds: Int) {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return (minutes, seconds)
    }
    
    private static func formatTimeForAnnouncement(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if totalSeconds <= 10 {
            return "\(totalSeconds) 秒"
        } else if minutes > 0 {
            return seconds > 0 ? "\(minutes) 分 \(seconds) 秒" : "\(minutes) 分"
        } else {
            return "\(seconds) 秒"
        }
    }
}