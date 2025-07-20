import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Responsive Layout Environment

/// Environment key for device information
private struct DeviceInfoKey: EnvironmentKey {
    typealias Value = DeviceInfo
    
    static let defaultValue = DeviceInfo(
        screenSize: CGSize(width: 375, height: 667),
        horizontalSizeClass: UserInterfaceSizeClass.compact,
        verticalSizeClass: UserInterfaceSizeClass.regular,
        deviceType: DeviceType.iPhone,
        orientation: DeviceOrientation.portrait
    )
}

extension EnvironmentValues {
    var deviceInfo: DeviceInfo {
        get { self[DeviceInfoKey.self] }
        set { self[DeviceInfoKey.self] = newValue }
    }
}

// MARK: - Responsive Layout Modifier

struct ResponsiveLayoutModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .environment(\.deviceInfo, createDeviceInfo(geometry: geometry))
        }
    }
    
    private func createDeviceInfo(geometry: GeometryProxy) -> DeviceInfo {
        let screenSize = geometry.size
        let deviceType = determineDeviceType(screenSize: screenSize)
        let orientation = determineOrientation(screenSize: screenSize)
        
        return DeviceInfo(
            screenSize: screenSize,
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            deviceType: deviceType,
            orientation: orientation
        )
    }
    
    private func determineDeviceType(screenSize: CGSize) -> DeviceType {
        #if os(macOS)
        return .mac
        #else
        // Use screen width to determine device type
        let width = max(screenSize.width, screenSize.height)
        if width >= 1024 { // iPad threshold
            return .iPad
        } else {
            return .iPhone
        }
        #endif
    }
    
    private func determineOrientation(screenSize: CGSize) -> DeviceOrientation {
        if screenSize.width > screenSize.height {
            return .landscape
        } else if screenSize.width < screenSize.height {
            return .portrait
        } else {
            return .unknown
        }
    }
}

// MARK: - Responsive Container Views

/// A container that adapts its layout based on screen size and device type
struct ResponsiveContainer<Content: View>: View {
    @Environment(\.deviceInfo) private var deviceInfo
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(deviceInfo.contentPadding)
            .frame(maxWidth: deviceInfo.deviceType == DeviceType.mac ? 800 : .infinity)
    }
}

/// A stack that switches between VStack and HStack based on available space
struct AdaptiveStack<Content: View>: View {
    @Environment(\.deviceInfo) private var deviceInfo
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?
    let content: Content
    
    init(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        if deviceInfo.shouldUseCompactLayout {
            VStack(alignment: horizontalAlignment, spacing: spacing) {
                content
            }
        } else {
            HStack(alignment: verticalAlignment, spacing: spacing) {
                content
            }
        }
    }
}

// MARK: - View Extensions for Responsive Layout

extension View {
    /// Applies responsive layout support to the view
    func responsiveLayout() -> some View {
        self.modifier(ResponsiveLayoutModifier())
    }
    
    /// Applies device-appropriate spacing
    func responsiveSpacing(_ edges: Edge.Set = .all) -> some View {
        ResponsiveSpacingView(content: self, edges: edges)
    }
    
    /// Applies responsive font scaling
    func responsiveFont(_ baseFont: Font) -> some View {
        ResponsiveFontView(content: self, baseFont: baseFont)
    }
}

// MARK: - Responsive Navigation Views

/// A navigation view that adapts between TabView and NavigationSplitView based on device
@available(iOS 16.0, macOS 13.0, *)
struct ResponsiveNavigationView<TimerContent: View, TodoContent: View>: View {
    @Environment(\.deviceInfo) private var deviceInfo
    let timerContent: TimerContent
    let todoContent: TodoContent
    @State private var selectedTab = 0
    @State private var selectedSidebarItem: SidebarItem? = .timer
    
    enum SidebarItem: String, CaseIterable {
        case timer = "timer"
        case todos = "checklist"
        
        var title: String {
            switch self {
            case .timer: return "番茄钟"
            case .todos: return "待办事项"
            }
        }
        
        var icon: String {
            return self.rawValue
        }
    }
    
    init(
        @ViewBuilder timerContent: () -> TimerContent,
        @ViewBuilder todoContent: () -> TodoContent
    ) {
        self.timerContent = timerContent()
        self.todoContent = todoContent()
    }
    
