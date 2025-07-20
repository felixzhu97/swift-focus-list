import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundColor(DesignTokens.SystemColors.neutral)
            
            Text("开始您的高效之旅")
                .font(DesignTokens.Typography.sectionTitle)
                .foregroundColor(DesignTokens.TextColors.primary)
            
            VStack(spacing: DesignTokens.Spacing.small) {
                Text("还没有任务？没关系！")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.TextColors.secondary)
                
                Text("点击右上角的加号按钮添加您的第一个任务，开始使用番茄工作法提高效率")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.TextColors.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.medium)
            }
            
            GestureHintsView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("任务列表为空，开始您的高效之旅")
        .accessibilityHint("点击右上角的加号按钮添加您的第一个任务，支持滑动手势操作和下拉刷新")
    }
}

private struct GestureHintsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            HStack {
                Image(systemName: "arrow.left")
                    .foregroundColor(DesignTokens.SystemColors.info)
                Text("向左滑动完成任务")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.TextColors.secondary)
            }
            
            HStack {
                Image(systemName: "arrow.right")
                    .foregroundColor(DesignTokens.SystemColors.warning)
                Text("向右滑动编辑或删除")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.TextColors.secondary)
            }
            
            HStack {
                Image(systemName: "arrow.down")
                    .foregroundColor(DesignTokens.SystemColors.neutral)
                Text("下拉刷新列表")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.TextColors.secondary)
            }
        }
        .padding(.top, DesignTokens.Spacing.medium)
    }
}

#Preview {
    EmptyStateView()
}