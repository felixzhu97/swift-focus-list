import SwiftUI
import Foundation

// MARK: - Supporting Types

struct TodoStats {
    let total: Int
    let active: Int
    let completed: Int
    let highPriority: Int
    
    var completionRate: Double {
        guard total > 0 else { return 0.0 }
        return Double(completed) / Double(total)
    }
    
    var hasHighPriorityTasks: Bool {
        highPriority > 0
    }
}

// MARK: - Error Types

enum TodoError: LocalizedError {
    case saveFailed(Error)
    case loadFailed(Error)
    case invalidInput(String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "保存任务失败"
        case .loadFailed:
            return "加载任务失败"
        case .invalidInput(let message):
            return "输入无效：\(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .saveFailed, .loadFailed:
            return "请检查设备存储空间并重试"
        case .invalidInput:
            return "请检查输入内容并重试"
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
    
    // MARK: - Error Handling
    
    @Published var lastError: TodoError?
    
    // MARK: - Public Methods
    
    func addTodo(_ title: String, priority: TodoItem.Priority = .medium) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { 
            lastError = .invalidInput("任务标题不能为空")
            return 
        }
        
        let newTodo = TodoItem(title: trimmedTitle, priority: priority)
        guard newTodo.isValid else {
            lastError = .invalidInput(newTodo.validationErrors.joined(separator: "，"))
            return
        }
        
        todos.append(newTodo)
        saveTodos()
    }
    
    func toggleTodo(_ todo: TodoItem) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { 
            lastError = .invalidInput("找不到指定的任务")
            return 
        }
        todos[index].isCompleted.toggle()
        saveTodos()
    }
    
    func deleteTodo(_ todo: TodoItem) {
        let originalCount = todos.count
        todos.removeAll { $0.id == todo.id }
        
        guard todos.count < originalCount else {
            lastError = .invalidInput("找不到要删除的任务")
            return
        }
        
        saveTodos()
    }
    
    func updateTodo(_ todo: TodoItem, title: String, priority: TodoItem.Priority) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else {
            lastError = .invalidInput("找不到要更新的任务")
            return
        }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else {
            lastError = .invalidInput("任务标题不能为空")
            return
        }
        
        // Create a temporary todo for validation
        var updatedTodo = todos[index]
        updatedTodo.title = trimmedTitle
        updatedTodo.priority = priority
        
        guard updatedTodo.isValid else {
            lastError = .invalidInput(updatedTodo.validationErrors.joined(separator: "，"))
            return
        }
        
        todos[index] = updatedTodo
        saveTodos()
    }
    
    // MARK: - Computed Properties
    
    var activeTodos: [TodoItem] {
        todos.lazy
            .filter { !$0.isCompleted }
            .sorted { lhs, rhs in
                // Use Comparable conformance for cleaner comparison
                if lhs.priority != rhs.priority {
                    return lhs.priority < rhs.priority
                }
                return lhs.createdAt < rhs.createdAt
            }
    }
    
    var completedTodos: [TodoItem] {
        todos.lazy
            .filter(\.isCompleted)
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Statistics
    
    var todoStats: TodoStats {
        // Use single pass for better performance with large lists
        var activeCount = 0
        var completedCount = 0
        var highPriorityCount = 0
        
        for todo in todos {
            if todo.isCompleted {
                completedCount += 1
            } else {
                activeCount += 1
                if todo.priority == .high {
                    highPriorityCount += 1
                }
            }
        }
        
        return TodoStats(
            total: todos.count,
            active: activeCount,
            completed: completedCount,
            highPriority: highPriorityCount
        )
    }
    
    // MARK: - Private Methods
    
    private func saveTodos() {
        do {
            let encoded = try JSONEncoder().encode(todos)
            userDefaults.set(encoded, forKey: todosKey)
            lastError = nil
        } catch {
            lastError = .saveFailed(error)
            #if DEBUG
            print("Failed to save todos: \(error)")
            #endif
        }
    }
    
    private func loadTodos() {
        guard let data = userDefaults.data(forKey: todosKey) else { 
            todos = []
            return 
        }
        
        do {
            todos = try JSONDecoder().decode([TodoItem].self, from: data)
            lastError = nil
        } catch {
            lastError = .loadFailed(error)
            todos = []
            #if DEBUG
            print("Failed to load todos: \(error)")
            #endif
        }
    }
}