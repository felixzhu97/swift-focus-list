import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

/// Manages system accessibility settings detection and updates
@MainActor
class AccessibilitySettingsManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isVoiceOverEnabled: Bool = false
    @Published var contentSizeCategory: ContentSizeCategory = .medium
    @Published var isHighContrastEnabled: Bool = false
    @Published var isReduceMotionEnabled: Bool = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        updateAllSettings()
        setupObservers()
    }
    
    // MARK: - Private Methods
    
    private func updateAllSettings() {
        #if canImport(UIKit)
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        contentSizeCategory = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
        isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled || UIAccessibility.isInvertColorsEnabled
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        #else
        // macOS fallbacks
        isVoiceOverEnabled = false
        contentSizeCategory = .medium
        isHighContrastEnabled = false
        isReduceMotionEnabled = false
        #endif
    }
    
    private func setupObservers() {
        #if canImport(UIKit)
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in self?.updateVoiceOverStatus() }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { [weak self] _ in self?.updateContentSizeCategory() }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIAccessibility.darkerSystemColorsStatusDidChangeNotification)
            .sink { [weak self] _ in self?.updateHighContrastStatus() }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in self?.updateReduceMotionStatus() }
            .store(in: &cancellables)
        #endif
    }
    
    private func updateVoiceOverStatus() {
        #if canImport(UIKit)
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        #endif
    }
    
    private func updateContentSizeCategory() {
        #if canImport(UIKit)
        contentSizeCategory = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
        #endif
    }
    
    private func updateHighContrastStatus() {
        #if canImport(UIKit)
        isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled || UIAccessibility.isInvertColorsEnabled
        #endif
    }
    
    private func updateReduceMotionStatus() {
        #if canImport(UIKit)
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        #endif
    }
}