//
//  MediaManager.swift
//  NotchBar
//
//  미디어 재생 상태 모니터링 (Now Playing)
//

import Foundation
import AppKit
import Combine
import os.log

@MainActor
class MediaManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = MediaManager()
    
    // MARK: - Published Properties
    
    @Published var isPlaying = false
    @Published var trackTitle = ""
    @Published var artistName = ""
    @Published var albumArtwork: NSImage?
    @Published var playbackProgress: Double = 0.0
    @Published var duration: TimeInterval = 0
    @Published var currentTime: TimeInterval = 0
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var isUpdating = false
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateNowPlaying()
            }
        }
        updateNowPlaying()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Playback Control
    
    func playPause() {
        sendMediaKey(.playPause)
    }
    
    func nextTrack() {
        sendMediaKey(.next)
    }
    
    func previousTrack() {
        sendMediaKey(.previous)
    }
    
    // MARK: - Private Methods
    
    private func updateNowPlaying() {
        guard !isUpdating else { return }
        isUpdating = true
        updateViaAppleScript()
    }
    
    private func updateViaAppleScript() {
        // Music.app (Apple Music) 체크
        let musicScript = """
        tell application "System Events"
            if exists process "Music" then
                tell application "Music"
                    if player state is playing then
                        set trackName to name of current track
                        set trackArtist to artist of current track
                        return trackName & "|" & trackArtist & "|playing"
                    else if player state is paused then
                        set trackName to name of current track
                        set trackArtist to artist of current track
                        return trackName & "|" & trackArtist & "|paused"
                    end if
                end tell
            end if
        end tell
        return ""
        """
        
        // Spotify 체크
        let spotifyScript = """
        tell application "System Events"
            if exists process "Spotify" then
                tell application "Spotify"
                    if player state is playing then
                        set trackName to name of current track
                        set trackArtist to artist of current track
                        return trackName & "|" & trackArtist & "|playing"
                    else if player state is paused then
                        set trackName to name of current track
                        set trackArtist to artist of current track
                        return trackName & "|" & trackArtist & "|paused"
                    end if
                end tell
            end if
        end tell
        return ""
        """
        
        Task.detached { [weak self] in
            defer { Task { @MainActor in self?.isUpdating = false } }

            // Music 먼저 시도
            if let result = MediaManager.runAppleScript(musicScript), !result.isEmpty {
                await self?.parseMediaInfo(result)
                return
            }

            // Spotify 시도
            if let result = MediaManager.runAppleScript(spotifyScript), !result.isEmpty {
                await self?.parseMediaInfo(result)
                return
            }

            // 재생 중인 미디어 없음
            await MainActor.run {
                self?.isPlaying = false
                self?.trackTitle = ""
                self?.artistName = ""
            }
        }
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "NotchBar", category: "Media")

    nonisolated private static func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let output = script.executeAndReturnError(&error)

        if let error = error {
            logger.debug("AppleScript error: \(error)")
            return nil
        }

        return output.stringValue
    }
    
    private func parseMediaInfo(_ info: String) {
        let components = info.split(separator: "|").map(String.init)

        guard components.count >= 3 else { return }

        trackTitle = components[0]
        artistName = components[1]
        isPlaying = components[2] == "playing"
    }
    
    private func sendMediaKey(_ key: MediaKey) {
        guard AXIsProcessTrusted() else {
            Self.logger.warning("Accessibility permission required for media key control")
            return
        }

        let keyCode: Int32
        switch key {
        case .playPause: keyCode = 16  // NX_KEYTYPE_PLAY
        case .next: keyCode = 17       // NX_KEYTYPE_NEXT
        case .previous: keyCode = 18   // NX_KEYTYPE_PREVIOUS
        }
        
        // Key Down
        let keyDown = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xa00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyCode << 16) | (0xa << 8)),
            data2: -1
        )
        keyDown?.cgEvent?.post(tap: .cghidEventTap)
        
        // Key Up
        let keyUp = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xb00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyCode << 16) | (0xb << 8)),
            data2: -1
        )
        keyUp?.cgEvent?.post(tap: .cghidEventTap)
    }
    
    enum MediaKey {
        case playPause
        case next
        case previous
    }
}
