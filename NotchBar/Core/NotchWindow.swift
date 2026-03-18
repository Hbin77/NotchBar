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
        // overlayWindow 레벨 — 메뉴바/노치 위에 표시 (ComfyNotch와 동일)
        let overlayLevel = CGWindowLevelForKey(.overlayWindow)
        self.level = NSWindow.Level(rawValue: Int(overlayLevel))
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
        // 접힌 상태에서도 보이게 (노치 안의 미니 콘텐츠)
        self.alphaValue = 1.0
        self.orderFrontRegardless()
    }

    func hide() { self.orderOut(nil) }

    func toggle() {
        if isExpanded { collapse() } else { expand() }
    }

    func expand() {
        guard !isExpanded else { return }
        let expandedFrame = NotchDetector.getExpandedFrame()

        viewModel.isExpanded = true

        // 애니메이션으로 프레임 확장
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.animator().setFrame(expandedFrame, display: true, animate: true)
        }
        self.orderFrontRegardless()
    }

    func collapse() {
        guard isExpanded else { return }
        viewModel.isExpanded = false

        // 애니메이션으로 프레임 축소
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().setFrame(self.notchFrame, display: true, animate: true)
        }
    }

    func updateNotchFrame(_ frame: NSRect) {
        self.notchFrame = frame
        if !isExpanded { self.setFrame(frame, display: true) }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
