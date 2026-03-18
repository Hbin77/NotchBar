//
//  NotchDetector.swift
//  NotchBar
//
//  노치 영역 감지 및 프레임 계산
//  전략: 노치 위에는 못 올라가므로, 메뉴바 바로 아래에서 드롭다운
//

import AppKit

struct NotchDetector {

    static let notchHeight: CGFloat = 38
    static let expandedHeight: CGFloat = 340
    static let expandedWidth: CGFloat = 600

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

    // MARK: - Collapsed Frame (메뉴바 영역, 노치 중앙)

    static func getNotchFrame() -> NSRect {
        guard let screen = targetScreen() else { return .zero }
        let sf = screen.frame
        let vf = screen.visibleFrame
        // 메뉴바 높이
        let menuBarH = sf.maxY - vf.maxY
        // 메뉴바 영역 중앙에 위치 (노치와 같은 높이)
        let width: CGFloat = hasNotch() ? getNotchWidth() + 40 : 260
        let x = sf.origin.x + (sf.width - width) / 2
        let y = vf.maxY  // 메뉴바 바로 아래
        return NSRect(x: x, y: y, width: width, height: menuBarH)
    }

    // MARK: - Expanded Frame (메뉴바 아래에서 드롭다운)

    static func getExpandedFrame() -> NSRect {
        guard let screen = targetScreen() else { return .zero }
        let sf = screen.frame
        let vf = screen.visibleFrame
        let x = sf.origin.x + (sf.width - expandedWidth) / 2
        let y = vf.maxY - expandedHeight  // 메뉴바 바로 아래에서 시작
        return NSRect(x: x, y: y, width: expandedWidth, height: expandedHeight)
    }

    // MARK: - Hover Detection

    static func getHoverDetectionFrame() -> NSRect {
        guard let screen = targetScreen() else { return .zero }
        let sf = screen.frame
        // 화면 상단 중앙 300px 너비, 노치 높이 영역을 호버 감지로
        let width: CGFloat = 300
        let x = sf.origin.x + (sf.width - width) / 2
        let y = sf.maxY - notchHeight - 5
        return NSRect(x: x, y: y, width: width, height: notchHeight + 10)
    }
}
