import SwiftUI
import Foundation

// MARK: - Device Detection

struct DeviceDetector {
    static func detectDevice(screenSize: CGSize) -> DeviceType {
        #if os(macOS)
        return .mac
        #else
        let width = max(screenSize.width, screenSize.height)
        return width >= 1024 ? .iPad : .iPhone
        #endif
    }
    
    static func detectOrientation(screenSize: CGSize) -> DeviceOrientation {
        if screenSize.width > screenSize.height {
            return .landscape
        } else if screenSize.width < screenSize.height {
            return .portrait
        } else {
            return .unknown
        }
    }
}

enum DeviceType {
    case iPhone, iPad, mac
    
    var isCompact: Bool { self == .iPhone }
    var isRegular: Bool { self == .iPad || self == .mac }
}

enum DeviceOrientation {
    case portrait, landscape, unknown
}