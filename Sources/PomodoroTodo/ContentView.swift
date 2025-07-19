import SwiftUI

struct ContentView: View {
    @StateObject private var todoManager = TodoManager()
    @StateObject private var pomodoroTimer = PomodoroTimer()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PomodoroView(timer: pomodoroTimer)
                .tabItem {
                    Image(systemName: "timer")
                    Text("番茄钟")
                }
                .tag(0)
            
            TodoListView(todoManager: todoManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("待办事项")
                }
                .tag(1)
        }
        .accentColor(ThemeManager.SystemColors.accent)
    }
}

#Preview {
    ContentView()
}