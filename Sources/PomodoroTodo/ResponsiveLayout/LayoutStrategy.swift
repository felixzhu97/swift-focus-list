import SwiftUI

// MARK: - Layout Strategy Protocol

protocol LayoutStrategy {
    func contentPadding(for orientation: DeviceOrientation) -> EdgeInsets
    func sectionSpacing(for orientation: DeviceOrientation) -> CGFloat
    func buttonSpacing(for orientation: DeviceOrientation) -> CGFloat
    func maxContentWidth(for orientation: DeviceOrientation) -> CGFloat?
    func optimalTimerSize(screenSize: CGSize, orientation: DeviceOrientation) -> CGFloat
}

// MARK: - Device-Specific Layout Strategies

struct iPhoneLayoutStrategy: LayoutStrategy {
    func contentPadding(for orientation: DeviceOrientation) -> EdgeInsets {
        switch orientation {
        case .landscape:
            return EdgeInsets(
                top: DesignTokens.Spacing.small,
                leading: DesignTokens.Spacing.medium,
                bottom: DesignTokens.Spacing.small,
                trailing: DesignTokens.Spacing.medium
            )
        default:
            return EdgeInsets(
                top: DesignTokens.Spacing.medium,
                leading: DesignTokens.Spacing.screenMargin,
                bottom: DesignTokens.Spacing.medium,
                trailing: DesignTokens.Spacing.screenMargin
            )
        }
    }
    
    func sectionSpacing(for orientation: DeviceOrientation) -> CGFloat {
        orientation == .landscape ? DesignTokens.Spacing.medium : DesignTokens.Spacing.section
    }
    
    func buttonSpacing(for orientation: DeviceOrientation) -> CGFloat {
        orientation == .landscape ? DesignTokens.Spacing.small : DesignTokens.Spacing.buttonSpacing
    }
    
    func maxContentWidth(for orientation: DeviceOrientation) -> CGFloat? {
        nil // Use full width
    }
    
    func optimalTimerSize(screenSize: CGSize, orientation: DeviceOrientation) -> CGFloat {
        let baseSize: CGFloat = 250
        let minSize: CGFloat = 180
        let padding = contentPadding(for: orientation)
        let availableWidth = screenSize.width - (padding.leading + padding.trailing)
        
        var calculatedSize = min(availableWidth * 0.75, baseSize)
        if orientation == .landscape {
            calculatedSize = min(calculatedSize, screenSize.height * 0.6)
        }
        
        return max(minSize, calculatedSize)
    }
}

struct iPadLayoutStrategy: LayoutStrategy {
    let shouldUseSplitView: Bool
    
    func contentPadding(for orientation: DeviceOrientation) -> EdgeInsets {
        let horizontalPadding = shouldUseSplitView ? DesignTokens.Spacing.large : DesignTokens.Spacing.extraLarge
        return EdgeInsets(
            top: DesignTokens.Spacing.large,
            leading: horizontalPadding,
            bottom: DesignTokens.Spacing.large,
            trailing: horizontalPadding
        )
    }
    
    func sectionSpacing(for orientation: DeviceOrientation) -> CGFloat {
        DesignTokens.Spacing.extraLarge
    }
    
    func buttonSpacing(for orientation: DeviceOrientation) -> CGFloat {
        DesignTokens.Spacing.large
    }
    
    func maxContentWidth(for orientation: DeviceOrientation) -> CGFloat? {
        shouldUseSplitView ? nil : 600
    }
    
    func optimalTimerSize(screenSize: CGSize, orientation: DeviceOrientation) -> CGFloat {
        let maxSize: CGFloat = 400
        let minSize: CGFloat = 180
        let padding = contentPadding(for: orientation)
        let availableWidth = screenSize.width - (padding.leading + padding.trailing)
        
        var calculatedSize = min(availableWidth * 0.5, maxSize)
        if shouldUseSplitView && orientation == .landscape {
            calculatedSize = min(calculatedSize, screenSize.height * 0.7)
        }
        
        return max(minSize, calculatedSize)
    }
}

struct MacLayoutStrategy: LayoutStrategy {
    func contentPadding(for orientation: DeviceOrientation) -> EdgeInsets {
        EdgeInsets(
            top: DesignTokens.Spacing.medium,
            leading: DesignTokens.Spacing.large,
            bottom: DesignTokens.Spacing.medium,
            trailing: DesignTokens.Spacing.large
        )
    }
    
    func sectionSpacing(for orientation: DeviceOrientation) -> CGFloat {
        DesignTokens.Spacing.section
    }
    
    func buttonSpacing(for orientation: DeviceOrientation) -> CGFloat {
        DesignTokens.Spacing.large
    }
    
    func maxContentWidth(for orientation: DeviceOrientation) -> CGFloat? {
        800
    }
    
    func optimalTimerSize(screenSize: CGSize, orientation: DeviceOrientation) -> CGFloat {
        250 // Fixed optimal size for macOS
    }
}