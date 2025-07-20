import SwiftUI

/// Test view to demonstrate typography scaling with Dynamic Type
struct TypographyTestView: View {
    @ScaledMetric private var timerCircleSize: CGFloat = DesignTokens.Spacing.timerCircleSize
    @ScaledMetric private var buttonSize: CGFloat = DesignTokens.Spacing.buttonSize
    @ScaledMetric private var spacing: CGFloat = DesignTokens.Spacing.medium
    
    var body: some View {
        ScrollView {
            VStack(spacing: spacing) {
                Group {
                    Text("Typography Scale Test")
                        .font(DesignTokens.Typography.sectionTitle)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    
                    Text("Timer Display (Large Title + Monospaced)")
                        .font(DesignTokens.Typography.timerDisplay)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    
                    Text("Section Title (Title2 + Semibold)")
                        .font(DesignTokens.Typography.sectionTitle)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    
                    Text("Headline Text")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    
                    Text("Body Text - This is the standard body text that should scale with Dynamic Type settings.")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    
                    Text("Caption Text - Secondary information")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.TextColors.secondary)
                    
                    Text("Caption2 Text - Very small details")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.TextColors.tertiary)
                }
                
                Divider()
                
                Group {
                    Text("Scaled Metrics Test")
                        .font(DesignTokens.Typography.sectionTitle)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    
                    Text("Timer Circle Size: \(Int(timerCircleSize))pt")
                        .font(DesignTokens.Typography.body)
                    
                    Text("Button Size: \(Int(buttonSize))pt")
                        .font(DesignTokens.Typography.body)
                    
                    Text("Spacing: \(Int(spacing))pt")
                        .font(DesignTokens.Typography.body)
                    
                    // Visual demonstration
                    Circle()
                        .stroke(DesignTokens.TimerColors.workSession, lineWidth: 4)
                        .frame(width: timerCircleSize * 0.5, height: timerCircleSize * 0.5)
                        .overlay(
                            Text("25:00")
                                .font(DesignTokens.Typography.timerDisplay)
                                .monospacedDigit()
                                .foregroundColor(DesignTokens.TextColors.primary)
                        )
                    
                    HStack(spacing: spacing) {
                        Circle()
                            .fill(DesignTokens.TimerColors.workSession)
                            .frame(width: buttonSize, height: buttonSize)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                                    .font(.title)
                            )
                        
                        Circle()
                            .fill(DesignTokens.SystemColors.neutral)
                            .frame(width: buttonSize, height: buttonSize)
                            .overlay(
                                Image(systemName: "stop.fill")
                                    .foregroundColor(.white)
                                    .font(.title)
                            )
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                    Text("Instructions:")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    
                    Text("1. Go to Settings > Display & Brightness > Text Size")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    
                    Text("2. Adjust the text size slider")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    
                    Text("3. Return to this app to see the scaling effect")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    
                    Text("4. For larger sizes, enable 'Larger Accessibility Sizes'")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.TextColors.secondary)
                }
                .padding(DesignTokens.Spacing.medium)
                .background(DesignTokens.BackgroundColors.secondary)
                .cornerRadius(DesignTokens.Spacing.listItem)
            }
            .padding(DesignTokens.Spacing.screenMargin)
        }
        .navigationTitle("Typography Test")
    }
}

#Preview {
    NavigationView {
        TypographyTestView()
    }
}