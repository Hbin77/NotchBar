//
//  NotchWindow.swift
//  NotchBar
//
//  노치 팝업 윈도우 — 접힌 상태에서도 보이고, 확장 시 애니메이션
//

import SwiftUI
import AppKit

class NotchViewModel: ObservableObject {
    @Published var isExpanded = false
}

class NotchWindow: NSPanel {

    var isExpanded: Bool { viewModel.isExpanded }
    private(set) var notchFrame: NSRect
    private var hostingView: NSHostingView<NotchPopupView>?
    let viewModel = NotchViewModel()

    init(notchFrame: NSRect) {
        self.notchFrame = notchFrame
        super.init(
            contentRect: notchFrame,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        setupWindow()
        setupContent()
    }

    private func setupWindow() {
        self.level = .popUpMenu
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
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
        hostingView?.wantsLayer = true
        hostingView?.layer?.masksToBounds = false
        hostingView?.frame = NSRect(origin: .zero, size: self.frame.size)
        self.contentView = hostingView
    }

    func show() {
        self.alphaValue = 0  // 접힌 상태에서 숨김
        self.orderFrontRegardless()
    }

    func hide() { self.orderOut(nil) }

    func toggle() {
        if isExpanded { collapse() } else { expand() }
    }

    func expand() {
        guard !isExpanded else { return }
        let expandedFrame = NotchDetector.getExpandedFrame()

        self.setFrame(expandedFrame, display: true)
        self.alphaValue = 1.0
        self.ignoresMouseEvents = false
        self.orderFrontRegardless()
        viewModel.isExpanded = true
    }

    func collapse() {
        guard isExpanded else { return }
        viewModel.isExpanded = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.setFrame(self.notchFrame, display: true)
            self.alphaValue = 0
            self.ignoresMouseEvents = true
        }
    }

    func updateNotchFrame(_ frame: NSRect) {
        self.notchFrame = frame
        if !isExpanded { self.setFrame(frame, display: true) }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
