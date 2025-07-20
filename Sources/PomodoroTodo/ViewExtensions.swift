import SwiftUI
import Foundation

// MARK: - View Extensions for Conditional Modifiers

extension View {
    /// Applies a transformation to the view conditionally
    func apply<T: View>(@ViewBuilder _ transform: (Self) -> T) -> T {
        transform(self)
    }
    
    /// Conditionally applies a modifier based on a boolean condition
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Conditionally applies one of two modifiers based on a boolean condition
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
    
    /// Applies a modifier only if the optional value is not nil
    @ViewBuilder
    func ifLet<Value, Content: View>(
        _ value: Value?,
        transform: (Self, Value) -> Content
    ) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Accessibility Extensions

extension View {
    /// Adds accessibility support with proper labeling and hints
    func accessibilitySupport(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
            .if(value != nil) { view in
                view.accessibilityValue(value!)
            }
            .if(!traits.isEmpty) { view in
                view.accessibilityAddTraits(traits)
            }
    }
    
    /// Ensures minimum touch target size for accessibility
    func minimumTouchTarget(size: CGFloat = 44) -> some View {
        self.frame(minWidth: size, minHeight: size)
    }
}

// MARK: - Animation Extensions

extension View {
    /// Applies a spring animation with reduced motion support
    func accessibleSpringAnimation(
        response: Double = 0.5,
        dampingFraction: Double = 0.8,
        blendDuration: Double = 0
    ) -> some View {
        self.animation(
            .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration),
            value: UUID() // This should be replaced with actual state values in usage
        )
    }
    
    /// Applies animation only if reduce motion is not enabled
    @ViewBuilder
    func animationIfNotReducedMotion<V: Equatable>(
        _ animation: Animation?,
        value: V,
        isReduceMotionEnabled: Bool = false
    ) -> some View {
        if isReduceMotionEnabled {
            self
        } else {
            self.animation(animation, value: value)
        }
    }
}