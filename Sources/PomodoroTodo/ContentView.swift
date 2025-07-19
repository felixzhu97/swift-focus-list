import SwiftUI

struct ContentView: View {
    @StateObject private var todoManager = TodoManager()
    @StateObject private var pomodoroTimer = PomodoroTimer()
    @StateObject private var accessibilityManager = AccessibilityManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PomodoroView(timer: pomodoroTimer, accessibilityManager: accessibilityManager)
                .tabItem {
                    Image(systemName: "timer")
                    Text("番茄钟")
                }
                .tag(0)
                .accessibilityLabel("番茄钟计时器")
                .accessibilityHint("切换到番茄钟计时器界面")
            
            TodoListView(todoManager: todoManager, accessibilityManager: accessibilityManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("待办事项")
                }
                .tag(1)
                .accessibilityLabel("待办事项列表")
                .accessibilityHint("切换到待办事项管理界面")
        }
        .accentColor(ThemeManager.SystemColors.accent)
        .onAppear {
            // Connect accessibility manager to timer for announcements
            pomodoroTimer.accessibilityManager = accessibilityManager
        }
    }
}

#Preview {
    ContentView()
}