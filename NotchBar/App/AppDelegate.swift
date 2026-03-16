//
//  AppDelegate.swift
//  NotchBar
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    private var statusItem: NSStatusItem?
    private var notchWindow: NotchWindow?
    private var hoverManager: HoverManager?
    private var mediaManager: MediaManager?
    
    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        setupNotchWindow()
        setupManagers()
        
        // 메뉴바 앱으로 설정 (Dock 아이콘 숨김)
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        hoverManager?.stopTracking()
    }
    
    // MARK: - Setup
    
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.topthird.inset.filled", accessibilityDescription: "NotchBar")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        setupStatusBarMenu()
    }
    
    private func setupStatusBarMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "NotchBar", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let showItem = NSMenuItem(title: "노치 팝업 표시", action: #selector(toggleNotchPopup), keyEquivalent: "n")
        showItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(showItem)
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "설정...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "종료", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func setupNotchWindow() {
        guard NotchDetector.hasNotch() else {
            print("⚠️ 노치가 없는 맥북입니다")
            return
        }
        
        let notchFrame = NotchDetector.getNotchFrame()
        notchWindow = NotchWindow(notchFrame: notchFrame)
        notchWindow?.show()
    }
    
    private func setupManagers() {
        // 호버 매니저 설정
        hoverManager = HoverManager(notchWindow: notchWindow)
        hoverManager?.startTracking()
        
        // 미디어 매니저 설정
        mediaManager = MediaManager.shared
        mediaManager?.startMonitoring()
    }
    
    // MARK: - Actions
    
    @objc private func statusBarButtonClicked() {
        // 좌클릭 시 팝업 토글
        toggleNotchPopup()
    }
    
    @objc private func toggleNotchPopup() {
        notchWindow?.toggle()
    }
    
    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
