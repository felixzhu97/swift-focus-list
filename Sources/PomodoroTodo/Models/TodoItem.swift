import SwiftUI
import Foundation

// MARK: - Validation Protocol

protocol Validatable {
    var isValid: Bool { get }
    var validationErrors: [String] { get }
}

struct TodoItem: Identifiable, Codable, Validatable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var priority: Priority = .medium
    var createdAt = Date()
    
    // MARK: - Validation
    
    var isValid: Bool {
        validationErrors.isEmpty
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            errors.append("任务标题不能为空")
        }
        
        if trimmedTitle.count > 200 {
            errors.append("任务标题不能超过200个字符")
        }
        
        if createdAt > Date() {
            errors.append("创建时间不能是未来时间")
        }
        
        return errors
    }
    
    // MARK: - Computed Properties
    
    /// Returns a cleaned version of the title
    var cleanTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Returns the age of the todo item in days
    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
    
    /// Returns true if the todo was created today
    var isCreatedToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }
    
    enum Priority: String, CaseIterable, Codable, Comparable {
        case high = "高"
        case medium = "中"
        case low = "低"
        
        // MARK: - Computed Properties
        
        var color: Color {
            DesignTokens.PriorityColors.color(for: self)
        }
        
        var sortOrder: Int {
            switch self {
            case .high: return 0
            case .medium: return 1
            case .low: return 2
            }
        }
        
        var accessibilityLabel: String {
            "\(rawValue)优先级"
        }
        
        var systemImage: String {
            switch self {
            case .high: return "exclamationmark.triangle.fill"
            case .medium: return "minus.circle.fill"
            case .low: return "checkmark.circle.fill"
            }
        }
        
        // MARK: - Comparable Conformance
        
        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.sortOrder < rhs.sortOrder
        }
        
        // MARK: - Convenience Methods
        
        /// Returns the next higher priority level, or nil if already at highest
        var higherPriority: Priority? {
            switch self {
            case .low: return .medium
            case .medium: return .high
            case .high: return nil
            }
        }
        
        /// Returns the next lower priority level, or nil if already at lowest
        var lowerPriority: Priority? {
            switch self {
            case .high: return .medium
            case .medium: return .low
            case .low: return nil
            }
        }
    }
}