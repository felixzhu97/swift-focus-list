import SwiftUI

struct ContentView: View {
    @StateObject private var pomodoroTimer = PomodoroTimer()
    @StateObject private var accessibilityManager = AccessibilityManager()
    @StateObject private var todoManager = TodoManager()
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if #available(iOS 16.0, macOS 13.0, *) {
                ResponsiveNavigationView {
                    // Timer Content
                    PomodoroView(timer: pomodoroTimer, accessibilityManager: accessibilityManager)
                        .badge(timerBadgeText)
                        .accessibilityLabel(timerAccessibilityLabel)
                        .accessibilityHint("切换到番茄钟计时器界面，管理工作和休息时间")
                        .accessibilityValue(timerAccessibilityValue)
                } todoContent: {
                    // Todo Content
                    TodoListView(todoManager: todoManager, accessibilityManager: accessibilityManager)
                        .accessibilityLabel("待办事项列表")
                        .accessibilityHint("切换到待办事项管理界面，查看和编辑任务")
                        .accessibilityValue(todoAccessibilityValue)
                }
            } else {
                LegacyResponsiveNavigationView {
                    // Timer Content
                    PomodoroView(timer: pomodoroTimer, accessibilityManager: accessibilityManager)
                        .badge(timerBadgeText)
                        .accessibilityLabel(timerAccessibilityLabel)
                        .accessibilityHint("切换到番茄钟计时器界面，管理工作和休息时间")
                        .accessibilityValue(timerAccessibilityValue)
                } todoContent: {
                    // Todo Content
                    TodoListView(todoManager: todoManager, accessibilityManager: accessibilityManager)
                        .accessibilityLabel("待办事项列表")
                        .accessibilityHint("切换到待办事项管理界面，查看和编辑任务")
                        .accessibilityValue(todoAccessibilityValue)
                }
            }
        }
        .responsiveLayout()
        .accentColor(DesignTokens.SystemColors.accent)
        .onAppear {
            // Connect accessibility manager to timer for announcements
            pomodoroTimer.accessibilityManager = accessibilityManager
        }
    }
    
    // MARK: - Computed Properties for Tab Bar
    
    /// Dynamic timer tab icon based on current state
    private var timerTabIcon: String {
        switch (pomodoroTimer.isRunning, pomodoroTimer.isBreakTime) {
        case (true, true): return "cup.and.saucer.fill"
        case (true, false): return "timer"
        case (false, _): return "timer"
        }
    }
    
    /// Dynamic accessibility label for timer tab
    private var timerAccessibilityLabel: String {
        let baseLabel = "番茄钟计时器"
        
        guard pomodoroTimer.isRunning else { return baseLabel }
        
        let stateText = pomodoroTimer.isBreakTime ? "休息中" : "工作中"
        let timeText = pomodoroTimer.formattedTime
        return "\(baseLabel)，\(stateText)，剩余时间 \(timeText)"
    }
    
    /// Badge text for active timer indication
    private var timerBadgeText: String? {
        guard pomodoroTimer.isRunning else { return nil }
        return pomodoroTimer.isBreakTime ? "休息" : "\(pomodoroTimer.currentSession)"
    }
    
    /// Accessibility value for timer tab providing current state information
    private var timerAccessibilityValue: String {
        if pomodoroTimer.isRunning {
            let stateText = pomodoroTimer.isBreakTime ? "休息模式" : "工作模式"
            let sessionText = "第 \(pomodoroTimer.currentSession) 个番茄"
            return "\(stateText)，\(sessionText)"
        } else {
            return "计时器已停止"
        }
    }
    
    /// Accessibility value for todo tab providing task count information
    private var todoAccessibilityValue: String {
        let stats = todoManager.todoStats
        if stats.total == 0 {
            return "暂无任务"
        } else {
            let activeText = stats.active > 0 ? "\(stats.active) 个待完成" : ""
            let completedText = stats.completed > 0 ? "\(stats.completed) 个已完成" : ""
            let parts = [activeText, completedText].filter { !$0.isEmpty }
            return parts.joined(separator: "，")
        }
    }
}

#Preview {
    ContentView()
}