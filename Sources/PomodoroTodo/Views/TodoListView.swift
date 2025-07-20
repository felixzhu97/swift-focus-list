import SwiftUI

struct TodoListView: View {
    @ObservedObject var todoManager: TodoManager
    @ObservedObject var accessibilityManager: AccessibilityManager
    @State private var editingTodo: TodoItem?
    @State private var showingAddTodo = false
    
    var body: some View {
        NavigationView {
            ResponsiveTodoLayout {
                TodoContentView(
                    todoManager: todoManager,
                    editingTodo: $editingTodo,
                    accessibilityManager: accessibilityManager
                )
            }
            .navigationTitle("待办事项")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddTodo = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .accessibilityLabel("添加新任务")
                            .accessibilityHint("双击打开添加任务表单")
                    }
                }
            }
            .sheet(isPresented: $showingAddTodo) {
                AddTodoView(
                    todoManager: todoManager,
                    accessibilityManager: accessibilityManager,
                    isPresented: $showingAddTodo
                )
            }
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
}

// MARK: - Supporting Views

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
        .listStyle(platformListStyle)
        .refreshable {
            await handleRefresh()
        }
    }
    
    // MARK: - Computed Properties
    
    private var platformListStyle: some ListStyle {
        #if os(iOS)
        return .insetGrouped
        #else
        return .sidebar
        #endif
    }
    
    // MARK: - Action Handlers
    
    private func handleRefresh() async {
        // Trigger immediate feedback
        accessibilityManager.triggerHapticFeedback(for: .buttonTap)
        
        // Brief delay for visual feedback
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        // Announce completion
        accessibilityManager.announceStateChange("列表已刷新")
    }
}

