import SwiftUI

struct EditTodoView: View {
    let todo: TodoItem
    let todoManager: TodoManager
    let accessibilityManager: AccessibilityManager
    @Binding var isPresented: Bool
    
    @State private var title: String
    @State private var priority: TodoItem.Priority
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            EditTodoNavigationBar(
                isValidTitle: isValidTitle,
                onCancel: handleCancel,
                onSave: handleSave
            )
            
            EditTodoForm(
                title: $title,
                priority: $priority
            )
        }
        .accessibilityLabel("编辑任务表单")
    }
    
    private func handleCancel() {
        accessibilityManager.triggerHapticFeedback(for: .buttonTap)
        isPresented = false
        accessibilityManager.announceStateChange("已取消编辑")
    }
    
    private func handleSave() {
        accessibilityManager.triggerHapticFeedback(for: .success)
        todoManager.updateTodo(todo, title: title, priority: priority)
        isPresented = false
        accessibilityManager.announceStateChange("任务已保存")
    }
}

// MARK: - Supporting Views

private struct EditTodoNavigationBar: View {
    let isValidTitle: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        HStack {
            Button("取消", action: onCancel)
                .font(ThemeManager.Typography.button)
                .accessibilityLabel("取消编辑")
                .accessibilityHint("双击取消编辑并关闭界面")
            
            Spacer()
            
            Text("编辑任务")
                .font(ThemeManager.Typography.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button("保存", action: onSave)
                .font(ThemeManager.Typography.button)
                .disabled(!isValidTitle)
                .accessibilityLabel("保存任务")
                .accessibilityHint("双击保存修改并关闭界面")
        }
        .padding()
        .background(ThemeManager.BackgroundColors.secondary)
    }
}

private struct EditTodoForm: View {
    @Binding var title: String
    @Binding var priority: TodoItem.Priority
    
    var body: some View {
        Form {
            Section {
                TextField("任务标题", text: $title)
                    .font(ThemeManager.Typography.body)
                    .accessibilityLabel("任务标题输入框")
                    .accessibilityHint("输入或修改任务的标题")
                    .accessibilityValue(title.isEmpty ? "空白" : title)
            } header: {
                Text("任务内容")
                    .font(ThemeManager.Typography.caption)
                    .accessibilityLabel("任务内容部分")
            }
            
            Section {
                Picker("优先级", selection: $priority) {
                    ForEach(TodoItem.Priority.allCases, id: \.self) { priority in
                        Text(priority.rawValue)
                            .font(ThemeManager.Typography.body)
                            .tag(priority)
                            .accessibilityLabel("优先级：\(priority.rawValue)")
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .accessibilityLabel("任务优先级选择器")
                .accessibilityHint("选择任务的优先级：高、中或低")
                .accessibilityValue("当前选择：\(priority.rawValue)")
            } header: {
                Text("优先级")
                    .font(ThemeManager.Typography.caption)
                    .accessibilityLabel("优先级设置部分")
            }
        }
        .apply { form in
            if #available(iOS 16.0, macOS 13.0, *) {
                form.formStyle(.grouped)
            } else {
                form
            }
        }
    }
}