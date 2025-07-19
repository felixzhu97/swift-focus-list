import SwiftUI

// MARK: - Custom Circular Progress View Style

struct NativeCircularProgressViewStyle: ProgressViewStyle {
    let tint: Color
    let lineWidth: CGFloat
    
    init(tint: Color, lineWidth: CGFloat = 8) {
        self.tint = tint
        self.lineWidth = lineWidth
    }
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: configuration.fractionCompleted ?? 0)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

struct PomodoroView: View {
    @ObservedObject var timer: PomodoroTimer
    @ObservedObject var accessibilityManager: AccessibilityManager
    @ScaledMetric private var timerCircleSize: CGFloat = ThemeManager.Spacing.timerCircleSize
    @ScaledMetric private var buttonSize: CGFloat = ThemeManager.Spacing.buttonSize
    @ScaledMetric private var buttonSpacing: CGFloat = ThemeManager.Spacing.buttonSpacing
    @ScaledMetric private var sectionSpacing: CGFloat = ThemeManager.Spacing.section
    @ScaledMetric private var screenPadding: CGFloat = ThemeManager.Spacing.screenMargin
    
    // Track previous progress for milestone announcements
    @State private var previousProgress: Double = 0.0
    
    // Button state tracking for enhanced visual feedback
    @State private var playButtonPressed: Bool = false
    @State private var stopButtonPressed: Bool = false
    @State private var playButtonHovered: Bool = false
    @State private var stopButtonHovered: Bool = false
    
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
    
    // MARK: - Button State Computed Properties
    
    /// Determines if the stop/reset button should be disabled
    private var isStopButtonDisabled: Bool {
        // Disabled when timer is at initial state (full time remaining) and not running
        let initialWorkTime = 25 * 60
        let initialShortBreakTime = 5 * 60
        let initialLongBreakTime = 15 * 60
        
        let expectedInitialTime = timer.isBreakTime ? 
            (timer.currentSession % 4 == 0 ? initialLongBreakTime : initialShortBreakTime) : 
            initialWorkTime
        
        return timer.timeRemaining == expectedInitialTime && !timer.isRunning
    }
    
    // MARK: - Progress Announcement Helper
    
    private func announceProgressIfNeeded(newProgress: Double) {
        guard accessibilityManager.isVoiceOverEnabled else { return }
        
        let milestones: [Double] = [0.25, 0.5, 0.75]
        
        for milestone in milestones {
            // Check if we've crossed a milestone
            if previousProgress < milestone && newProgress >= milestone {
                let percent = Int(milestone * 100)
                let stateText = timer.isBreakTime ? "休息" : "工作"
                let announcement = "\(stateText)时间已完成 \(percent)%"
                
                // Delay announcement slightly to avoid conflicts with other announcements
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    accessibilityManager.announceStateChange(announcement)
                }
                break // Only announce one milestone at a time
            }
        }
        
