//
//  NotchWindow.swift
//  NotchBar
//
//  노치 팝업 윈도우 관리
//

import SwiftUI
import AppKit

class NotchWindow: NSWindow {
    
    // MARK: - Properties
    
    private(set) var isExpanded = false
    private let notchFrame: NSRect
    private var hostingView: NSHostingView<NotchPopupView>?
    
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
        // 윈도우 속성 설정
        self.level = .statusBar + 1  // 메뉴바 위에 표시
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.isMovableByWindowBackground = false
        
        // 모든 Space에서 표시
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
    }
    
    private func setupContent() {
        let contentView = NotchPopupView()
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
        isExpanded = true
        
        let expandedFrame = NotchDetector.getExpandedFrame()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            self.animator().setFrame(expandedFrame, display: true)
            self.animator().alphaValue = 1.0
        }
        
        // 뷰 업데이트
        updateContent(expanded: true)
        
        print("📱 노치 팝업 확장")
    }
    
    func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            self.animator().setFrame(notchFrame, display: true)
        }
        
        // 뷰 업데이트
        updateContent(expanded: false)
        
        print("📱 노치 팝업 축소")
    }
    
    private func updateContent(expanded: Bool) {
        let contentView = NotchPopupView(isExpanded: expanded)
        hostingView?.rootView = contentView
    }
    
    // MARK: - Mouse Events
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
