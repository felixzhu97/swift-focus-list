import SwiftUI

struct PomodoroView: View {
    @ObservedObject var timer: PomodoroTimer
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 会话信息
                VStack {
                    Text("第 \(timer.currentSession) 个番茄")
                        .font(.headline)
                        .foregroundColor(ThemeManager.TextColors.secondary)
                    
                    Text(timer.isBreakTime ? "休息时间" : "专注时间")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(ThemeManager.timerColor(isBreakTime: timer.isBreakTime))
                }
                
                // 圆形进度条和时间显示
                ZStack {
                    Circle()
                        .stroke(ThemeManager.TimerColors.progressTrack, lineWidth: 8)
                        .frame(width: 250, height: 250)
                    
                    Circle()
                        .trim(from: 0, to: timer.progress)
                        .stroke(
                            ThemeManager.timerColor(isBreakTime: timer.isBreakTime, isRunning: timer.isRunning),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: timer.progress)
                    
                    Text(timer.formattedTime)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(ThemeManager.TextColors.primary)
                }
                
                // 控制按钮
                HStack(spacing: 20) {
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
                            .frame(width: 60, height: 60)
                            .background(ThemeManager.timerButtonColor(isBreakTime: timer.isBreakTime))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        timer.resetTimer()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(ThemeManager.SystemColors.neutral)
                            .clipShape(Circle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("番茄钟")
        }
    }
}

#Preview {
    PomodoroView(timer: PomodoroTimer())
}