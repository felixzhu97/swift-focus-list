import Foundation
import XCTest
@testable import PomodoroTodo

/// Test suite for background timer functionality
class BackgroundTimerTests: XCTestCase {
    
    var timer: PomodoroTimer!
    
    override func setUp() {
        super.setUp()
        timer = PomodoroTimer()
    }
    
    override func tearDown() {
        timer = nil
        super.tearDown()
    }
    
    /// Test that timer state is properly saved when entering background
    func testBackgroundStateSaving() {
        // Given: Timer is running with specific state
        timer.timeRemaining = 1200 // 20 minutes
        timer.currentSession = 3
        timer.isBreakTime = false
        timer.startTimer()
        
        // When: App enters background
        timer.handleAppDidEnterBackground()
        
        // Then: State should be saved to UserDefaults
        let savedData = UserDefaults.standard.data(forKey: "PomodoroTimerState")
        XCTAssertNotNil(savedData, "Timer state should be saved to UserDefaults")
        
        // Verify saved state can be decoded
        if let data = savedData {
            let decoder = JSONDecoder()
            XCTAssertNoThrow(try decoder.decode(PersistentTimerState.self, from: data))
        }
    }
    
    /// Test that timer state is properly restored when returning from background
    func testBackgroundStateRestoration() {
        // Given: Timer was running and went to background
        timer.timeRemaining = 1200 // 20 minutes
        timer.currentSession = 2
        timer.isBreakTime = false
        timer.startTimer()
        timer.handleAppDidEnterBackground()
        
        // Simulate 60 seconds in background
        Thread.sleep(forTimeInterval: 1.0) // Small delay to simulate background time
        
        // When: App returns from background
        timer.handleAppWillEnterForeground()
        
        // Then: Timer should be restored and still running
        XCTAssertTrue(timer.isRunning, "Timer should still be running after foreground return")
        XCTAssertEqual(timer.currentSession, 2, "Session should be preserved")
        XCTAssertFalse(timer.isBreakTime, "Break state should be preserved")
    }
    
    /// Test timer completion during background
    func testTimerCompletionInBackground() {
        // Given: Timer with very little time remaining
        timer.timeRemaining = 1 // 1 second
        timer.currentSession = 1
        timer.isBreakTime = false
        timer.startTimer()
        timer.handleAppDidEnterBackground()
        
        // Simulate longer background time than remaining
        Thread.sleep(forTimeInterval: 2.0)
        
        // When: App returns from background
        let expectation = XCTestExpectation(description: "Timer completion")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Then: Timer should have completed and switched to break
            XCTAssertTrue(self.timer.isBreakTime, "Should have switched to break time")
            XCTAssertEqual(self.timer.currentSession, 1, "Session should remain same until break completes")
            expectation.fulfill()
        }
        
        timer.handleAppWillEnterForeground()
        wait(for: [expectation], timeout: 2.0)
    }
    
    /// Test formatted time display
    func testFormattedTimeDisplay() {
        // Test various time values
        timer.timeRemaining = 1500 // 25:00
        XCTAssertEqual(timer.formattedTime, "25:00")
        
        timer.timeRemaining = 65 // 01:05
        XCTAssertEqual(timer.formattedTime, "01:05")
        
        timer.timeRemaining = 0 // 00:00
        XCTAssertEqual(timer.formattedTime, "00:00")
    }
    
    /// Test progress calculation
    func testProgressCalculation() {
        // Test work session progress
        timer.isBreakTime = false
        timer.timeRemaining = 1500 // 25 minutes (full work session)
        XCTAssertEqual(timer.progress, 0.0, accuracy: 0.01)
        
        timer.timeRemaining = 750 // 12.5 minutes (half work session)
        XCTAssertEqual(timer.progress, 0.5, accuracy: 0.01)
        
        timer.timeRemaining = 0 // Complete
        XCTAssertEqual(timer.progress, 1.0, accuracy: 0.01)
        
        // Test break session progress
        timer.isBreakTime = true
        timer.currentSession = 1 // Short break
        timer.timeRemaining = 300 // 5 minutes (full short break)
        XCTAssertEqual(timer.progress, 0.0, accuracy: 0.01)
        
        timer.timeRemaining = 150 // 2.5 minutes (half short break)
        XCTAssertEqual(timer.progress, 0.5, accuracy: 0.01)
    }
}

/// Mock struct to test PersistentTimerState (since it's private)
private struct PersistentTimerState: Codable {
    let timeRemaining: Int
    let isRunning: Bool
    let currentSession: Int
    let isBreakTime: Bool
    let backgroundStartTime: Date?
}

// MARK: - Manual Test Instructions

/*
 To manually test background timer functionality:
 
 1. Build and run the app on a physical device
 2. Start a timer with a few minutes remaining
 3. Press home button to background the app
 4. Wait 30-60 seconds
 5. Return to the app
 6. Verify the timer shows the correct remaining time
 
 For background expiration testing:
 1. Start a timer
 2. Background the app for 10+ minutes
 3. Check for notification about timer pause
 4. Return to app and verify state
 
 For completion testing:
 1. Start timer with 30 seconds remaining
 2. Background the app immediately
 3. Wait for completion notification
 4. Return to app and verify session advanced
 */