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
    static let expandedHeight: CGFloat = 350
    static let expandedWidth: CGFloat = 600

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
        let notchWidth = hasNotch() ? getNotchWidth() + 20 : 250  // 노치보다 살짝 넓게
        let notchX = sf.origin.x + (sf.width - notchWidth) / 2
        // 화면 절대 최상단 (노치 영역)
        let notchY = sf.origin.y + sf.height - notchHeight
        return NSRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight)
    }

    /// 화면 상단에서 아래로 — 노치에서 확장되는 느낌
    static func getExpandedFrame() -> NSRect {
        guard let screen = targetScreen() else { return .zero }
        let screenTop = screen.frame.maxY
        let popupX = screen.frame.origin.x + (screen.frame.width - expandedWidth) / 2
        let popupY = screenTop - expandedHeight
        return NSRect(x: popupX, y: popupY, width: expandedWidth, height: expandedHeight)
    }

    static func getHoverDetectionFrame() -> NSRect {
        let nf = getNotchFrame()
        return NSRect(x: nf.origin.x - 20, y: nf.origin.y - 10, width: nf.width + 40, height: nf.height + 10)
    }
}
