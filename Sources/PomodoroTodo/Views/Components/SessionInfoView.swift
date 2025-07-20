import SwiftUI

struct SessionInfoView: View {
    @ObservedObject var timer: PomodoroTimer
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.small) {
            Text("第 \(timer.currentSession) 个番茄")
                .font(DesignTokens.Typography.headline)
                .foregroundColor(DesignTokens.TextColors.secondary)
                .accessibilityLabel("当前是第 \(timer.currentSession) 个番茄钟会话")
            
            Text(timer.isBreakTime ? "休息时间" : "专注时间")
                .font(DesignTokens.Typography.sectionTitle)
                .foregroundColor(DesignTokens.TimerColors.color(isBreakTime: timer.isBreakTime))
                .accessibilityLabel(timer.isBreakTime ? "当前是休息时间" : "当前是专注工作时间")
        }
        .accessibilityElement(children: .combine)
    }
}