import SwiftUI

/// Service for calculating Dynamic Type scaling factors and sizes
struct DynamicTypeScalingService {
    
    // MARK: - Scale Factor Calculation
    
    /// Returns the scale factor based on current Dynamic Type setting
    static func scaleFactor(for contentSizeCategory: ContentSizeCategory) -> CGFloat {
        switch contentSizeCategory {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        case .extraExtraLarge: return 1.3
        case .extraExtraExtraLarge: return 1.4
        case .accessibilityMedium: return 1.6
        case .accessibilityLarge: return 1.8
        case .accessibilityExtraLarge: return 2.0
        case .accessibilityExtraExtraLarge: return 2.2
        case .accessibilityExtraExtraExtraLarge: return 2.4
        @unknown default: return 1.0
        }
    }
    
    // MARK: - Scaling Methods
    
    /// Calculates scaled spacing based on Dynamic Type settings
    static func scaledSpacing(baseSpacing: CGFloat, contentSizeCategory: ContentSizeCategory) -> CGFloat {
        let scaleFactor = scaleFactor(for: contentSizeCategory)
        return baseSpacing * scaleFactor
    }
    
    /// Calculates scaled font size for custom fonts
    static func scaledFontSize(baseSize: CGFloat, contentSizeCategory: ContentSizeCategory) -> CGFloat {
        let scaleFactor = scaleFactor(for: contentSizeCategory)
        return baseSize * scaleFactor
    }
    
    /// Calculates minimum touch target size based on accessibility guidelines
    static func minimumTouchTargetSize(contentSizeCategory: ContentSizeCategory) -> CGFloat {
        // Apple recommends 44pt minimum, but increase for larger Dynamic Type
        let baseSize: CGFloat = 44
        let scaleFactor = scaleFactor(for: contentSizeCategory)
        return max(baseSize, baseSize * scaleFactor)
    }
    
    // MARK: - Specialized Font Scaling
    
    /// Returns a scaled monospaced font for timer display with proper Dynamic Type support
    static func scaledTimerFont(contentSizeCategory: ContentSizeCategory) -> Font {
        let baseSize: CGFloat = 48
        let scaledSize = scaledFontSize(baseSize: baseSize, contentSizeCategory: contentSizeCategory)
        
        // Ensure minimum readability while maintaining monospace alignment
        let clampedSize = max(24, min(scaledSize, 72))
        
        return Font.system(size: clampedSize, weight: .bold, design: .monospaced)
    }
    
    /// Returns scaled kerning for monospaced timer display to improve digit alignment
    static func scaledKerning(contentSizeCategory: ContentSizeCategory) -> CGFloat {
        let baseKerning: CGFloat = 0.5
        let scaleFactor = scaleFactor(for: contentSizeCategory)
        
        // Scale kerning proportionally but keep it subtle
        return baseKerning * min(scaleFactor, 1.5)
    }
}