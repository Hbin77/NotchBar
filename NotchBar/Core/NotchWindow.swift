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
    private let notchFrame: NSRect
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
        self.hasShadow = true
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
        hostingView?.frame = self.frame
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
        viewModel.isExpanded = true

        let expandedFrame = NotchDetector.getExpandedFrame()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)

            self.animator().setFrame(expandedFrame, display: true)
            self.animator().alphaValue = 1.0
        }
    }

    func collapse() {
        guard isExpanded else { return }
        viewModel.isExpanded = false

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)

            self.animator().setFrame(notchFrame, display: true)
        }
    }

    // MARK: - Mouse Events

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
