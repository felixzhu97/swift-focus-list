import SwiftUI

struct PriorityBadge: View {
    let priority: TodoItem.Priority
    
    @ScaledMetric private var horizontalPadding: CGFloat = DesignTokens.Spacing.componentPadding
    @ScaledMetric private var verticalPadding: CGFloat = DesignTokens.Spacing.componentPadding / 4
    @ScaledMetric private var cornerRadius: CGFloat = DesignTokens.Spacing.componentPadding
    @ScaledMetric private var iconSize: CGFloat = 16
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.small / 2) {
            Image(systemName: priority.systemImage)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(priority.color)
                .accessibilityHidden(true)
            
            Text(priority.rawValue)
                .font(DesignTokens.Typography.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(priority.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(priority.color.opacity(0.3), lineWidth: 0.5)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(priority.accessibilityLabel)
    }
}