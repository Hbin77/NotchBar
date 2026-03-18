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
        let notchWidth = hasNotch() ? getNotchWidth() + 30 : 260
        let centerX = sf.origin.x + (sf.width - notchWidth) / 2
        // ComfyNotch 방식: screen.frame.height 기준, origin.y 오프셋 적용
        let y = sf.origin.y + sf.height - notchHeight
        return NSRect(x: centerX, y: y, width: notchWidth, height: notchHeight)
    }

    static func getExpandedFrame() -> NSRect {
        guard let screen = targetScreen() else { return .zero }
        let sf = screen.frame
        let centerX = sf.origin.x + (sf.width - expandedWidth) / 2
        // 화면 최상단에서 아래로 확장
        let y = sf.origin.y + sf.height - expandedHeight
        return NSRect(x: centerX, y: y, width: expandedWidth, height: expandedHeight)
    }

    static func getHoverDetectionFrame() -> NSRect {
        let nf = getNotchFrame()
        return NSRect(x: nf.origin.x - 20, y: nf.origin.y - 10, width: nf.width + 40, height: nf.height + 10)
    }
}
