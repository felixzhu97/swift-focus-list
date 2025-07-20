import SwiftUI

struct SwipeActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    var role: ButtonRole?
    let action: () -> Void
    
    var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
        }
        .tint(color)
        .accessibilityLabel(title)
        .accessibilityHint("双击执行\(title)操作")
    }
}

#Preview {
    VStack {
        SwipeActionButton(
            title: "完成",
            systemImage: "checkmark",
            color: .green,
            action: {}
        )
        
        SwipeActionButton(
            title: "删除",
            systemImage: "trash",
            color: .red,
            role: .destructive,
            action: {}
        )
        
        SwipeActionButton(
            title: "编辑",
            systemImage: "pencil",
            color: .blue,
            action: {}
        )
    }
    .padding()
}