    var body: some View {
        if deviceInfo.shouldUseSidebarNavigation {
            // Use NavigationSplitView for iPad landscape and macOS
            NavigationSplitView {
                SidebarView(selectedItem: $selectedSidebarItem)
            } detail: {
                DetailView(selectedItem: selectedSidebarItem)
            }
        } else {
            // Use TabView for iPhone and iPad portrait
            TabView(selection: $selectedTab) {
                timerContent
                    .tabItem {
                        Label("番茄钟", systemImage: "timer")
                    }
                    .tag(0)
                
                todoContent
                    .tabItem {
                        Label("待办事项", systemImage: "checklist")
                    }
                    .tag(1)
            }
        }
    }
    
    @ViewBuilder
    private func SidebarView(selectedItem: Binding<SidebarItem?>) -> some View {
        List(SidebarItem.allCases, id: \.self, selection: selectedItem) { item in
            NavigationLink(value: item) {
                Label(item.title, systemImage: item.icon)
            }
        }
        .navigationTitle("PomodoroTodo")
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        #endif
    }
    
    @ViewBuilder
    private func DetailView(selectedItem: SidebarItem?) -> some View {
        switch selectedItem {
        case .timer:
            timerContent
        case .todos:
            todoContent
        case .none:
            if #available(iOS 17.0, macOS 14.0, *) {
                ContentUnavailableView(
                    "选择一个功能",
                    systemImage: "sidebar.left",
                    description: Text("从侧边栏选择番茄钟或待办事项")
                )
            } else {
                VStack {
                    Image(systemName: "sidebar.left")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("选择一个功能")
                        .font(.title2)
                    Text("从侧边栏选择番茄钟或待办事项")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

/// Fallback navigation view for older iOS versions
struct LegacyResponsiveNavigationView<TimerContent: View, TodoContent: View>: View {
    let timerContent: TimerContent
    let todoContent: TodoContent
    @State private var selectedTab = 0
    
    init(
        @ViewBuilder timerContent: () -> TimerContent,
        @ViewBuilder todoContent: () -> TodoContent
    ) {
        self.timerContent = timerContent()
        self.todoContent = todoContent()
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            timerContent
                .tabItem {
                    Label("番茄钟", systemImage: "timer")
                }
                .tag(0)
            
            todoContent
                .tabItem {
                    Label("待办事项", systemImage: "checklist")
                }
                .tag(1)
        }
    }
}

/// A responsive timer layout that adapts to different screen sizes
struct ResponsiveTimerLayout<Content: View>: View {
    @Environment(\.deviceInfo) private var deviceInfo
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if deviceInfo.deviceType == .iPhone && deviceInfo.orientation == .landscape {
            // Compact horizontal layout for iPhone landscape
            ScrollView {
                HStack(alignment: .center, spacing: deviceInfo.buttonSpacing) {
                    content
                }
                .padding(deviceInfo.contentPadding)
            }
        } else {
            // Standard vertical layout for other cases
            ScrollView {
                VStack(spacing: deviceInfo.sectionSpacing) {
                    content
                }
                .padding(deviceInfo.contentPadding)
                .frame(maxWidth: deviceInfo.maxContentWidth)
            }
        }
    }
}

/// A responsive todo list layout that optimizes for different screen sizes
struct ResponsiveTodoLayout<Content: View>: View {
    @Environment(\.deviceInfo) private var deviceInfo
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(deviceInfo.contentPadding)
            .frame(maxWidth: deviceInfo.maxContentWidth)
    }
}

// MARK: - Supporting Views

private struct ResponsiveSpacingView<Content: View>: View {
    @Environment(\.deviceInfo) private var deviceInfo
    let content: Content
    let edges: Edge.Set
    
    var body: some View {
        content.padding(deviceInfo.contentPadding)
    }
}

private struct ResponsiveFontView<Content: View>: View {
    @Environment(\.deviceInfo) private var deviceInfo
    let content: Content
    let baseFont: Font
    
    var body: some View {
        content.font(scaledFont)
    }
    
    private var scaledFont: Font {
        switch deviceInfo.deviceType {
        case .iPhone:
            return baseFont
        case .iPad:
            // Slightly larger fonts on iPad
            return baseFont
        case .mac:
            // Standard fonts on Mac
            return baseFont
        }
    }
}

// MARK: - Responsive Layout Utilities

extension View {
    /// Applies responsive timer layout
    func responsiveTimerLayout() -> some View {
        ResponsiveTimerLayout {
            self
        }
    }
    
    /// Applies responsive todo layout
    func responsiveTodoLayout() -> some View {
        ResponsiveTodoLayout {
            self
        }
    }
    
    /// Applies responsive container with max width
    func responsiveContainer() -> some View {
        ResponsiveContainer {
            self
        }
    }
}