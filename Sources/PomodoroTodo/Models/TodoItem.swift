import SwiftUI
import Foundation

struct TodoItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var priority: Priority = .medium
    var createdAt = Date()
    
    enum Priority: String, CaseIterable, Codable, Comparable {
        case high = "高"
        case medium = "中"
        case low = "低"
        
        // MARK: - Computed Properties
        
        var color: Color {
            ThemeManager.PriorityColors.color(for: self)
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