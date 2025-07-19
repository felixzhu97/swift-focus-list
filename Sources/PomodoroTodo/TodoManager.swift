import SwiftUI
import Foundation

// MARK: - View Extensions for Conditional Modifiers

extension View {
    /// Applies a transformation to the view conditionally
    func apply<T: View>(@ViewBuilder _ transform: (Self) -> T) -> T {
        transform(self)
    }
}

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
    
    // Computed properties for organizing todos
    private var activeTodos: [TodoItem] {
        todoManager.todos.filter { !$0.isCompleted }
            .sorted { todo1, todo2 in
                // Sort by priority first (high -> medium -> low), then by creation date
                if todo1.priority != todo2.priority {
                    return todo1.priority.rawValue < todo2.priority.rawValue
                }
                return todo1.createdAt < todo2.createdAt
            }
    }
    
    private var completedTodos: [TodoItem] {
        todoManager.todos.filter { $0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt } // Most recently completed first
    }
    
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
                    // Enhanced empty state with helpful guidance
                    VStack(spacing: ThemeManager.Spacing.medium) {
                        Image(systemName: "checklist")
                            .font(.system(size: 64))
                            .foregroundColor(ThemeManager.SystemColors.neutral)
                        
                        Text("开始您的高效之旅")
                            .font(ThemeManager.Typography.sectionTitle)
                            .foregroundColor(ThemeManager.TextColors.primary)
                        
                        VStack(spacing: ThemeManager.Spacing.small) {
                            Text("还没有任务？没关系！")
                                .font(ThemeManager.Typography.headline)
                                .foregroundColor(ThemeManager.TextColors.secondary)
                            
                            Text("在上方输入框中添加您的第一个任务，开始使用番茄工作法提高效率")
                                .font(ThemeManager.Typography.body)
                                .foregroundColor(ThemeManager.TextColors.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, ThemeManager.Spacing.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: ThemeManager.Spacing.small) {
                            HStack {
                                Image(systemName: "arrow.left")
                                    .foregroundColor(ThemeManager.SystemColors.info)
                                Text("向左滑动完成任务")
                                    .font(ThemeManager.Typography.caption)
                                    .foregroundColor(ThemeManager.TextColors.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "arrow.right")
                                    .foregroundColor(ThemeManager.SystemColors.warning)
                                Text("向右滑动编辑或删除")
                                    .font(ThemeManager.Typography.caption)
                                    .foregroundColor(ThemeManager.TextColors.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "arrow.down")
                                    .foregroundColor(ThemeManager.SystemColors.neutral)
                                Text("下拉刷新列表")
                                    .font(ThemeManager.Typography.caption)
                                    .foregroundColor(ThemeManager.TextColors.secondary)
                            }
                        }
                        .padding(.top, ThemeManager.Spacing.medium)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("任务列表为空，开始您的高效之旅")
                    .accessibilityHint("使用上方的输入框添加您的第一个任务，支持滑动手势操作和下拉刷新")
                } else {
                    List {
                        // Active tasks section
                        if !activeTodos.isEmpty {
                            Section {
                                ForEach(activeTodos) { todo in
                                    TodoRowView(
                                        todo: todo,
                                        onToggle: { todoManager.toggleTodo(todo) },
                                        onEdit: { editingTodo = todo },
                                        onDelete: { todoManager.deleteTodo(todo) },
                                        accessibilityManager: accessibilityManager
                                    )
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            accessibilityManager.triggerHapticFeedback(for: .todoComplete)
                                            todoManager.toggleTodo(todo)
                                            accessibilityManager.announceStateChange("任务已完成")
                                        } label: {
                                            Label("完成", systemImage: "checkmark")
                                        }
                                        .tint(.green)
                                        .accessibilityLabel("完成任务")
                                        .accessibilityHint("标记任务为已完成")
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            accessibilityManager.triggerHapticFeedback(for: .error)
                                            todoManager.deleteTodo(todo)
                                            accessibilityManager.announceStateChange("任务已删除")
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                        .accessibilityLabel("删除任务")
                                        .accessibilityHint("永久删除此任务")
                                        
                                        Button {
                                            editingTodo = todo
                                            accessibilityManager.announceStateChange("打开编辑界面")
                                        } label: {
                                            Label("编辑", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                        .accessibilityLabel("编辑任务")
                                        .accessibilityHint("编辑任务标题和优先级")
                                    }
                                }
                            } header: {
                                Text("待完成 (\(activeTodos.count))")
                                    .headerProminence(.increased)
                                    .accessibilityLabel("待完成任务，共\(activeTodos.count)个")
                            }
                        }
                        
                        // Completed tasks section
                        if !completedTodos.isEmpty {
                            Section {
                                ForEach(completedTodos) { todo in
                                    TodoRowView(
                                        todo: todo,
                                        onToggle: { todoManager.toggleTodo(todo) },
                                        onEdit: { editingTodo = todo },
                                        onDelete: { todoManager.deleteTodo(todo) },
                                        accessibilityManager: accessibilityManager
                                    )
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            accessibilityManager.triggerHapticFeedback(for: .todoComplete)
                                            todoManager.toggleTodo(todo)
                                            accessibilityManager.announceStateChange("任务已标记为未完成")
                                        } label: {
                                            Label("未完成", systemImage: "arrow.uturn.backward")
                                        }
                                        .tint(.orange)
                                        .accessibilityLabel("标记为未完成")
                                        .accessibilityHint("将已完成任务标记为未完成")
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            accessibilityManager.triggerHapticFeedback(for: .error)
                                            todoManager.deleteTodo(todo)
                                            accessibilityManager.announceStateChange("任务已删除")
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                        .accessibilityLabel("删除任务")
                                        .accessibilityHint("永久删除此任务")
                                        
                                        Button {
                                            editingTodo = todo
                                            accessibilityManager.announceStateChange("打开编辑界面")
                                        } label: {
                                            Label("编辑", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                        .accessibilityLabel("编辑任务")
                                        .accessibilityHint("编辑任务标题和优先级")
                                    }
                                }
                            } header: {
                                Text("已完成 (\(completedTodos.count))")
                                    .headerProminence(.increased)
                                    .accessibilityLabel("已完成任务，共\(completedTodos.count)个")
                            }
                        }
                    }
                    .apply { list in
                        #if os(iOS)
                        list.listStyle(.insetGrouped)
                        #else
                        list.listStyle(.sidebar)
                        #endif
                    }
                    .accessibilityLabel("待办事项列表")
                    .accessibilityHint("包含 \(todoManager.todos.count) 个任务，\(activeTodos.count) 个未完成，支持滑动操作")
                    .refreshable {
                        // Enhanced pull-to-refresh with haptic feedback
                        accessibilityManager.triggerHapticFeedback(for: .buttonTap)
                        // Simulate refresh delay for better UX
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
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
    
    // MARK: - Scaled Metrics for Dynamic Type Support
    @ScaledMetric private var rowVerticalPadding: CGFloat = ThemeManager.Spacing.componentPadding / 2
    @ScaledMetric private var priorityHorizontalPadding: CGFloat = ThemeManager.Spacing.componentPadding
    @ScaledMetric private var priorityVerticalPadding: CGFloat = ThemeManager.Spacing.componentPadding / 4
    @ScaledMetric private var priorityCornerRadius: CGFloat = ThemeManager.Spacing.componentPadding
    @ScaledMetric private var contentSpacing: CGFloat = ThemeManager.Spacing.componentPadding / 2
    @ScaledMetric private var priorityIconSize: CGFloat = 16
    @ScaledMetric private var checkmarkSize: CGFloat = 24
    
    // MARK: - Animation State
    @State private var isAnimatingCompletion = false
    
    // MARK: - Priority SF Symbol Mapping
    private var prioritySymbol: String {
        switch todo.priority {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "minus.circle.fill"
        case .low: return "checkmark.circle.fill"
        }
    }
    
    // MARK: - Accessibility Computed Properties
    private var todoAccessibilityLabel: String {
        let priorityText = switch todo.priority {
        case .high: "高优先级"
        case .medium: "中优先级"
        case .low: "低优先级"
        }
        
        let statusText = todo.isCompleted ? "已完成" : "未完成"
        let dateText = DateFormatter.localizedString(from: todo.createdAt, dateStyle: .short, timeStyle: .none)
        return "\(priorityText)任务：\(todo.title)，\(statusText)，创建于\(dateText)"
    }
    
    private var checkmarkAccessibilityLabel: String {
        todo.isCompleted ? "标记为未完成" : "标记为完成"
    }
    
    private var priorityAccessibilityLabel: String {
        let priorityText = switch todo.priority {
        case .high: "高优先级"
        case .medium: "中优先级"
        case .low: "低优先级"
        }
        return "任务优先级：\(priorityText)"
    }
    
    var body: some View {
        HStack(spacing: ThemeManager.Spacing.small) {
            // Enhanced Checkmark Button with Animation
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isAnimatingCompletion = true
                }
                
                accessibilityManager.triggerHapticFeedback(for: .todoComplete)
                onToggle()
                
                let statusText = todo.isCompleted ? "任务已标记为未完成" : "任务已完成"
                accessibilityManager.announceStateChange(statusText)
                
                // Reset animation state
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimatingCompletion = false
                }
            }) {
                ZStack {
                    // Background circle for better touch target
                    Circle()
                        .fill(Color.clear)
                        .frame(width: accessibilityManager.minimumTouchTargetSize(), 
                               height: accessibilityManager.minimumTouchTargetSize())
                    
                    // Animated checkmark
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: checkmarkSize, weight: .medium))
                        .foregroundColor(todo.isCompleted ? ThemeManager.SystemColors.success : ThemeManager.SystemColors.neutral)
                        .scaleEffect(isAnimatingCompletion ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: todo.isCompleted)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimatingCompletion)
                }
            }
            .accessibilityLabel(checkmarkAccessibilityLabel)
            .accessibilityHint("双击切换任务完成状态")
            .accessibilityAddTraits(todo.isCompleted ? [.isSelected] : [])
            
            // Enhanced Content with Priority Indicator
            VStack(alignment: .leading, spacing: contentSpacing) {
                // Task Title with Completion Animation
                HStack(spacing: ThemeManager.Spacing.small / 2) {
                    Text(todo.title)
                        .font(ThemeManager.Typography.headline)
                        .strikethrough(todo.isCompleted)
                        .foregroundColor(todo.isCompleted ? ThemeManager.TextColors.secondary : ThemeManager.TextColors.primary)
                        .animation(.easeInOut(duration: 0.2), value: todo.isCompleted)
                    
                    Spacer()
                }
                .accessibilityLabel("任务标题：\(todo.title)")
                .accessibilityAddTraits(todo.isCompleted ? [.isSelected] : [])
                
                // Enhanced Priority and Date Row
                HStack(spacing: ThemeManager.Spacing.small) {
                    // Priority Indicator with SF Symbol
                    HStack(spacing: ThemeManager.Spacing.small / 2) {
                        Image(systemName: prioritySymbol)
                            .font(.system(size: priorityIconSize, weight: .medium))
                            .foregroundColor(todo.priority.color)
                            .accessibilityHidden(true) // Hide from VoiceOver since we have text label
                        
                        Text(todo.priority.rawValue)
                            .font(ThemeManager.Typography.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, priorityHorizontalPadding)
                    .padding(.vertical, priorityVerticalPadding)
                    .background(
                        RoundedRectangle(cornerRadius: priorityCornerRadius)
                            .fill(todo.priority.color.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: priorityCornerRadius)
                                    .stroke(todo.priority.color.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(priorityAccessibilityLabel)
                    
                    Spacer()
                    
                    // Creation Date
                    Text(todo.createdAt, style: .date)
                        .font(ThemeManager.Typography.caption)
                        .foregroundColor(ThemeManager.TextColors.secondary)
                        .accessibilityLabel("创建日期：\(DateFormatter.localizedString(from: todo.createdAt, dateStyle: .medium, timeStyle: .none))")
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("任务内容：\(todo.title)，\(priorityAccessibilityLabel)")
            
            // Enhanced Context Menu with Better Touch Target
            Menu {
                // Edit Action
                Button {
                    onEdit()
                    accessibilityManager.announceStateChange("打开编辑界面")
                } label: {
                    Label("编辑任务", systemImage: "pencil")
                }
                .accessibilityLabel("编辑任务")
                .accessibilityHint("编辑当前任务的标题和优先级")
                
                // Toggle Completion Action
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
                
                // Delete Action
                Button(role: .destructive) {
                    accessibilityManager.triggerHapticFeedback(for: .error)
                    onDelete()
                    accessibilityManager.announceStateChange("任务已删除")
                } label: {
                    Label("删除任务", systemImage: "trash")
                }
                .accessibilityLabel("删除任务")
                .accessibilityHint("永久删除当前任务")
            } label: {
                ZStack {
                    // Background for better touch target
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.clear)
                        .frame(width: accessibilityManager.minimumTouchTargetSize(), 
                               height: accessibilityManager.minimumTouchTargetSize())
                    
                    Image(systemName: "ellipsis")
                        .font(ThemeManager.Typography.body)
                        .foregroundColor(ThemeManager.SystemColors.neutral)
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
        .padding(.vertical, rowVerticalPadding)
        .contentShape(Rectangle()) // Improve tap area
        .accessibilityElement(children: .contain)
        .accessibilityLabel(todoAccessibilityLabel)
        .accessibilityHint("使用完成按钮切换状态，或使用操作菜单进行更多操作")
        // Add context menu to entire row for better accessibility
        .contextMenu {
            Button {
                onEdit()
                accessibilityManager.announceStateChange("打开编辑界面")
            } label: {
                Label("编辑任务", systemImage: "pencil")
            }
            
            Button {
                accessibilityManager.triggerHapticFeedback(for: .todoComplete)
                onToggle()
                let statusText = todo.isCompleted ? "任务已标记为未完成" : "任务已完成"
                accessibilityManager.announceStateChange(statusText)
            } label: {
                Label(todo.isCompleted ? "标记为未完成" : "标记为完成", 
                      systemImage: todo.isCompleted ? "arrow.uturn.backward" : "checkmark")
            }
            
            Divider()
            
            Button(role: .destructive) {
                accessibilityManager.triggerHapticFeedback(for: .error)
                onDelete()
                accessibilityManager.announceStateChange("任务已删除")
            } label: {
                Label("删除任务", systemImage: "trash")
            }
        }
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
        VStack(spacing: 0) {
            // Custom navigation bar
            HStack {
                Button("取消") {
                    accessibilityManager.triggerHapticFeedback(for: .buttonTap)
                    isPresented = false
                    accessibilityManager.announceStateChange("已取消编辑")
                }
                .font(ThemeManager.Typography.button)
                .accessibilityLabel("取消编辑")
                .accessibilityHint("双击取消编辑并关闭界面")
                
                Spacer()
                
                Text("编辑任务")
                    .font(ThemeManager.Typography.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
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
            .padding()
            .background(ThemeManager.BackgroundColors.secondary)
            
            // Form content
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
        .accessibilityLabel("编辑任务表单")
    }
}