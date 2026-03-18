//
//  NotchWindow.swift
//  NotchBar
//
//  노치 팝업 윈도우 관리
//

import SwiftUI
import AppKit

class NotchViewModel: ObservableObject {
    @Published var isExpanded = false
}

class NotchWindow: NSPanel {

    // MARK: - Properties

    var isExpanded: Bool { viewModel.isExpanded }
    private(set) var notchFrame: NSRect
    private var hostingView: NSHostingView<NotchPopupView>?
    let viewModel = NotchViewModel()

    // MARK: - Initialization

    init(notchFrame: NSRect) {
        self.notchFrame = notchFrame

        super.init(
            contentRect: notchFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupContent()
    }

    // MARK: - Setup

    private func setupWindow() {
        self.level = .statusBar + 1
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false  // SwiftUI에서 그림자 제어
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.isMovableByWindowBackground = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = true
    }

    private func setupContent() {
        let contentView = NotchPopupView(viewModel: viewModel)
        hostingView = NSHostingView(rootView: contentView)
        hostingView?.frame = NSRect(origin: .zero, size: self.frame.size)
        self.contentView = hostingView
    }

    // MARK: - Public Methods

    func show() {
        self.orderFrontRegardless()
    }

    func hide() {
        self.orderOut(nil)
    }

    func toggle() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }

    func expand() {
        guard !isExpanded else { return }

        let expandedFrame = NotchDetector.getExpandedFrame()

        // 먼저 상태 변경
        viewModel.isExpanded = true

        // 윈도우를 앞으로 가져오기
        self.orderFrontRegardless()
        self.alphaValue = 1.0

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.animator().setFrame(expandedFrame, display: true, animate: true)
        }
    }

    func collapse() {
        guard isExpanded else { return }

        viewModel.isExpanded = false

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().setFrame(self.notchFrame, display: true, animate: true)
        }, completionHandler: {
            // 애니메이션 완료 후 윈도우를 다시 앞으로
            self.orderFrontRegardless()
        })
    }

    /// 모니터 변경 시 notchFrame 업데이트
    func updateNotchFrame(_ frame: NSRect) {
        self.notchFrame = frame
        if !isExpanded {
            self.setFrame(frame, display: true)
        }
    }

    // MARK: - Mouse Events

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
