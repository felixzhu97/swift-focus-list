import SwiftUI
import Foundation

struct TodoItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var priority: Priority = .medium
    var createdAt = Date()
    
    enum Priority: String, CaseIterable, Codable {
        case high = "高"
        case medium = "中"
        case low = "低"
        
        var color: Color {
            return ThemeManager.PriorityColors.color(for: self)
        }
    }
}

class TodoManager: ObservableObject {
    @Published var todos: [TodoItem] = []
    
    private let userDefaults = UserDefaults.standard
    private let todosKey = "SavedTodos"
    
    init() {
        loadTodos()
    }
    
    func addTodo(_ title: String, priority: TodoItem.Priority = .medium) {
        let newTodo = TodoItem(title: title, priority: priority)
        todos.append(newTodo)
        saveTodos()
    }
    
    func toggleTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
            saveTodos()
        }
    }
    
    func deleteTodo(_ todo: TodoItem) {
        todos.removeAll { $0.id == todo.id }
        saveTodos()
    }
    
    func updateTodo(_ todo: TodoItem, title: String, priority: TodoItem.Priority) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].title = title
            todos[index].priority = priority
            saveTodos()
        }
    }
    
    private func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            userDefaults.set(encoded, forKey: todosKey)
        }
    }
    
    private func loadTodos() {
        if let data = userDefaults.data(forKey: todosKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            todos = decoded
        }
    }
}

struct TodoListView: View {
    @ObservedObject var todoManager: TodoManager
    @State private var newTodoTitle = ""
    @State private var selectedPriority: TodoItem.Priority = .medium
    @State private var showingAddTodo = false
    @State private var editingTodo: TodoItem?
    @ScaledMetric private var screenPadding: CGFloat = ThemeManager.Spacing.screenMargin
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 添加新任务
                HStack(spacing: ThemeManager.Spacing.small) {
                    TextField("添加新任务...", text: $newTodoTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(ThemeManager.Typography.body)
                    
                    Button(action: addTodo) {
                        Image(systemName: "plus.circle.fill")
                            .font(ThemeManager.Typography.sectionTitle)
                            .foregroundColor(ThemeManager.SystemColors.info)
                    }
                    .disabled(newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(screenPadding)
                
                // 任务列表
                List {
                    ForEach(todoManager.todos.sorted(by: { !$0.isCompleted && $1.isCompleted })) { todo in
                        TodoRowView(
                            todo: todo,
                            onToggle: { todoManager.toggleTodo(todo) },
                            onEdit: { editingTodo = todo },
                            onDelete: { todoManager.deleteTodo(todo) }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("待办事项")
            .sheet(item: $editingTodo) { todo in
                EditTodoView(
                    todo: todo,
                    todoManager: todoManager,
                    isPresented: Binding(
                        get: { editingTodo != nil },
                        set: { if !$0 { editingTodo = nil } }
                    )
                )
            }
        }
    }
    
    private func addTodo() {
        let title = newTodoTitle.trimmingCharacters(in: .whitespaces)
        if !title.isEmpty {
            todoManager.addTodo(title, priority: selectedPriority)
            newTodoTitle = ""
        }
    }
}

struct TodoRowView: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @ScaledMetric private var rowVerticalPadding: CGFloat = ThemeManager.Spacing.componentPadding / 2
    @ScaledMetric private var priorityHorizontalPadding: CGFloat = ThemeManager.Spacing.componentPadding
    @ScaledMetric private var priorityVerticalPadding: CGFloat = ThemeManager.Spacing.componentPadding / 4
    @ScaledMetric private var priorityCornerRadius: CGFloat = ThemeManager.Spacing.componentPadding
    @ScaledMetric private var contentSpacing: CGFloat = ThemeManager.Spacing.componentPadding / 2
    
    var body: some View {
        HStack(spacing: ThemeManager.Spacing.small) {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? ThemeManager.SystemColors.success : ThemeManager.SystemColors.neutral)
                    .font(ThemeManager.Typography.sectionTitle)
            }
            
            VStack(alignment: .leading, spacing: contentSpacing) {
                Text(todo.title)
                    .font(ThemeManager.Typography.headline)
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? ThemeManager.TextColors.secondary : ThemeManager.TextColors.primary)
                
                HStack(spacing: ThemeManager.Spacing.small) {
                    Text(todo.priority.rawValue)
                        .font(ThemeManager.Typography.caption)
                        .padding(.horizontal, priorityHorizontalPadding)
                        .padding(.vertical, priorityVerticalPadding)
                        .background(todo.priority.color.opacity(0.2))
                        .foregroundColor(todo.priority.color)
                        .cornerRadius(priorityCornerRadius)
                    
                    Spacer()
                    
                    Text(todo.createdAt, style: .date)
                        .font(ThemeManager.Typography.caption)
                        .foregroundColor(ThemeManager.TextColors.secondary)
                }
            }
            
            Spacer()
            
            Menu {
                Button("编辑", action: onEdit)
                Button("删除", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .font(ThemeManager.Typography.body)
                    .foregroundColor(ThemeManager.SystemColors.neutral)
            }
        }
        .padding(.vertical, rowVerticalPadding)
    }
}

struct EditTodoView: View {
    let todo: TodoItem
    let todoManager: TodoManager
    @Binding var isPresented: Bool
    
    @State private var title: String
    @State private var priority: TodoItem.Priority
    
    init(todo: TodoItem, todoManager: TodoManager, isPresented: Binding<Bool>) {
        self.todo = todo
        self.todoManager = todoManager
        self._isPresented = isPresented
        self._title = State(initialValue: todo.title)
        self._priority = State(initialValue: todo.priority)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("任务标题", text: $title)
                        .font(ThemeManager.Typography.body)
                } header: {
                    Text("任务内容")
                        .font(ThemeManager.Typography.caption)
                }
                
                Section {
                    Picker("优先级", selection: $priority) {
                        ForEach(TodoItem.Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue)
                                .font(ThemeManager.Typography.body)
                                .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                } header: {
                    Text("优先级")
                        .font(ThemeManager.Typography.caption)
                }
            }
            .navigationTitle("编辑任务")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                    .font(ThemeManager.Typography.button)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        todoManager.updateTodo(todo, title: title, priority: priority)
                        isPresented = false
                    }
                    .font(ThemeManager.Typography.button)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}