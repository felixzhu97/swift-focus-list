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
    @ScaledMetric private var buttonSpacing: CGFloat = DesignTokens.Spacing.buttonSpacing
    @ScaledMetric private var sectionSpacing: CGFloat = DesignTokens.Spacing.section
    @ScaledMetric private var screenPadding: CGFloat = DesignTokens.Spacing.screenMargin
    
    // Track previous progress for milestone announcements
    @State private var previousProgress: Double = 0.0
    
    // Track last announced time for VoiceOver time updates
    @State private var lastAnnouncedTime: Int = 0
    
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: sectionSpacing) {
                // Session Information
                SessionInfoView(timer: timer)
                
                // Timer Display
                TimerDisplayView(
                    timer: timer,
                    accessibilityManager: accessibilityManager,
                    previousProgress: $previousProgress,
                    lastAnnouncedTime: $lastAnnouncedTime
                )
                
                // Control Buttons
                TimerControlsView(
                    timer: timer,
                    accessibilityManager: accessibilityManager,
                    isStopButtonDisabled: isStopButtonDisabled,
                    buttonSpacing: buttonSpacing
                )
                
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