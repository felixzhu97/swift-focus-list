import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct EditTodoView: View {
    let todo: TodoItem
    let todoManager: TodoManager
    let accessibilityManager: AccessibilityManager
    @Binding var isPresented: Bool
    
    @State private var title: String
    @State private var priority: TodoItem.Priority
    @State private var titleValidationError: String?
    @State private var hasChanges: Bool = false
    @FocusState private var isTitleFieldFocused: Bool
    
    init(todo: TodoItem, todoManager: TodoManager, accessibilityManager: AccessibilityManager, isPresented: Binding<Bool>) {
        self.todo = todo
        self.todoManager = todoManager
        self.accessibilityManager = accessibilityManager
        self._isPresented = isPresented
        self._title = State(initialValue: todo.title)
        self._priority = State(initialValue: todo.priority)
    }
    
    private var isValidTitle: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var canSave: Bool {
        isValidTitle && titleValidationError == nil && hasChanges
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button("取消") {
                    handleCancel()
                }
                .accessibilityLabel("取消编辑任务")
                .accessibilityHint("双击取消编辑并关闭界面")
                
                Spacer()
                
                Text("编辑任务")
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
                .accessibilityLabel("保存任务修改")
                .accessibilityHint("双击保存修改到任务")
            }
            .padding()
            .background(DesignTokens.BackgroundColors.secondary)
            
            // Form Content
            EditTodoForm(
                title: $title,
                priority: $priority,
                titleValidationError: $titleValidationError,
                isTitleFieldFocused: $isTitleFieldFocused,
                originalTodo: todo,
                accessibilityManager: accessibilityManager
            )
        }
        .onChange(of: title) { (newValue: String) in
            updateHasChanges()
        }
        .onChange(of: priority) { (newValue: TodoItem.Priority) in
            updateHasChanges()
        }
        .onAppear {
            // Focus the title field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTitleFieldFocused = true
            }
        }
        .interactiveDismissDisabled(hasChanges)
        .accessibilityLabel("编辑任务表单")
    }
    
    private func updateHasChanges() {
        hasChanges = title != todo.title || priority != todo.priority
    }
    
    private func handleCancel() {
        accessibilityManager.triggerHapticFeedback(for: .buttonTap)
        
        if hasChanges {
            // For now, just dismiss - we can add confirmation dialog later
            isPresented = false
            accessibilityManager.announceStateChange("已取消编辑")
        } else {
            isPresented = false
            accessibilityManager.announceStateChange("已取消编辑")
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
        todoManager.updateTodo(todo, title: title, priority: priority)
        isPresented = false
        accessibilityManager.announceStateChange("任务已保存")
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

private struct EditTodoForm: View {
    @Binding var title: String
    @Binding var priority: TodoItem.Priority
    @Binding var titleValidationError: String?
    var isTitleFieldFocused: FocusState<Bool>.Binding
    let originalTodo: TodoItem
    let accessibilityManager: AccessibilityManager
    
    var body: some View {
        Form {
            titleSection
            prioritySection
            infoSection
        }
        .apply { form in
            if #available(iOS 16.0, macOS 13.0, *) {
                form.formStyle(.grouped)
            } else {
                form
            }
        }

    }
    
    private var titleSection: some View {
        Section {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                TextField("输入任务标题", text: $title)
                    .font(DesignTokens.Typography.body)
                    .focused(isTitleFieldFocused)
                    .apply { textField in
                        #if os(macOS)
                        textField.textFieldStyle(.roundedBorder)
                        #else
                        textField.textFieldStyle(.plain)
                        #endif
                    }
                    .accessibilityLabel("任务标题输入框")
                    .accessibilityHint("输入或修改任务的标题")
                    .accessibilityValue(title.isEmpty ? "空白" : title)
                    .onChange(of: title) { _ in
                        if titleValidationError != nil {
                            titleValidationError = nil
                        }
                    }
                    .onSubmit {
                        validateTitle()
                    }
                
                if let error = titleValidationError {
                    Text(error)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.SystemColors.destructive)
                        .accessibilityLabel("输入错误：\(error)")
                }
            }
        } header: {
            Text("任务内容")
                .font(DesignTokens.Typography.caption)
                .accessibilityLabel("任务内容部分")
        } footer: {
            if titleValidationError == nil {
                Text("修改任务的描述内容")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.TextColors.secondary)
            }
        }
    }
    
    private var prioritySection: some View {
        Section {
            priorityPicker
        } header: {
            Text("优先级")
                .font(DesignTokens.Typography.caption)
                .accessibilityLabel("优先级设置部分")
        } footer: {
            Text("修改任务的重要程度，高优先级任务将显示在列表顶部")
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
        .onChange(of: priority) { newPriority in
            accessibilityManager.triggerHapticFeedback(for: .buttonTap)
            accessibilityManager.announceStateChange("优先级已设置为\(newPriority.rawValue)")
        }
    }
    
    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                HStack {
                    Text("任务状态")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    
                    Spacer()
                    
                    HStack(spacing: DesignTokens.Spacing.small) {
                        Image(systemName: originalTodo.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(originalTodo.isCompleted ? DesignTokens.SystemColors.success : DesignTokens.SystemColors.neutral)
                        
                        Text(originalTodo.isCompleted ? "已完成" : "待完成")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.TextColors.secondary)
                    }
                }
                
                Text("创建时间：\(originalTodo.createdAt, formatter: dateFormatter)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.TextColors.secondary)
                
                if originalTodo.ageInDays > 0 {
                    Text("已创建 \(originalTodo.ageInDays) 天")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.TextColors.secondary)
                }
            }
        } header: {
            Text("任务信息")
                .font(DesignTokens.Typography.caption)
                .accessibilityLabel("任务信息部分")
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
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
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

