import SwiftUI

struct TimerControlsView: View {
    @ObservedObject var timer: PomodoroTimer
    @ObservedObject var accessibilityManager: AccessibilityManager
    let isStopButtonDisabled: Bool
    let buttonSpacing: CGFloat
    
    var body: some View {
        HStack(spacing: buttonSpacing) {
            // Play/Pause Button
            TimerControlButton(
                title: timer.isRunning ? "暂停" : "开始",
                systemImage: timer.isRunning ? "pause.fill" : "play.fill",
                action: {
                    accessibilityManager.triggerHapticFeedback(for: timer.isRunning ? .buttonTap : .timerStart)
                    
                    if timer.isRunning {
                        timer.pauseTimer()
                        accessibilityManager.announceStateChange("计时器已暂停")
                    } else {
                        timer.startTimer()
                        let stateText = timer.isBreakTime ? "休息时间开始" : "工作时间开始"
                        accessibilityManager.announceStateChange(stateText)
                    }
                },
                tint: DesignTokens.TimerColors.color(isBreakTime: timer.isBreakTime, isRunning: timer.isRunning),
                keyboardShortcut: .space,
                accessibilityManager: accessibilityManager
            )
            
            // Stop/Reset Button
            TimerControlButton(
                title: "重置",
                systemImage: "stop.fill",
                action: {
                    accessibilityManager.triggerHapticFeedback(for: .buttonTap)
                    timer.resetTimer()
                    accessibilityManager.announceStateChange("计时器已重置")
                },
                tint: Color.secondary,
                isDisabled: isStopButtonDisabled,
                keyboardShortcut: .escape,
                accessibilityManager: accessibilityManager
            )
        }
    }
}