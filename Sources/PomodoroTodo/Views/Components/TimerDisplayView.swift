import SwiftUI

struct TimerDisplayView: View {
    @ObservedObject var timer: PomodoroTimer
    @ObservedObject var accessibilityManager: AccessibilityManager
    @ScaledMetric private var timerCircleSize: CGFloat = DesignTokens.Spacing.timerCircleSize
    
    @Binding var previousProgress: Double
    @Binding var lastAnnouncedTime: Int
    
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
    
    private func announceProgressIfNeeded(newProgress: Double) {
        guard accessibilityManager.isVoiceOverEnabled else { return }
        
        let milestones: [Double] = [0.25, 0.5, 0.75]
        
        for milestone in milestones {
            if previousProgress < milestone && newProgress >= milestone {
                let percent = Int(milestone * 100)
                let stateText = timer.isBreakTime ? "休息" : "工作"
                let announcement = "\(stateText)时间已完成 \(percent)%"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    accessibilityManager.announceStateChange(announcement)
                }
                break
            }
        }
        
        previousProgress = newProgress
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height, timerCircleSize)
            
            ZStack {
                ProgressView(value: timer.progress, total: 1.0)
                    .progressViewStyle(NativeCircularProgressViewStyle(
                        tint: DesignTokens.TimerColors.color(isBreakTime: timer.isBreakTime, isRunning: timer.isRunning),
                        lineWidth: 8
                    ))
                    .frame(width: size, height: size)
                    .animation(.easeInOut(duration: 0.8), value: timer.progress)
                    .animation(.easeInOut(duration: 0.5), value: timer.isBreakTime)
                
                Text(timer.formattedTime)
                    .font(accessibilityManager.scaledTimerFont())
                    .foregroundColor(accessibilityManager.highContrastTimerTextColor())
                    .monospacedDigit()
                    .kerning(accessibilityManager.scaledKerning())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .accessibilityLabel(timerAccessibilityLabel)
                    .accessibilityValue(timerAccessibilityValue)
                    .accessibilityAddTraits(.updatesFrequently)
                    .scaleEffect(min(size / timerCircleSize, 1.0))
                    .animation(.easeInOut(duration: 0.2), value: timer.formattedTime)
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: timerCircleSize)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("计时器显示")
        .accessibilityValue(timerAccessibilityLabel)
        .accessibilityAddTraits(.updatesFrequently)
        .onChange(of: timer.progress) { newValue in
            announceProgressIfNeeded(newProgress: newValue)
        }
        .onChange(of: timer.timeRemaining) { newTime in
            accessibilityManager.announceTimeUpdateIfNeeded(
                timeRemaining: newTime,
                isBreakTime: timer.isBreakTime,
                lastAnnouncedTime: &lastAnnouncedTime
            )
        }
    }
}