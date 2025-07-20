import SwiftUI

struct TodoRowView: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let accessibilityManager: AccessibilityManager
    
    // MARK: - Scaled Metrics for Dynamic Type Support
    @ScaledMetric private var rowVerticalPadding: CGFloat = DesignTokens.Spacing.componentPadding / 2
    @ScaledMetric private var contentSpacing: CGFloat = DesignTokens.Spacing.componentPadding / 2
    @ScaledMetric private var checkmarkSize: CGFloat = 24
    
    // MARK: - Animation State
    @State private var isAnimatingCompletion = false
    
    // MARK: - Accessibility Computed Properties
    private var todoAccessibilityLabel: String {
        let priorityText = todo.priority.accessibilityLabel
        let statusText = todo.isCompleted ? "已完成" : "未完成"
        let dateText = DateFormatter.localizedString(from: todo.createdAt, dateStyle: .short, timeStyle: .none)
        return "\(priorityText)任务：\(todo.title)，\(statusText)，创建于\(dateText)"
    }
    
    private var checkmarkAccessibilityLabel: String {
        todo.isCompleted ? "标记为未完成" : "标记为完成"
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            CheckmarkButton(
                isCompleted: todo.isCompleted,
                isAnimating: isAnimatingCompletion,
                accessibilityLabel: checkmarkAccessibilityLabel,
                accessibilityManager: accessibilityManager,
                onToggle: handleToggle
            )
            
            TodoContent(
                todo: todo,
                contentSpacing: contentSpacing
            )
            
            TodoActionsMenu(
                todo: todo,
                onEdit: onEdit,
                onToggle: handleToggle,
                onDelete: onDelete,
                accessibilityManager: accessibilityManager
            )
        }
        .padding(.vertical, rowVerticalPadding)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(todoAccessibilityLabel)
        .accessibilityHint("使用完成按钮切换状态，或使用操作菜单进行更多操作")
        .accessibilityAddTraits(todo.isCompleted ? [.isSelected] : [])
        .contextMenu {
            TodoContextMenu(
                todo: todo,
                onEdit: onEdit,
                onToggle: handleToggle,
                onDelete: onDelete,
                accessibilityManager: accessibilityManager
            )
        }
    }
    
    private func handleToggle() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isAnimatingCompletion = true
        }
        
        accessibilityManager.triggerHapticFeedback(for: .todoComplete)
        onToggle()
        
        let statusText = todo.isCompleted ? "任务已标记为未完成" : "任务已完成"
        accessibilityManager.announceStateChange(statusText)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimatingCompletion = false
        }
    }
}

// MARK: - Supporting Views

private struct CheckmarkButton: View {
    let isCompleted: Bool
    let isAnimating: Bool
    let accessibilityLabel: String
    let accessibilityManager: AccessibilityManager
    let onToggle: () -> Void
    
    @ScaledMetric private var checkmarkSize: CGFloat = 24
    
    var body: some View {
        Button(action: onToggle) {
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .frame(width: accessibilityManager.minimumTouchTargetSize(), 
                           height: accessibilityManager.minimumTouchTargetSize())
                
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: checkmarkSize, weight: .medium))
                    .foregroundColor(isCompleted ? DesignTokens.SystemColors.success : DesignTokens.SystemColors.neutral)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("双击切换任务完成状态")
        .accessibilityAddTraits(isCompleted ? [.isSelected] : [])
    }
}

private struct TodoContent: View {
    let todo: TodoItem
    let contentSpacing: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            HStack(spacing: DesignTokens.Spacing.small / 2) {
                Text(todo.title)
                    .font(DesignTokens.Typography.headline)
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? DesignTokens.TextColors.secondary : DesignTokens.TextColors.primary)
                    .animation(.easeInOut(duration: 0.2), value: todo.isCompleted)
                
                Spacer()
            }
            .accessibilityLabel("任务标题：\(todo.title)")
            .accessibilityAddTraits(todo.isCompleted ? [.isSelected] : [])
            
            HStack(spacing: DesignTokens.Spacing.small) {
                PriorityBadge(priority: todo.priority)
                
                Spacer()
                
                Text(todo.createdAt, style: .date)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.TextColors.secondary)
                    .accessibilityLabel("创建日期：\(DateFormatter.localizedString(from: todo.createdAt, dateStyle: .medium, timeStyle: .none))")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("任务内容：\(todo.title)，\(todo.priority.accessibilityLabel)")
    }
}

private struct TodoActionsMenu: View {
    let todo: TodoItem
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    let accessibilityManager: AccessibilityManager
    
    var body: some View {
        Menu {
            TodoContextMenu(
                todo: todo,
                onEdit: onEdit,
                onToggle: onToggle,
                onDelete: onDelete,
                accessibilityManager: accessibilityManager
            )
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
                    .frame(width: accessibilityManager.minimumTouchTargetSize(), 
                           height: accessibilityManager.minimumTouchTargetSize())
                
                Image(systemName: "ellipsis")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.SystemColors.neutral)
                    .apply { image in
                        if #available(macOS 13.0, iOS 16.0, *) {
                            image.fontWeight(.medium)
                        } else {
                            image
                        }
                    }
            }
        }
        .accessibilityLabel("任务操作菜单")
        .accessibilityHint("双击打开编辑、完成状态切换和删除选项")
    }
}

private struct TodoContextMenu: View {
    let todo: TodoItem
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    let accessibilityManager: AccessibilityManager
    
    var body: some View {
        Button {
            onEdit()
            accessibilityManager.announceStateChange("打开编辑界面")
        } label: {
            Label("编辑任务", systemImage: "pencil")
        }
        .accessibilityLabel("编辑任务")
        .accessibilityHint("编辑当前任务的标题和优先级")
        
        Button {
            accessibilityManager.triggerHapticFeedback(for: .todoComplete)
            onToggle()
            let statusText = todo.isCompleted ? "任务已标记为未完成" : "任务已完成"
            accessibilityManager.announceStateChange(statusText)
        } label: {
            Label(todo.isCompleted ? "标记为未完成" : "标记为完成", 
                  systemImage: todo.isCompleted ? "arrow.uturn.backward" : "checkmark")
        }
        .accessibilityLabel(todo.isCompleted ? "标记为未完成" : "标记为完成")
        
        Divider()
        
        Button(role: .destructive) {
            accessibilityManager.triggerHapticFeedback(for: .error)
            onDelete()
            accessibilityManager.announceStateChange("任务已删除")
        } label: {
            Label("删除任务", systemImage: "trash")
        }
        .accessibilityLabel("删除任务")
        .accessibilityHint("永久删除当前任务")
    }
}