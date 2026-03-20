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
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var hoverTimer: Timer?
    private var isHovering = false

    /// 호버 지연 시간 (초) — @AppStorage 연동
    private var hoverDelay: TimeInterval {
        UserDefaults.standard.double(forKey: "hoverDelay").clamped(to: 0.1...3.0, default: 0.2)
    }

    /// 호버 해제 지연 시간 (초)
    private var unhoverDelay: TimeInterval {
        UserDefaults.standard.double(forKey: "unhoverDelay").clamped(to: 0.1...3.0, default: 0.3)
    }

    // MARK: - Initialization

    init(notchWindow: NotchWindow?) {
        self.notchWindow = notchWindow
    }

    deinit {
        stopTracking()
    }

    // MARK: - Tracking

    func startTracking() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .mouseEntered, .mouseExited]) { [weak self] event in
            self?.handleMouseEvent(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseEvent(event)
            return event
        }
    }

    func stopTracking() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        hoverTimer?.invalidate()
        hoverTimer = nil
    }

    // MARK: - Event Handling

    private func handleMouseEvent(_ event: NSEvent) {
        let mouseLocation = NSEvent.mouseLocation
        let detectionFrame = NotchDetector.getHoverDetectionFrame()

        let isInNotchArea = detectionFrame.contains(mouseLocation)

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
        hoverTimer?.invalidate()
        hoverTimer = nil

        // 이미 열려있으면 (메뉴 토글 등으로) 호버 상태만 동기화
        if notchWindow?.isExpanded == true {
            isHovering = true
            return
        }

        guard !isHovering else { return }

        hoverTimer = Timer.scheduledTimer(withTimeInterval: hoverDelay, repeats: false) { [weak self] _ in
            self?.isHovering = true
            self?.notchWindow?.expand()
        }
    }

    private func handleHoverExit() {
        hoverTimer?.invalidate()
        hoverTimer = nil

        // 열려있지 않으면 무시
        guard notchWindow?.isExpanded == true else {
            isHovering = false
            return
        }

        hoverTimer = Timer.scheduledTimer(withTimeInterval: unhoverDelay, repeats: false) { [weak self] _ in
            self?.isHovering = false
            self?.notchWindow?.collapse()
        }
    }
}

// MARK: - Double Extension

private extension Double {
    func clamped(to range: ClosedRange<Double>, default defaultValue: Double) -> Double {
        if self == 0 { return defaultValue }
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
