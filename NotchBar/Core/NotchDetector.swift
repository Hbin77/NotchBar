//
//  NotchDetector.swift
//  NotchBar
//
//  노치 영역 감지 및 프레임 계산
//

import AppKit

struct NotchDetector {
    
    // MARK: - Constants
    
    /// 노치 너비 (픽셀, 대략적인 값)
    static let notchWidth: CGFloat = 180
    
    /// 노치 높이 (메뉴바 높이와 동일)
    static let notchHeight: CGFloat = 38
    
    /// 확장된 팝업 높이
    static let expandedHeight: CGFloat = 200
    
    /// 확장된 팝업 너비
    static let expandedWidth: CGFloat = 400
    
    // MARK: - Detection
    
    /// 노치가 있는 맥북인지 확인
    static func hasNotch() -> Bool {
        guard let screen = NSScreen.main else { return false }
        
        if #available(macOS 12.0, *) {
            let safeArea = screen.safeAreaInsets
            return safeArea.top > 0
        }

        return false
    }
    
    /// 노치 영역의 프레임 반환
    static func getNotchFrame() -> NSRect {
        guard let screen = NSScreen.main else {
            return .zero
        }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        
        // 메뉴바 높이 계산
        let menuBarHeight = screenFrame.height - visibleFrame.height - visibleFrame.origin.y
        
        // 노치 중앙 위치
        let notchX = (screenFrame.width - notchWidth) / 2
        let notchY = screenFrame.height - menuBarHeight
        
        return NSRect(
            x: notchX,
            y: notchY,
            width: notchWidth,
            height: menuBarHeight
        )
    }
    
    /// 확장된 팝업 프레임 반환
    static func getExpandedFrame() -> NSRect {
        guard let screen = NSScreen.main else {
            return .zero
        }
        
        let screenFrame = screen.frame
        
        // 화면 중앙, 메뉴바 아래에 위치
        let popupX = (screenFrame.width - expandedWidth) / 2
        let popupY = screenFrame.height - notchHeight - expandedHeight
        
        return NSRect(
            x: popupX,
            y: popupY,
            width: expandedWidth,
            height: expandedHeight
        )
    }
    
    /// 노치 영역 포함한 확장 감지 영역 (호버 감지용)
    static func getHoverDetectionFrame() -> NSRect {
        let notchFrame = getNotchFrame()
        
        // 노치 영역보다 약간 넓게 (좌우 20px, 아래 10px 확장)
        return NSRect(
            x: notchFrame.origin.x - 20,
            y: notchFrame.origin.y - 10,
            width: notchFrame.width + 40,
            height: notchFrame.height + 10
        )
    }
}
