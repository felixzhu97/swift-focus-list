import SwiftUI

struct TimerControlButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    let tint: Color
    let isDisabled: Bool
    let keyboardShortcut: KeyEquivalent?
    let modifiers: EventModifiers
    
    @State private var isPressed: Bool = false
    @State private var isHovered: Bool = false
    @ObservedObject var accessibilityManager: AccessibilityManager
    
    init(
        title: String,
        systemImage: String,
        action: @escaping () -> Void,
        tint: Color = .accentColor,
        isDisabled: Bool = false,
        keyboardShortcut: KeyEquivalent? = nil,
        modifiers: EventModifiers = [],
        accessibilityManager: AccessibilityManager
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
        self.tint = tint
        self.isDisabled = isDisabled
        self.keyboardShortcut = keyboardShortcut
        self.modifiers = modifiers
        self.accessibilityManager = accessibilityManager
    }
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.title2.weight(.medium))
                .labelStyle(.iconOnly)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(tint)
        .disabled(isDisabled)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .frame(
            minWidth: max(44, accessibilityManager.minimumTouchTargetSize()),
            minHeight: max(44, accessibilityManager.minimumTouchTargetSize())
        )
        .keyboardShortcut(keyboardShortcut ?? .space, modifiers: modifiers)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(isHovered && !isDisabled ? 0.85 : (isDisabled ? 0.6 : 1.0))
        .brightness(isPressed && !isDisabled ? -0.1 : 0.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            guard !isDisabled else { return }
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}