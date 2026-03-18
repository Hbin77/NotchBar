//
//  NotchDetector.swift
//  NotchBar
//
//  노치 영역 감지 및 프레임 계산
//  전략: 노치에서 자연스럽게 확장되는 드롭다운 패널
//

import AppKit

struct NotchDetector {

    static let notchHeight: CGFloat = 38
    static let expandedPanelHeight: CGFloat = 320
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

    static func getMenuBarHeight() -> CGFloat {
        guard let screen = targetScreen() else { return 38 }
        return screen.frame.maxY - screen.visibleFrame.maxY
    }

    // MARK: - Collapsed Frame (메뉴바 영역, 노치 중앙)

    static func getNotchFrame() -> NSRect {
        guard let screen = targetScreen() else { return .zero }
        let sf = screen.frame
        let vf = screen.visibleFrame
        let menuBarH = sf.maxY - vf.maxY
        let width: CGFloat = hasNotch() ? getNotchWidth() + 40 : 260
        let x = sf.origin.x + (sf.width - width) / 2
        let y = vf.maxY  // 메뉴바 바로 아래
        return NSRect(x: x, y: y, width: width, height: menuBarH)
    }

    // MARK: - Expanded Frame (노치 영역 포함, 아래로 확장)

    static func getExpandedFrame() -> NSRect {
        guard let screen = targetScreen() else { return .zero }
        let sf = screen.frame
        let vf = screen.visibleFrame
        let menuBarH = sf.maxY - vf.maxY
        let x = sf.origin.x + (sf.width - expandedWidth) / 2
        // 패널 본체 + 메뉴바 높이 (노치 연결용)
        let totalHeight = expandedPanelHeight + menuBarH
        let y = vf.maxY - expandedPanelHeight  // 패널 본체 하단
        return NSRect(x: x, y: y, width: expandedWidth, height: totalHeight)
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
