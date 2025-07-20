import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
#endif

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
            .ifLet(hint) { view, hintText in
                view.accessibilityHint(hintText)
            }
            .ifLet(value) { view, valueText in
                view.accessibilityValue(valueText)
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

// MARK: - Layout Extensions

extension View {
    /// Applies platform-specific styling
    @ViewBuilder
    func platformSpecificStyle() -> some View {
        #if os(iOS)
        self
        #elseif os(macOS)
        self.buttonStyle(.bordered)
        #else
        self
        #endif
    }
    
    /// Applies consistent card styling across the app
    func cardStyle(
        backgroundColor: Color = DesignTokens.BackgroundColors.primary,
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 2
    ) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 1)
    }
    
    /// Applies responsive padding based on device size
    func responsivePadding(_ edges: Edge.Set = .all) -> some View {
        self.padding(edges, DesignTokens.Spacing.screenMargin)
    }
}

// MARK: - Animation Extensions

extension View {
    /// Applies animation with automatic reduced motion support
    @ViewBuilder
    func accessibleAnimation<V: Equatable>(
        _ animation: Animation? = .spring(response: 0.5, dampingFraction: 0.8),
        value: V
    ) -> some View {
        #if os(iOS)
        if UIAccessibility.isReduceMotionEnabled {
            self
        } else {
            if let animation = animation {
                self.animation(animation, value: value)
            } else {
                self
            }
        }
        #else
        if let animation = animation {
            self.animation(animation, value: value)
        } else {
            self
        }
        #endif
    }
    
    /// Modern transition-based animation with automatic accessibility support
    @ViewBuilder
    func accessibleTransition(_ transition: AnyTransition = .opacity) -> some View {
        #if os(iOS)
        if UIAccessibility.isReduceMotionEnabled {
            self
        } else {
            self.transition(transition)
        }
        #else
        self.transition(transition)
        #endif
    }
}