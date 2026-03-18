//
//  NotchWindow.swift
//  NotchBar
//
//  노치 팝업 윈도우
//

import SwiftUI
import AppKit

class NotchViewModel: ObservableObject {
    @Published var isExpanded = false
    @Published var notchWidth: CGFloat
    @Published var stemHeight: CGFloat

    init(notchWidth: CGFloat = 200, stemHeight: CGFloat = 20) {
        self.notchWidth = notchWidth
        self.stemHeight = stemHeight
    }
}

class NotchWindow: NSPanel {

    var isExpanded: Bool { viewModel.isExpanded }
    private(set) var notchFrame: NSRect
    private var hostingView: NSHostingView<NotchPopupView>?
    let viewModel: NotchViewModel
    private var collapseWorkItem: DispatchWorkItem?

    init(notchFrame: NSRect) {
        self.notchFrame = notchFrame
        self.viewModel = NotchViewModel(
            notchWidth: NotchDetector.hasNotch() ? NotchDetector.getNotchWidth() + 10 : 200,
            stemHeight: NotchDetector.stemHeight
        )
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
        self.alphaValue = 0
        self.orderFrontRegardless()
    }

    func hide() { self.orderOut(nil) }

    func toggle() {
        if isExpanded { collapse() } else { expand() }
    }

    func expand() {
        guard !isExpanded else { return }
        collapseWorkItem?.cancel()
        collapseWorkItem = nil

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

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, !self.isExpanded else { return }
            self.setFrame(self.notchFrame, display: true)
            self.alphaValue = 0
            self.ignoresMouseEvents = true
        }
        collapseWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }

    func updateNotchFrame(_ frame: NSRect) {
        self.notchFrame = frame
        viewModel.notchWidth = NotchDetector.hasNotch() ? NotchDetector.getNotchWidth() + 10 : 200
        viewModel.stemHeight = NotchDetector.stemHeight
        if !isExpanded { self.setFrame(frame, display: true) }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
