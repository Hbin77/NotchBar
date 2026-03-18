//
//  AppDelegate.swift
//  NotchBar
//

import SwiftUI
import AppKit
import os.log

class AppDelegate: NSObject, NSApplicationDelegate {

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "NotchBar", category: "AppDelegate")

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
        NSApp.setActivationPolicy(.accessory)

        // 모니터 변경 감지 (외부 모니터 연결/해제 시 위치 재계산)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        hoverManager?.stopTracking()
    }

    @objc private func screenConfigChanged() {
        Self.logger.info("Screen configuration changed, repositioning...")
        // 노치 화면 재탐색 후 윈도우 위치 재설정
        let notchFrame: NSRect
        if NotchDetector.hasNotch() {
            notchFrame = NotchDetector.getNotchFrame()
        } else {
            guard let screen = NotchDetector.targetScreen() else { return }
            let width: CGFloat = 200
            notchFrame = NSRect(
                x: screen.frame.origin.x + (screen.frame.width - width) / 2,
                y: screen.frame.maxY - 38,
                width: width,
                height: 38
            )
        }

        if let window = notchWindow {
            if window.isExpanded {
                window.collapse()
            }
            window.updateNotchFrame(notchFrame)
        }
    }

    // MARK: - Setup

    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // SF Symbol 아이콘 설정
            if let image = NSImage(systemSymbolName: "rectangle.topthird.inset.filled", accessibilityDescription: "NotchBar") {
                image.isTemplate = true
                button.image = image
            } else {
                // 폴백: 텍스트 타이틀
                button.title = "NB"
            }
        }

        // 메뉴 설정
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "NotchBar", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let showItem = NSMenuItem(title: "노치 팝업 토글", action: #selector(toggleNotchPopup), keyEquivalent: "n")
        showItem.keyEquivalentModifierMask = [.command, .shift]
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "설정...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "종료", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    private func setupNotchWindow() {
        let hasNotch = NotchDetector.hasNotch()
        Self.logger.info("hasNotch=\(hasNotch)")

        let notchFrame: NSRect
        if hasNotch {
            notchFrame = NotchDetector.getNotchFrame()
        } else {
            guard let screen = NotchDetector.targetScreen() else { return }
            let width: CGFloat = 200
            notchFrame = NSRect(
                x: screen.frame.origin.x + (screen.frame.width - width) / 2,
                y: screen.frame.maxY - 38,
                width: width,
                height: 38
            )
        }

        notchWindow = NotchWindow(notchFrame: notchFrame)
        notchWindow?.show()
    }

    private func setupManagers() {
        hoverManager = HoverManager(notchWindow: notchWindow)
        hoverManager?.startTracking()

        Task { @MainActor in
            let media = MediaManager.shared
            media.startMonitoring()
            self.mediaManager = media
            WeatherManager.shared.startMonitoring()
        }
    }

    // MARK: - Actions

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
