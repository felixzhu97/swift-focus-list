import SwiftUI

struct PomodoroView: View {
    @ObservedObject var timer: PomodoroTimer
    @ScaledMetric private var timerCircleSize: CGFloat = ThemeManager.Spacing.timerCircleSize
    @ScaledMetric private var buttonSize: CGFloat = ThemeManager.Spacing.buttonSize
    @ScaledMetric private var buttonSpacing: CGFloat = ThemeManager.Spacing.buttonSpacing
    @ScaledMetric private var sectionSpacing: CGFloat = ThemeManager.Spacing.section
    @ScaledMetric private var screenPadding: CGFloat = ThemeManager.Spacing.screenMargin
    
    var body: some View {
        NavigationView {
            VStack(spacing: sectionSpacing) {
                // 会话信息
                VStack(spacing: ThemeManager.Spacing.small) {
                    Text("第 \(timer.currentSession) 个番茄")
                        .font(ThemeManager.Typography.headline)
                        .foregroundColor(ThemeManager.TextColors.secondary)
                    
                    Text(timer.isBreakTime ? "休息时间" : "专注时间")
                        .font(ThemeManager.Typography.sectionTitle)
                        .foregroundColor(ThemeManager.timerColor(isBreakTime: timer.isBreakTime))
                }
                
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
                }
                
                // 控制按钮
                HStack(spacing: buttonSpacing) {
                    Button(action: {
                        if timer.isRunning {
                            timer.pauseTimer()
                        } else {
                            timer.startTimer()
                        }
                    }) {
                        Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(ThemeManager.timerButtonColor(isBreakTime: timer.isBreakTime))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        timer.resetTimer()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(ThemeManager.SystemColors.neutral)
                            .clipShape(Circle())
                    }
                }
                
                Spacer()
            }
            .padding(screenPadding)
            .navigationTitle("番茄钟")
        }
    }
}

#Preview {
    PomodoroView(timer: PomodoroTimer())
}