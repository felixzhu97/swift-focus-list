import SwiftUI

/// Test view to demonstrate typography scaling with Dynamic Type
struct TypographyTestView: View {
    @ScaledMetric private var timerCircleSize: CGFloat = 250
    @ScaledMetric private var buttonSize: CGFloat = 60
    @ScaledMetric private var spacing: CGFloat = 16
    
    var body: some View {
        ScrollView {
            VStack(spacing: spacing) {
                Group {
                    Text("Typography Scale Test")
                        .font(ThemeManager.Typography.sectionTitle)
                        .foregroundColor(ThemeManager.TextColors.primary)
                    
                    Text("Timer Display (Large Title + Monospaced)")
                        .font(ThemeManager.Typography.timerDisplay)
                        .foregroundColor(ThemeManager.TextColors.primary)
                    
                    Text("Section Title (Title2 + Semibold)")
                        .font(ThemeManager.Typography.sectionTitle)
                        .foregroundColor(ThemeManager.TextColors.primary)
                    
                    Text("Headline Text")
                        .font(ThemeManager.Typography.headline)
                        .foregroundColor(ThemeManager.TextColors.primary)
                    
                    Text("Body Text - This is the standard body text that should scale with Dynamic Type settings.")
                        .font(ThemeManager.Typography.body)
                        .foregroundColor(ThemeManager.TextColors.primary)
                    
                    Text("Caption Text - Secondary information")
                        .font(ThemeManager.Typography.caption)
                        .foregroundColor(ThemeManager.TextColors.secondary)
                    
                    Text("Caption2 Text - Very small details")
                        .font(ThemeManager.Typography.caption2)
                        .foregroundColor(ThemeManager.TextColors.tertiary)
                }
                
                Divider()
                
                Group {
                    Text("Scaled Metrics Test")
                        .font(ThemeManager.Typography.sectionTitle)
                        .foregroundColor(ThemeManager.TextColors.primary)
                    
                    Text("Timer Circle Size: \(Int(timerCircleSize))pt")
                        .font(ThemeManager.Typography.body)
                    
                    Text("Button Size: \(Int(buttonSize))pt")
                        .font(ThemeManager.Typography.body)
                    
                    Text("Spacing: \(Int(spacing))pt")
                        .font(ThemeManager.Typography.body)
                    
                    // Visual demonstration
                    Circle()
                        .stroke(ThemeManager.TimerColors.workSession, lineWidth: 4)
                        .frame(width: timerCircleSize * 0.5, height: timerCircleSize * 0.5)
                        .overlay(
                            Text("25:00")
                                .font(ThemeManager.Typography.timerDisplay)
                                .monospacedDigit()
                                .foregroundColor(ThemeManager.TextColors.primary)
                        )
                    
                    HStack(spacing: spacing) {
                        Circle()
                            .fill(ThemeManager.TimerColors.workSession)
                            .frame(width: buttonSize, height: buttonSize)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                                    .font(.title)
                            )
                        
                        Circle()
                            .fill(ThemeManager.SystemColors.neutral)
                            .frame(width: buttonSize, height: buttonSize)
                            .overlay(
                                Image(systemName: "stop.fill")
                                    .foregroundColor(.white)
                                    .font(.title)
                            )
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: ThemeManager.Spacing.small) {
                    Text("Instructions:")
                        .font(ThemeManager.Typography.headline)
                        .foregroundColor(ThemeManager.TextColors.primary)
                    
                    Text("1. Go to Settings > Display & Brightness > Text Size")
                        .font(ThemeManager.Typography.body)
                        .foregroundColor(ThemeManager.TextColors.primary)
                    
                    Text("2. Adjust the text size slider")
                        .font(ThemeManager.Typography.body)
                        .foregroundColor(ThemeManager.TextColors.primary)
                    
                    Text("3. Return to this app to see the scaling effect")
                        .font(ThemeManager.Typography.body)
                        .foregroundColor(ThemeManager.TextColors.primary)
                    
                    Text("4. For larger sizes, enable 'Larger Accessibility Sizes'")
                        .font(ThemeManager.Typography.caption)
                        .foregroundColor(ThemeManager.TextColors.secondary)
                }
                .padding()
                .background(ThemeManager.BackgroundColors.secondary)
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Typography Test")
    }
}

#Preview {
    NavigationView {
        TypographyTestView()
    }
}