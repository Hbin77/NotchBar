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
    static let expandedHeight: CGFloat = 56   // 노치 높이 + 약간만 확장
    static let expandedWidth: CGFloat = 400  // 노치보다 좌우로 넓게

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

    /// 노치 위치에서 좌우로 확장 — 노치 자체가 커지는 느낌
    static func getExpandedFrame() -> NSRect {
        guard let screen = targetScreen() else { return .zero }
        let screenTop = screen.frame.maxY
        let popupX = screen.frame.origin.x + (screen.frame.width - expandedWidth) / 2
        // 상단이 화면 최상단에 맞닿음 (노치와 이어짐)
        let popupY = screenTop - expandedHeight
        return NSRect(x: popupX, y: popupY, width: expandedWidth, height: expandedHeight)
    }

    static func getHoverDetectionFrame() -> NSRect {
        let nf = getNotchFrame()
        return NSRect(x: nf.origin.x - 20, y: nf.origin.y - 10, width: nf.width + 40, height: nf.height + 10)
    }
}
