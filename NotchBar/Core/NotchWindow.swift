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
        hostingView?.autoresizingMask = [.width, .height]
        hostingView?.frame = NSRect(origin: .zero, size: self.frame.size)
        self.contentView = hostingView
    }

    // MARK: - Public Methods

    func show() {
        self.alphaValue = 0
        self.ignoresMouseEvents = true
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

        self.ignoresMouseEvents = false
        self.setFrame(expandedFrame, display: true)
        self.alphaValue = 1.0
        self.orderFrontRegardless()
        viewModel.isExpanded = true
    }

    func collapse() {
        guard isExpanded else { return }

        viewModel.isExpanded = false

        // 약간의 딜레이 후 프레임 축소+숨김
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.setFrame(self.notchFrame, display: true)
            self.alphaValue = 0
            self.ignoresMouseEvents = true
        }
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
