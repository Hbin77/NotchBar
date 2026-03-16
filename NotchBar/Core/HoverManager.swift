//
//  HoverManager.swift
//  NotchBar
//
//  마우스 호버 감지 및 팝업 트리거
//

import AppKit
import Combine

class HoverManager {
    
    // MARK: - Properties
    
    private weak var notchWindow: NotchWindow?
    private var eventMonitor: Any?
    private var hoverTimer: Timer?
    private var isHovering = false
    
    /// 호버 지연 시간 (초)
    private let hoverDelay: TimeInterval = 0.3
    
    /// 호버 해제 지연 시간 (초)
    private let unhoverDelay: TimeInterval = 0.5
    
    // MARK: - Initialization
    
    init(notchWindow: NotchWindow?) {
        self.notchWindow = notchWindow
    }
    
    deinit {
        stopTracking()
    }
    
    // MARK: - Tracking
    
    func startTracking() {
        // 전역 마우스 이동 모니터링
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .mouseEntered, .mouseExited]) { [weak self] event in
            self?.handleMouseEvent(event)
        }
        
        // 로컬 이벤트도 모니터링 (앱 윈도우 위에서)
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseEvent(event)
            return event
        }
        
        print("🖱️ 마우스 트래킹 시작")
    }
    
    func stopTracking() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        hoverTimer?.invalidate()
        hoverTimer = nil
        print("🖱️ 마우스 트래킹 종료")
    }
    
    // MARK: - Event Handling
    
    private func handleMouseEvent(_ event: NSEvent) {
        let mouseLocation = NSEvent.mouseLocation
        let detectionFrame = NotchDetector.getHoverDetectionFrame()
        
        let isInNotchArea = detectionFrame.contains(mouseLocation)
        
        // 팝업이 열려있으면 팝업 영역도 체크
        if let window = notchWindow, window.isExpanded {
            let expandedFrame = NotchDetector.getExpandedFrame()
            let isInPopupArea = expandedFrame.contains(mouseLocation)
            
            if isInNotchArea || isInPopupArea {
                handleHoverEnter()
            } else {
                handleHoverExit()
            }
        } else {
            if isInNotchArea {
                handleHoverEnter()
            } else {
                handleHoverExit()
            }
        }
    }
    
    private func handleHoverEnter() {
        guard !isHovering else { return }
        
        // 기존 타이머 취소
        hoverTimer?.invalidate()
        
        // 지연 후 팝업 표시
        hoverTimer = Timer.scheduledTimer(withTimeInterval: hoverDelay, repeats: false) { [weak self] _ in
            self?.isHovering = true
            self?.notchWindow?.expand()
        }
    }
    
    private func handleHoverExit() {
        guard isHovering else {
            hoverTimer?.invalidate()
            hoverTimer = nil
            return
        }
        
        // 기존 타이머 취소
        hoverTimer?.invalidate()
        
        // 지연 후 팝업 숨김
        hoverTimer = Timer.scheduledTimer(withTimeInterval: unhoverDelay, repeats: false) { [weak self] _ in
            self?.isHovering = false
            self?.notchWindow?.collapse()
        }
    }
}
