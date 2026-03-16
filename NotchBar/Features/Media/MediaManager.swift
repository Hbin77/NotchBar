//
//  MediaManager.swift
//  NotchBar
//
//  미디어 재생 상태 모니터링 (Now Playing)
//

import Foundation
import AppKit
import Combine

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
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        // 1초마다 Now Playing 정보 업데이트
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNowPlaying()
        }
        
        // 즉시 한번 실행
        updateNowPlaying()
        
        print("🎵 미디어 모니터링 시작")
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        print("🎵 미디어 모니터링 종료")
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
        // MRMediaRemote 프레임워크 사용 (Private API)
        // 실제 구현에서는 MediaRemote.framework 링크 필요
        
        // 대안: AppleScript 사용
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
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Music 먼저 시도
            if let result = self?.runAppleScript(musicScript), !result.isEmpty {
                self?.parseMediaInfo(result)
                return
            }
            
            // Spotify 시도
            if let result = self?.runAppleScript(spotifyScript), !result.isEmpty {
                self?.parseMediaInfo(result)
                return
            }
            
            // 재생 중인 미디어 없음
            DispatchQueue.main.async {
                self?.isPlaying = false
                self?.trackTitle = ""
                self?.artistName = ""
            }
        }
    }
    
    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let output = script.executeAndReturnError(&error)
        
        if let error = error {
            print("AppleScript Error: \(error)")
            return nil
        }
        
        return output.stringValue
    }
    
    private func parseMediaInfo(_ info: String) {
        let components = info.split(separator: "|").map(String.init)
        
        guard components.count >= 3 else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.trackTitle = components[0]
            self?.artistName = components[1]
            self?.isPlaying = components[2] == "playing"
        }
    }
    
    private func sendMediaKey(_ key: MediaKey) {
        // 미디어 키 이벤트 전송
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
