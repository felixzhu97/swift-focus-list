import SwiftUI

// MARK: - Simplified Device Info

struct DeviceInfo {
    let screenSize: CGSize
    let horizontalSizeClass: UserInterfaceSizeClass?
    let verticalSizeClass: UserInterfaceSizeClass?
    let deviceType: DeviceType
    let orientation: DeviceOrientation
    
    private let layoutStrategy: LayoutStrategy
    
    init(
        screenSize: CGSize,
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        deviceType: DeviceType,
        orientation: DeviceOrientation
    ) {
        self.screenSize = screenSize
        self.horizontalSizeClass = horizontalSizeClass
        self.verticalSizeClass = verticalSizeClass
        self.deviceType = deviceType
        self.orientation = orientation
        
        // Initialize appropriate layout strategy
        switch deviceType {
        case .iPhone:
            self.layoutStrategy = iPhoneLayoutStrategy()
        case .iPad:
            let shouldUseSplitView = deviceType == .iPad && horizontalSizeClass == .regular
            self.layoutStrategy = iPadLayoutStrategy(shouldUseSplitView: shouldUseSplitView)
        case .mac:
            self.layoutStrategy = MacLayoutStrategy()
        }
    }
    
    // MARK: - Layout Decision Properties
    
    var shouldUseCompactLayout: Bool {
        deviceType.isCompact || (horizontalSizeClass == .compact && verticalSizeClass == .regular)
    }
    
    var shouldUseSidebarNavigation: Bool {
        #if os(macOS)
        return true
        #else
        return deviceType == .iPad && horizontalSizeClass == .regular && orientation == .landscape
        #endif
    }
    
    var shouldUseSplitView: Bool {
        deviceType == .iPad && horizontalSizeClass == .regular
    }
    
    // MARK: - Layout Properties (Delegated to Strategy)
    
    var contentPadding: EdgeInsets {
        layoutStrategy.contentPadding(for: orientation)
    }
    
    var sectionSpacing: CGFloat {
        layoutStrategy.sectionSpacing(for: orientation)
    }
    
    var buttonSpacing: CGFloat {
        layoutStrategy.buttonSpacing(for: orientation)
    }
    
    var maxContentWidth: CGFloat? {
        layoutStrategy.maxContentWidth(for: orientation)
    }
    
    var optimalTimerSize: CGFloat {
        layoutStrategy.optimalTimerSize(screenSize: screenSize, orientation: orientation)
    }
}