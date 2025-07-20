import SwiftUI
import UserNotifications

#if canImport(UIKit)
import UIKit
#endif

@main
struct PomodoroTodoApp: App {
    @StateObject private var appDelegate = AppDelegate()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.pomodoroTimer)
                .onAppear {
                    requestNotificationPermissions()
                }
        }
    }
    
    /// Requests notification permissions for timer completion alerts
    private func requestNotificationPermissions() {
        #if os(iOS)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        
        // Set up notification categories
        setupNotificationCategories()
        #endif
    }
    
    /// Sets up notification categories for timer-related notifications
    private func setupNotificationCategories() {
        #if os(iOS)
        let timerCompleteCategory = UNNotificationCategory(
            identifier: "TIMER_COMPLETE",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        let backgroundExpirationCategory = UNNotificationCategory(
            identifier: "BACKGROUND_EXPIRATION",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            timerCompleteCategory,
            backgroundExpirationCategory
        ])
        #endif
    }
}

// MARK: - App Delegate for Background Handling

@MainActor
class AppDelegate: ObservableObject {
    let pomodoroTimer = PomodoroTimer()
    
    init() {
        setupAppLifecycleObservers()
    }
    
    /// Sets up observers for app lifecycle events
    private func setupAppLifecycleObservers() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pomodoroTimer.handleAppDidEnterBackground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pomodoroTimer.handleAppWillEnterForeground()
        }
        #endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}