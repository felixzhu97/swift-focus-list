import SwiftUI

struct PomodoroView: View {
    @ObservedObject var timer: PomodoroTimer
    @ObservedObject var accessibilityManager: AccessibilityManager
    @ScaledMetric private var timerCircleSize: CGFloat = ThemeManager.Spacing.timerCircleSize
    @ScaledMetric private var buttonSize: CGFloat = ThemeManager.Spacing.buttonSize
    @ScaledMetric private var buttonSpacing: CGFloat = ThemeManager.Spacing.buttonSpacing
    @ScaledMetric private var sectionSpacing: CGFloat = ThemeManager.Spacing.section
    @ScaledMetric private var screenPadding: CGFloat = ThemeManager.Spacing.screenMargin
    
    // MARK: - Accessibility Computed Properties
    
    private var timerAccessibilityLabel: String {
        let minutes = timer.timeRemaining / 60
        let seconds = timer.timeRemaining % 60
        let timeText = "剩余 \(minutes) 分 \(seconds) 秒"
        let stateText = timer.isBreakTime ? "休息时间" : "工作时间"
        let statusText = timer.isRunning ? "正在运行" : "已暂停"
        return "\(stateText)，\(timeText)，计时器\(statusText)"
    }
    
    private var timerAccessibilityValue: String {
        let progressPercent = Int(timer.progress * 100)
        return "进度 \(progressPercent)%"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: sectionSpacing) {
                // 会话信息
                VStack(spacing: ThemeManager.Spacing.small) {
                    Text("第 \(timer.currentSession) 个番茄")
                        .font(ThemeManager.Typography.headline)
                        .foregroundColor(ThemeManager.TextColors.secondary)
                        .accessibilityLabel("当前是第 \(timer.currentSession) 个番茄钟会话")
                    
                    Text(timer.isBreakTime ? "休息时间" : "专注时间")
                        .font(ThemeManager.Typography.sectionTitle)
                        .foregroundColor(ThemeManager.timerColor(isBreakTime: timer.isBreakTime))
                        .accessibilityLabel(timer.isBreakTime ? "当前是休息时间" : "当前是专注工作时间")
                }
                .accessibilityElement(children: .combine)
                
                // 圆形进度条和时间显示
                ZStack {
                    Circle()
                        .stroke(ThemeManager.TimerColors.progressTrack, lineWidth: 8)
                        .frame(width: timerCircleSize, height: timerCircleSize)
                    
                    Circle()
                        .trim(from: 0, to: timer.progress)
                        .stroke(
                            ThemeManager.timerColor(isBreakTime: timer.isBreakTime, isRunning: timer.isRunning),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: timerCircleSize, height: timerCircleSize)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: timer.progress)
                    
                    Text(timer.formattedTime)
                        .font(ThemeManager.Typography.timerDisplay)
                        .foregroundColor(ThemeManager.TextColors.primary)
                        .monospacedDigit()
                        .accessibilityLabel(timerAccessibilityLabel)
                        .accessibilityValue(timerAccessibilityValue)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("计时器显示")
                .accessibilityValue(timerAccessibilityLabel)
                
                // 控制按钮
                HStack(spacing: buttonSpacing) {
                    Button(action: {
                        // Trigger haptic feedback
                        accessibilityManager.triggerHapticFeedback(for: timer.isRunning ? .buttonTap : .timerStart)
                        
                        if timer.isRunning {
                            timer.pauseTimer()
                            accessibilityManager.announceStateChange("计时器已暂停")
                        } else {
                            timer.startTimer()
                            let stateText = timer.isBreakTime ? "休息时间开始" : "工作时间开始"
                            accessibilityManager.announceStateChange(stateText)
                        }
                    }) {
                        Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(ThemeManager.timerButtonColor(isBreakTime: timer.isBreakTime))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(timer.isRunning ? "暂停计时器" : "开始计时器")
                    .accessibilityHint(accessibilityManager.accessibilityHint(for: timer.isRunning ? .pauseTimer : .startTimer))
                    .frame(minWidth: accessibilityManager.minimumTouchTargetSize(), minHeight: accessibilityManager.minimumTouchTargetSize())
                    
                    Button(action: {
                        // Trigger haptic feedback
                        accessibilityManager.triggerHapticFeedback(for: .buttonTap)
                        timer.resetTimer()
                        accessibilityManager.announceStateChange("计时器已重置")
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(ThemeManager.SystemColors.neutral)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("重置计时器")
                    .accessibilityHint(accessibilityManager.accessibilityHint(for: .stopTimer))
                    .frame(minWidth: accessibilityManager.minimumTouchTargetSize(), minHeight: accessibilityManager.minimumTouchTargetSize())
                }
                
                Spacer()
            }
            .padding(screenPadding)
            .navigationTitle("番茄钟")
        }
    }
}

#Preview {
    PomodoroView(timer: PomodoroTimer(), accessibilityManager: AccessibilityManager())
}