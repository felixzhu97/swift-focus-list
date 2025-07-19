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
    @ObservedObject var accessibilityManager: AccessibilityManager
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
                        .accessibilityLabel("新任务标题输入框")
                        .accessibilityHint("输入要添加的新任务标题")
                    
                    Button(action: {
                        addTodo()
                        accessibilityManager.triggerHapticFeedback(for: .success)
                        if !newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                            accessibilityManager.announceStateChange("新任务已添加")
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(ThemeManager.Typography.sectionTitle)
                            .foregroundColor(ThemeManager.SystemColors.info)
                    }
                    .disabled(newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityLabel("添加新任务")
                    .accessibilityHint("双击添加输入的新任务到列表")
                    .frame(minWidth: accessibilityManager.minimumTouchTargetSize(), minHeight: accessibilityManager.minimumTouchTargetSize())
                }
                .padding(screenPadding)
                
                // 任务列表
                if todoManager.todos.isEmpty {
                    VStack(spacing: ThemeManager.Spacing.medium) {
                        Image(systemName: "checklist")
                            .font(.system(size: 48))
                            .foregroundColor(ThemeManager.SystemColors.neutral)
                        
                        Text("还没有任务")
                            .font(ThemeManager.Typography.headline)
                            .foregroundColor(ThemeManager.TextColors.secondary)
                        
                        Text("在上方输入框中添加您的第一个任务")
                            .font(ThemeManager.Typography.body)
                            .foregroundColor(ThemeManager.TextColors.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("任务列表为空")
                    .accessibilityHint("使用上方的输入框添加您的第一个任务")
                } else {
                    List {
                        ForEach(todoManager.todos.sorted(by: { !$0.isCompleted && $1.isCompleted })) { todo in
                            TodoRowView(
                                todo: todo,
                                onToggle: { todoManager.toggleTodo(todo) },
                                onEdit: { editingTodo = todo },
                                onDelete: { todoManager.deleteTodo(todo) },
                                accessibilityManager: accessibilityManager
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                    .accessibilityLabel("待办事项列表")
                    .accessibilityHint("包含 \(todoManager.todos.count) 个任务，\(todoManager.todos.filter { !$0.isCompleted }.count) 个未完成")
                    .refreshable {
                        // Add pull-to-refresh accessibility announcement
                        accessibilityManager.announceStateChange("列表已刷新")
                    }
                }
            }
            .navigationTitle("待办事项")
            .accessibilityElement(children: .contain)
            .accessibilityLabel("待办事项管理界面")
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
    let accessibilityManager: AccessibilityManager
    @ScaledMetric private var rowVerticalPadding: CGFloat = ThemeManager.Spacing.componentPadding / 2
    @ScaledMetric private var priorityHorizontalPadding: CGFloat = ThemeManager.Spacing.componentPadding
    @ScaledMetric private var priorityVerticalPadding: CGFloat = ThemeManager.Spacing.componentPadding / 4
    @ScaledMetric private var priorityCornerRadius: CGFloat = ThemeManager.Spacing.componentPadding
    @ScaledMetric private var contentSpacing: CGFloat = ThemeManager.Spacing.componentPadding / 2
    
    // MARK: - Accessibility Computed Properties
    
    private var todoAccessibilityLabel: String {
        let priorityText = switch todo.priority {
        case .high: "高优先级"
        case .medium: "中优先级"
        case .low: "低优先级"
        }
        
        let statusText = todo.isCompleted ? "已完成" : "未完成"
        return "\(priorityText)任务：\(todo.title)，\(statusText)"
    }
    
    var body: some View {
        HStack(spacing: ThemeManager.Spacing.small) {
            Button(action: {
                accessibilityManager.triggerHapticFeedback(for: .todoComplete)
                onToggle()
                let statusText = todo.isCompleted ? "任务已标记为未完成" : "任务已完成"
                accessibilityManager.announceStateChange(statusText)
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? ThemeManager.SystemColors.success : ThemeManager.SystemColors.neutral)
                    .font(ThemeManager.Typography.sectionTitle)
            }
            .accessibilityLabel(todo.isCompleted ? "标记为未完成" : "标记为完成")
            .accessibilityHint("双击切换任务完成状态")
            .frame(minWidth: accessibilityManager.minimumTouchTargetSize(), minHeight: accessibilityManager.minimumTouchTargetSize())
            
            VStack(alignment: .leading, spacing: contentSpacing) {
                Text(todo.title)
                    .font(ThemeManager.Typography.headline)
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? ThemeManager.TextColors.secondary : ThemeManager.TextColors.primary)
                    .accessibilityLabel("任务标题：\(todo.title)")
                
                HStack(spacing: ThemeManager.Spacing.small) {
                    Text(todo.priority.rawValue)
                        .font(ThemeManager.Typography.caption)
                        .padding(.horizontal, priorityHorizontalPadding)
                        .padding(.vertical, priorityVerticalPadding)
                        .background(todo.priority.color.opacity(0.2))
                        .foregroundColor(todo.priority.color)
                        .cornerRadius(priorityCornerRadius)
                        .accessibilityLabel("优先级：\(todo.priority.rawValue)")
                    
                    Spacer()
                    
                    Text(todo.createdAt, style: .date)
                        .font(ThemeManager.Typography.caption)
                        .foregroundColor(ThemeManager.TextColors.secondary)
                        .accessibilityLabel("创建日期：\(todo.createdAt, style: .date)")
                }
                .accessibilityElement(children: .combine)
            }
            .accessibilityElement(children: .combine)
            
            Spacer()
            
            Menu {
                Button("编辑") {
                    onEdit()
                    accessibilityManager.announceStateChange("打开编辑界面")
                }
                .accessibilityLabel("编辑任务")
                .accessibilityHint("编辑当前任务的标题和优先级")
                
                Button("删除", role: .destructive) {
                    accessibilityManager.triggerHapticFeedback(for: .error)
                    onDelete()
                    accessibilityManager.announceStateChange("任务已删除")
                }
                .accessibilityLabel("删除任务")
                .accessibilityHint("永久删除当前任务")
            } label: {
                Image(systemName: "ellipsis")
                    .font(ThemeManager.Typography.body)
                    .foregroundColor(ThemeManager.SystemColors.neutral)
            }
            .accessibilityLabel("任务操作菜单")
            .accessibilityHint("双击打开编辑和删除选项")
            .frame(minWidth: accessibilityManager.minimumTouchTargetSize(), minHeight: accessibilityManager.minimumTouchTargetSize())
        }
        .padding(.vertical, rowVerticalPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(todoAccessibilityLabel)
        .accessibilityHint("双击完成状态按钮切换任务状态，或使用操作菜单编辑删除")
    }
}

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
    
    var body: some View {
        NavigationView {
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
            .navigationTitle("编辑任务")
            .accessibilityLabel("编辑任务表单")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        accessibilityManager.triggerHapticFeedback(for: .buttonTap)
                        isPresented = false
                        accessibilityManager.announceStateChange("已取消编辑")
                    }
                    .font(ThemeManager.Typography.button)
                    .accessibilityLabel("取消编辑")
                    .accessibilityHint("双击取消编辑并关闭界面")
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        accessibilityManager.triggerHapticFeedback(for: .success)
                        todoManager.updateTodo(todo, title: title, priority: priority)
                        isPresented = false
                        accessibilityManager.announceStateChange("任务已保存")
                    }
                    .font(ThemeManager.Typography.button)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityLabel("保存任务")
                    .accessibilityHint("双击保存修改并关闭界面")
                }
            }
        }
    }
}