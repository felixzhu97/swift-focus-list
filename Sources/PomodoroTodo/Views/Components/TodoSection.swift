import SwiftUI

struct TodoSection: View {
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
                            handleToggleAction(for: todo)
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
                            handleDeleteAction(for: todo)
                        }
                    )
                    
                    SwipeActionButton(
                        title: "编辑",
                        systemImage: "pencil",
                        color: .blue,
                        action: {
                            handleEditAction(for: todo)
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
    
    // MARK: - Action Handlers
    
    private func handleToggleAction(for todo: TodoItem) {
        accessibilityManager.triggerHapticFeedback(for: .todoComplete)
        todoManager.toggleTodo(todo)
        let message = todo.isCompleted ? "任务已标记为未完成" : "任务已完成"
        accessibilityManager.announceStateChange(message)
    }
    
    private func handleDeleteAction(for todo: TodoItem) {
        accessibilityManager.triggerHapticFeedback(for: .error)
        todoManager.deleteTodo(todo)
        accessibilityManager.announceStateChange("任务已删除")
    }
    
    private func handleEditAction(for todo: TodoItem) {
        editingTodo = todo
        accessibilityManager.announceStateChange("打开编辑界面")
    }
}

#Preview {
    List {
        TodoSection(
            title: "待完成",
            todos: [
                TodoItem(title: "示例任务", priority: .medium),
                TodoItem(title: "另一个任务", priority: .high)
            ],
            editingTodo: .constant(nil),
            todoManager: TodoManager(),
            accessibilityManager: AccessibilityManager()
        )
    }
    #if os(iOS)
    .listStyle(.insetGrouped)
    #else
    .listStyle(.sidebar)
    #endif
}