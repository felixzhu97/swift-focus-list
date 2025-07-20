import SwiftUI
import Foundation

// MARK: - View Extensions for Conditional Modifiers

extension View {
    /// Applies a transformation to the view conditionally
    func apply<T: View>(@ViewBuilder _ transform: (Self) -> T) -> T {
        transform(self)
    }
}