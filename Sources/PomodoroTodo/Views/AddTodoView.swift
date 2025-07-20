import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct AddTodoView: View {
    let todoManager: TodoManager
    let accessibilityManager: AccessibilityManager
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    @State private var priority: TodoItem.Priority = .medium
    @State private var titleValidationError: String?
    @FocusState private var isTitleFieldFocused: Bool
    
    private var isValidTitle: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var canSave: Bool {
        isValidTitle && titleValidationError == nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button("取消") {
                    handleCancel()
                }
                .accessibilityLabel("取消添加任务")
                .accessibilityHint("双击取消添加并关闭界面")
                
                Spacer()
                
                Text("添加任务")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("保存") {
                    handleSave()
                }
                .disabled(!canSave)
                .apply { button in
                    if #available(macOS 13.0, iOS 16.0, *) {
                        button.fontWeight(.semibold)
                    } else {
                        button
                    }
                }
                .accessibilityLabel("保存新任务")
                .accessibilityHint("双击保存新任务到列表")
            }
            .padding()
            .background(DesignTokens.BackgroundColors.secondary)
            
            // Form Content
            TodoForm(
                title: $title,
                priority: $priority,
                titleValidationError: $titleValidationError,
                isTitleFieldFocused: $isTitleFieldFocused,
                accessibilityManager: accessibilityManager
            )
        }
        .onAppear {
            print("AddTodoView出现")
            // Focus the title field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("尝试设置焦点")
                isTitleFieldFocused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            print("窗口成为焦点")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTitleFieldFocused = true
            }
        }
        .interactiveDismissDisabled(!title.isEmpty)
        .accessibilityLabel("添加新任务表单")
    }
    
    private func handleCancel() {
        accessibilityManager.triggerHapticFeedback(for: .buttonTap)
        
        if !title.isEmpty {
            // For now, just dismiss - we can add confirmation dialog later
            isPresented = false
            accessibilityManager.announceStateChange("已取消添加任务")
        } else {
            isPresented = false
            accessibilityManager.announceStateChange("已取消添加任务")
        }
    }
    
    private func handleSave() {
        // Validate input
        validateTitle()
        
        guard canSave else {
            accessibilityManager.triggerHapticFeedback(for: .error)
            accessibilityManager.announceStateChange("请检查输入内容")
            return
        }
        
        accessibilityManager.triggerHapticFeedback(for: .success)
        todoManager.addTodo(title, priority: priority)
        isPresented = false
        accessibilityManager.announceStateChange("新任务已添加")
    }
    
    private func validateTitle() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        
        if trimmedTitle.isEmpty {
            titleValidationError = "任务标题不能为空"
        } else if trimmedTitle.count > 100 {
            titleValidationError = "任务标题不能超过100个字符"
        } else {
            titleValidationError = nil
        }
    }
}

// MARK: - Supporting Views

private struct TodoForm: View {
    @Binding var title: String
    @Binding var priority: TodoItem.Priority
    @Binding var titleValidationError: String?
    var isTitleFieldFocused: FocusState<Bool>.Binding
    let accessibilityManager: AccessibilityManager
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.large) {
            titleSection
            prioritySection
            helpSection
        }
        .padding()
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text("任务内容")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.TextColors.secondary)
                .accessibilityLabel("任务内容部分")
            
            TextField("输入任务标题", text: $title)
                .textFieldStyle(.roundedBorder)
                .font(DesignTokens.Typography.body)
                .focused(isTitleFieldFocused)
                .onTapGesture {
                    print("TextField被点击")
                    isTitleFieldFocused.wrappedValue = true
                }
                .onChange(of: title) { _ in
                    print("TextField值变化: '\(title)'")
                    if titleValidationError != nil {
                        titleValidationError = nil
                    }
                }
                .onSubmit {
                    print("TextField提交")
                }
            
            if let error = titleValidationError {
                Text(error)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.SystemColors.destructive)
                    .accessibilityLabel("输入错误：\(error)")
            } else {
                Text("输入您要完成的任务描述")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.TextColors.secondary)
            }
        }
    }
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text("优先级")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.TextColors.secondary)
                .accessibilityLabel("优先级设置部分")
            
            priorityPicker
            
            Text("选择任务的重要程度，高优先级任务将显示在列表顶部")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.TextColors.secondary)
        }
    }
    
    private var priorityPicker: some View {
        Picker("优先级", selection: $priority) {
            ForEach(TodoItem.Priority.allCases, id: \.self) { priority in
                HStack {
                    PriorityIndicator(priority: priority)
                    Text(priority.rawValue)
                        .font(DesignTokens.Typography.body)
                }
                .tag(priority)
                .accessibilityLabel("优先级：\(priority.rawValue)")
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("任务优先级选择器")
        .accessibilityHint("选择任务的优先级：高、中或低")
        .accessibilityValue("当前选择：\(priority.rawValue)")
        .onChange(of: priority) { _ in
            accessibilityManager.triggerHapticFeedback(for: .buttonTap)
            accessibilityManager.announceStateChange("优先级已设置为\(priority.rawValue)")
        }
    }
    
    private var helpSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text("帮助")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.TextColors.secondary)
                .accessibilityLabel("使用帮助部分")
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                Text("使用技巧")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.TextColors.primary)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                    TipRow(icon: "timer", text: "使用番茄工作法专注完成任务")
                    TipRow(icon: "checkmark.circle", text: "完成后左滑标记为已完成")
                    TipRow(icon: "pencil", text: "右滑可以编辑或删除任务")
                }
            }
        }
    }
    
    private func validateTitle() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        
        if trimmedTitle.isEmpty {
            titleValidationError = "任务标题不能为空"
        } else if trimmedTitle.count > 100 {
            titleValidationError = "任务标题不能超过100个字符"
        } else {
            titleValidationError = nil
        }
    }
}

private struct PriorityIndicator: View {
    let priority: TodoItem.Priority
    
    var body: some View {
        Circle()
            .fill(priority.color)
            .frame(width: 12, height: 12)
            .accessibilityHidden(true)
    }
}

private struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: icon)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.SystemColors.info)
                .frame(width: 16)
            
            Text(text)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.TextColors.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

