//
//  NotchDetector.swift
//  NotchBar
//
//  노치 영역 감지 및 프레임 계산
//

import AppKit

struct NotchDetector {

    // MARK: - Constants

    static let notchHeight: CGFloat = 38
    static let expandedHeight: CGFloat = 460
    static let expandedWidth: CGFloat = 700

    // MARK: - Screen Detection

    static func notchScreen() -> NSScreen? {
        if #available(macOS 12.0, *) {
            for screen in NSScreen.screens {
                if screen.safeAreaInsets.top > 0 { return screen }
                if screen.auxiliaryTopLeftArea != nil || screen.auxiliaryTopRightArea != nil { return screen }
            }
        }
        return nil
    }

    static func targetScreen() -> NSScreen? {
        return notchScreen() ?? NSScreen.main
    }

    static func hasNotch() -> Bool {
        return notchScreen() != nil
    }

    static func getNotchWidth() -> CGFloat {
        guard let screen = notchScreen() else { return 180 }
        if #available(macOS 12.0, *) {
            if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
                let w = screen.frame.width - left.width - right.width
                if w > 0 { return w }
            }
        }
        return 180
    }

    static func getNotchFrame() -> NSRect {
        guard let screen = targetScreen() else { return .zero }
        let sf = screen.frame
        let vf = screen.visibleFrame
        let notchWidth = hasNotch() ? getNotchWidth() : 200
        let menuBarHeight = sf.maxY - vf.maxY
        let notchX = sf.origin.x + (sf.width - notchWidth) / 2
        let notchY = sf.maxY - menuBarHeight
        return NSRect(x: notchX, y: notchY, width: notchWidth, height: max(menuBarHeight, notchHeight))
    }

    /// 노치 상단에서 아래로 펼쳐지는 확장 프레임
    static func getExpandedFrame() -> NSRect {
        let notch = getNotchFrame()
        guard notch != .zero else { return .zero }
        let popupX = notch.midX - expandedWidth / 2
        return NSRect(x: popupX, y: notch.maxY - expandedHeight, width: expandedWidth, height: expandedHeight)
    }

    static func getHoverDetectionFrame() -> NSRect {
        let nf = getNotchFrame()
        return NSRect(x: nf.origin.x - 20, y: nf.origin.y - 10, width: nf.width + 40, height: nf.height + 10)
    }
}
