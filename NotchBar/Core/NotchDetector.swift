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
    static let expandedHeight: CGFloat = 420
    static let expandedWidth: CGFloat = 600

    // MARK: - Screen Detection

    /// 노치가 있는 화면을 찾음 (내장 디스플레이 우선)
    static func notchScreen() -> NSScreen? {
        if #available(macOS 12.0, *) {
            // 모든 스크린 중에서 노치가 있는 화면 찾기
            for screen in NSScreen.screens {
                if screen.safeAreaInsets.top > 0 {
                    return screen
                }
                if screen.auxiliaryTopLeftArea != nil || screen.auxiliaryTopRightArea != nil {
                    return screen
                }
            }
        }
        return nil
    }

    /// 팝업을 표시할 화면 (노치 화면 > 메인 화면)
    static func targetScreen() -> NSScreen? {
        return notchScreen() ?? NSScreen.main
    }

    // MARK: - Detection

    static func hasNotch() -> Bool {
        return notchScreen() != nil
    }

    /// 노치 너비를 런타임에 계산
    static func getNotchWidth() -> CGFloat {
        guard let screen = notchScreen() else { return 180 }

        if #available(macOS 12.0, *) {
            if let leftArea = screen.auxiliaryTopLeftArea,
               let rightArea = screen.auxiliaryTopRightArea {
                let notchWidth = screen.frame.width - leftArea.width - rightArea.width
                if notchWidth > 0 { return notchWidth }
            }
        }

        return 180
    }

    /// 노치 영역의 프레임 반환 (노치 화면 기준 절대 좌표)
    static func getNotchFrame() -> NSRect {
        guard let screen = targetScreen() else { return .zero }

        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let notchWidth = hasNotch() ? getNotchWidth() : 200

        // 메뉴바 높이 계산
        let menuBarHeight = screenFrame.maxY - visibleFrame.maxY

        // 노치 중앙 위치 (절대 좌표 — 멀티 모니터 대응)
        let notchX = screenFrame.origin.x + (screenFrame.width - notchWidth) / 2
        let notchY = screenFrame.maxY - menuBarHeight

        return NSRect(
            x: notchX,
            y: notchY,
            width: notchWidth,
            height: max(menuBarHeight, notchHeight)
        )
    }

    /// 확장된 팝업 프레임 반환
    static func getExpandedFrame() -> NSRect {
        guard let screen = targetScreen() else { return .zero }

        let screenFrame = screen.frame

        let popupX = screenFrame.origin.x + (screenFrame.width - expandedWidth) / 2
        let popupY = screenFrame.maxY - notchHeight - expandedHeight

        return NSRect(
            x: popupX,
            y: popupY,
            width: expandedWidth,
            height: expandedHeight
        )
    }

    /// 호버 감지 영역
    static func getHoverDetectionFrame() -> NSRect {
        let notchFrame = getNotchFrame()

        return NSRect(
            x: notchFrame.origin.x - 20,
            y: notchFrame.origin.y - 10,
            width: notchFrame.width + 40,
            height: notchFrame.height + 10
        )
    }
}
