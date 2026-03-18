//
//  NotchDetector.swift
//  NotchBar
//
//  노치 영역 감지 및 프레임 계산
//

import AppKit

struct NotchDetector {

    static let notchHeight: CGFloat = 38
    static let stemHeight: CGFloat = 16
    static let expandedPanelHeight: CGFloat = 360
    static let expandedWidth: CGFloat = 480

    // MARK: - Screen Detection

    static func notchScreen() -> NSScreen? {
        if #available(macOS 12.0, *) {
            for screen in NSScreen.screens {
                if screen.safeAreaInsets.top > 0 { return screen }
                if screen.auxiliaryTopLeftArea != nil { return screen }
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

    // MARK: - Collapsed Frame

    static func getNotchFrame() -> NSRect {
        guard let screen = targetScreen() else { return .zero }
        let sf = screen.frame
        let vf = screen.visibleFrame
        let menuBarH = sf.maxY - vf.maxY
        let width: CGFloat = hasNotch() ? getNotchWidth() + 40 : 260
        let x = sf.origin.x + (sf.width - width) / 2
        let y = vf.maxY
        return NSRect(x: x, y: y, width: width, height: menuBarH)
    }

    // MARK: - Expanded Frame

    static func getExpandedFrame() -> NSRect {
        guard let screen = targetScreen() else { return .zero }
        let sf = screen.frame
        let vf = screen.visibleFrame
        let x = sf.origin.x + (sf.width - expandedWidth) / 2
        let y = vf.maxY - expandedPanelHeight
        return NSRect(x: x, y: y, width: expandedWidth, height: expandedPanelHeight)
    }

    // MARK: - Hover Detection

    static func getHoverDetectionFrame() -> NSRect {
        guard let screen = targetScreen() else { return .zero }
        let sf = screen.frame
        let width: CGFloat = 300
        let x = sf.origin.x + (sf.width - width) / 2
        let y = sf.maxY - notchHeight - 5
        return NSRect(x: x, y: y, width: width, height: notchHeight + 10)
    }
}
