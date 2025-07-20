import SwiftUI

struct TodoListView: View {
    @StateObject private var todoManager = TodoManager()
    @ObservedObject var accessibilityManager: AccessibilityManager
    @State private var newTodoTitle = ""
    @State private var selectedPriority: TodoItem.Priority = .medium
    @State private var editingTodo: TodoItem?
    @ScaledMetric private var screenPadding: CGFloat = DesignTokens.Spacing.screenMargin
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                AddTodoSection(
                    newTodoTitle: $newTodoTitle,
                    selectedPriority: $selectedPriority,
                    onAddTodo: addTodo,
                    accessibilityManager: accessibilityManager
                )
                .padding(screenPadding)
                
                TodoContentView(
                    todoManager: todoManager,
                    editingTodo: $editingTodo,
                    accessibilityManager: accessibilityManager
                )
            }
            .navigationTitle("待办事项")
            .sheet(item: $editingTodo) { todo in
                EditTodoView(
                    todo: todo,
                    todoManager: todoManager,
                    accessibilityManager: accessibilityManager,
                    isPresented: Binding(
                        get: { editingTodo != nil },
                        set: { if !$0 { editingTodo = nil } }
                    )
                )
            }
        }
    }
    
    private func addTodo() {
        todoManager.addTodo(newTodoTitle, priority: selectedPriority)
        if !newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            newTodoTitle = ""
            accessibilityManager.triggerHapticFeedback(for: .success)
            accessibilityManager.announceStateChange("新任务已添加")
        }
    }
}

// MARK: - Supporting Views

private struct AddTodoSection: View {
    @Binding var newTodoTitle: String
    @Binding var selectedPriority: TodoItem.Priority
    let onAddTodo: () -> Void
    let accessibilityManager: AccessibilityManager
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            TextField("添加新任务...", text: $newTodoTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(DesignTokens.Typography.body)
                .accessibilityLabel("新任务标题输入框")
                .accessibilityHint("输入要添加的新任务标题")
                .onSubmit {
                    onAddTodo()
                }
            
            Button(action: onAddTodo) {
                Image(systemName: "plus.circle.fill")
                    .font(DesignTokens.Typography.sectionTitle)
                    .foregroundColor(DesignTokens.SystemColors.info)
            }
            .disabled(newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("添加新任务")
            .accessibilityHint("双击添加输入的新任务到列表")
            .frame(minWidth: accessibilityManager.minimumTouchTargetSize(), 
                   minHeight: accessibilityManager.minimumTouchTargetSize())
        }
    }
}

private struct TodoContentView: View {
    @ObservedObject var todoManager: TodoManager
    @Binding var editingTodo: TodoItem?
    let accessibilityManager: AccessibilityManager
    
    var body: some View {
        if todoManager.todos.isEmpty {
            EmptyStateView()
        } else {
            TodoList(
                todoManager: todoManager,
                editingTodo: $editingTodo,
                accessibilityManager: accessibilityManager
            )
        }
    }
}

private struct EmptyStateView: View {
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
                
                Text("在上方输入框中添加您的第一个任务，开始使用番茄工作法提高效率")
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
        .accessibilityHint("使用上方的输入框添加您的第一个任务，支持滑动手势操作和下拉刷新")
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

private struct TodoList: View {
    @ObservedObject var todoManager: TodoManager
    @Binding var editingTodo: TodoItem?
    let accessibilityManager: AccessibilityManager
    
    var body: some View {
        List {
            if !todoManager.activeTodos.isEmpty {
                TodoSection(
                    title: "待完成",
                    todos: todoManager.activeTodos,
                    editingTodo: $editingTodo,
                    todoManager: todoManager,
                    accessibilityManager: accessibilityManager
                )
            }
            
            if !todoManager.completedTodos.isEmpty {
                TodoSection(
                    title: "已完成",
                    todos: todoManager.completedTodos,
                    editingTodo: $editingTodo,
                    todoManager: todoManager,
                    accessibilityManager: accessibilityManager
                )
            }
        }
        .apply { list in
            #if os(iOS)
            list.listStyle(.insetGrouped)
            #else
            list.listStyle(.sidebar)
            #endif
        }
        .refreshable {
            await MainActor.run {
                accessibilityManager.triggerHapticFeedback(for: .buttonTap)
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                accessibilityManager.announceStateChange("列表已刷新")
            }
        }
    }
}

private struct TodoSection: View {
    let title: String
    let todos: [TodoItem]
    @Binding var editingTodo: TodoItem?
    let todoManager: TodoManager
    let accessibilityManager: AccessibilityManager
    
    var body: some View {
        Section {
            ForEach(todos) { todo in
                TodoRowView(
                    todo: todo,
                    onToggle: { todoManager.toggleTodo(todo) },
                    onEdit: { editingTodo = todo },
                    onDelete: { todoManager.deleteTodo(todo) },
                    accessibilityManager: accessibilityManager
                )
                .swipeActions(edge: .leading) {
                    SwipeActionButton(
                        title: todo.isCompleted ? "未完成" : "完成",
                        systemImage: todo.isCompleted ? "arrow.uturn.backward" : "checkmark",
                        color: todo.isCompleted ? .orange : .green,
                        action: {
                            accessibilityManager.triggerHapticFeedback(for: .todoComplete)
                            todoManager.toggleTodo(todo)
                            let message = todo.isCompleted ? "任务已标记为未完成" : "任务已完成"
                            accessibilityManager.announceStateChange(message)
                        }
                    )
                }
                .swipeActions(edge: .trailing) {
                    SwipeActionButton(
                        title: "删除",
                        systemImage: "trash",
                        color: .red,
                        role: .destructive,
                        action: {
                            accessibilityManager.triggerHapticFeedback(for: .error)
                            todoManager.deleteTodo(todo)
                            accessibilityManager.announceStateChange("任务已删除")
                        }
                    )
                    
                    SwipeActionButton(
                        title: "编辑",
                        systemImage: "pencil",
                        color: .blue,
                        action: {
                            editingTodo = todo
                            accessibilityManager.announceStateChange("打开编辑界面")
                        }
                    )
                }
            }
        } header: {
            Text("\(title) (\(todos.count))")
                .headerProminence(.increased)
                .accessibilityLabel("\(title)任务，共\(todos.count)个")
        }
    }
}

private struct SwipeActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    var role: ButtonRole?
    let action: () -> Void
    
    var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
        }
        .tint(color)
        .accessibilityLabel(title)
    }
}