        // Update previous progress for next comparison
        previousProgress = newProgress
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
                GeometryReader { geometry in
                    let size = min(geometry.size.width, geometry.size.height, timerCircleSize)
                    
                    ZStack {
                        // Native ProgressView with custom styling
                        ProgressView(value: timer.progress, total: 1.0)
                            .progressViewStyle(NativeCircularProgressViewStyle(
                                tint: ThemeManager.timerColor(isBreakTime: timer.isBreakTime, isRunning: timer.isRunning),
                                lineWidth: 8
                            ))
                            .frame(width: size, height: size)
                            .animation(.easeInOut(duration: 0.8), value: timer.progress)
                            .animation(.easeInOut(duration: 0.5), value: timer.isBreakTime)
                        
                        // Timer display text
                        Text(timer.formattedTime)
                            .font(ThemeManager.Typography.timerDisplay)
                            .foregroundColor(ThemeManager.TextColors.primary)
                            .monospacedDigit()
                            .accessibilityLabel(timerAccessibilityLabel)
                            .accessibilityValue(timerAccessibilityValue)
                            .scaleEffect(min(size / timerCircleSize, 1.0))
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
                    // Announce progress at key milestones (25%, 50%, 75%)
                    announceProgressIfNeeded(newProgress: newValue)
                }
                
                // 控制按钮 - Enhanced with native button styling and comprehensive state management
                HStack(spacing: buttonSpacing) {
                    // Play/Pause Button with native .borderedProminent styling
                    Button(action: {
                        // Trigger appropriate haptic feedback
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
                        Label(timer.isRunning ? "暂停" : "开始", 
                              systemImage: timer.isRunning ? "pause.fill" : "play.fill")
                            .font(.title2.weight(.medium))
                            .labelStyle(.iconOnly)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24) // Consistent icon sizing
                    }
                    .buttonStyle(.borderedProminent) // Native prominent button style
                    .controlSize(.large) // Large control size for better touch targets
                    .tint(ThemeManager.timerButtonColor(isBreakTime: timer.isBreakTime))
                    .disabled(false) // Timer controls are always enabled
                    .accessibilityLabel(timer.isRunning ? "暂停计时器" : "开始计时器")
                    .accessibilityHint(accessibilityManager.accessibilityHint(for: timer.isRunning ? .pauseTimer : .startTimer))
                    .accessibilityAddTraits(.isButton)
                    // Ensure minimum 44pt touch targets with accessibility scaling
                    .frame(minWidth: max(44, accessibilityManager.minimumTouchTargetSize()), 
                           minHeight: max(44, accessibilityManager.minimumTouchTargetSize()))
                    // macOS keyboard shortcut: Space for play/pause
                    .keyboardShortcut(.space, modifiers: [])
                    // Enhanced button state animations and visual feedback
                    .scaleEffect(playButtonPressed ? 0.95 : 1.0)
                    .opacity(playButtonHovered ? 0.85 : 1.0)
                    .brightness(playButtonPressed ? -0.1 : 0.0)
                    .animation(.easeInOut(duration: 0.1), value: playButtonPressed)
                    .animation(.easeInOut(duration: 0.15), value: playButtonHovered)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: timer.isRunning)
                    // Button state tracking for enhanced visual feedback
                    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            playButtonPressed = pressing
                        }
                    }, perform: {})
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            playButtonHovered = hovering
                        }
                    }
                    
                    // Stop/Reset Button with native .borderedProminent styling
                    Button(action: {
                        // Trigger haptic feedback for button interaction
                        accessibilityManager.triggerHapticFeedback(for: .buttonTap)
                        timer.resetTimer()
                        accessibilityManager.announceStateChange("计时器已重置")
                    }) {
                        Label("重置", systemImage: "stop.fill")
                            .font(.title2.weight(.medium))
                            .labelStyle(.iconOnly)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24) // Consistent icon sizing
                    }
                    .buttonStyle(.borderedProminent) // Native prominent button style
                    .controlSize(.large) // Large control size for better touch targets
                    .tint(ThemeManager.SystemColors.neutral)
                    // Proper disabled state: disabled when timer is at initial state and not running
                    .disabled(isStopButtonDisabled)
                    .accessibilityLabel("重置计时器")
                    .accessibilityHint(accessibilityManager.accessibilityHint(for: .stopTimer))
                    .accessibilityAddTraits(.isButton)
                    // Ensure minimum 44pt touch targets with accessibility scaling
                    .frame(minWidth: max(44, accessibilityManager.minimumTouchTargetSize()), 
                           minHeight: max(44, accessibilityManager.minimumTouchTargetSize()))
                    // macOS keyboard shortcut: Escape for stop/reset
                    .keyboardShortcut(.escape, modifiers: [])
                    // Enhanced button state animations and visual feedback
                    .scaleEffect(stopButtonPressed ? 0.95 : 1.0)
                    .opacity(stopButtonHovered && !isStopButtonDisabled ? 0.85 : (isStopButtonDisabled ? 0.6 : 1.0))
                    .brightness(stopButtonPressed && !isStopButtonDisabled ? -0.1 : 0.0)
                    .animation(.easeInOut(duration: 0.1), value: stopButtonPressed)
                    .animation(.easeInOut(duration: 0.15), value: stopButtonHovered)
                    .animation(.easeInOut(duration: 0.2), value: isStopButtonDisabled)
                    // Button state tracking for enhanced visual feedback
                    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                        guard !isStopButtonDisabled else { return }
                        withAnimation(.easeInOut(duration: 0.1)) {
                            stopButtonPressed = pressing
                        }
                    }, perform: {})
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            stopButtonHovered = hovering
                        }
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
    PomodoroView(timer: PomodoroTimer(), accessibilityManager: AccessibilityManager())
}