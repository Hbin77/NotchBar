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
    private var currentTrackId = ""

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
        Task.detached { [weak self] in
            let spotifyCheck = AppleScriptRunner.run("""
                tell application "System Events" to return exists process "Spotify"
            """)
            let musicCheck = AppleScriptRunner.run("""
                tell application "System Events" to return exists process "Music"
            """)

            if spotifyCheck == "true" {
                AppleScriptRunner.run("tell application \"Spotify\" to playpause")
            } else if musicCheck == "true" {
                AppleScriptRunner.run("tell application \"Music\" to playpause")
            } else {
                AppleScriptRunner.run("""
                    tell application "Music"
                        activate
                        play
                    end tell
                """)
            }

            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run { self?.updateNowPlaying() }
        }
    }

    func nextTrack() {
        Task.detached { [weak self] in
            let spotifyCheck = AppleScriptRunner.run("""
                tell application "System Events" to return exists process "Spotify"
            """)
            if spotifyCheck == "true" {
                AppleScriptRunner.run("tell application \"Spotify\" to next track")
            } else {
                AppleScriptRunner.run("tell application \"Music\" to next track")
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run { self?.updateNowPlaying() }
        }
    }

    func previousTrack() {
        Task.detached { [weak self] in
            let spotifyCheck = AppleScriptRunner.run("""
                tell application "System Events" to return exists process "Spotify"
            """)
            if spotifyCheck == "true" {
                AppleScriptRunner.run("tell application \"Spotify\" to previous track")
            } else {
                AppleScriptRunner.run("tell application \"Music\" to back track")
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run { self?.updateNowPlaying() }
        }
    }

    // MARK: - Private Methods

    private func updateNowPlaying() {
        guard !isUpdating else { return }
        isUpdating = true
        updateViaAppleScript()
    }

    private func updateViaAppleScript() {
        let musicScript = """
        tell application "System Events"
            if exists process "Music" then
                tell application "Music"
                    if player state is playing or player state is paused then
                        set trackName to name of current track
                        set trackArtist to artist of current track
                        set trackAlbum to album of current track
                        set trackId to database ID of current track as text
                        if player state is playing then
                            set pState to "playing"
                        else
                            set pState to "paused"
                        end if
                        return trackName & "|" & trackArtist & "|" & pState & "|" & trackAlbum & "|" & trackId & "|music"
                    end if
                end tell
            end if
        end tell
        return ""
        """

        let spotifyScript = """
        tell application "System Events"
            if exists process "Spotify" then
                tell application "Spotify"
                    if player state is playing or player state is paused then
                        set trackName to name of current track
                        set trackArtist to artist of current track
                        set trackAlbum to album of current track
                        set trackId to id of current track
                        set artUrl to artwork url of current track
                        if player state is playing then
                            set pState to "playing"
                        else
                            set pState to "paused"
                        end if
                        return trackName & "|" & trackArtist & "|" & pState & "|" & trackAlbum & "|" & trackId & "|spotify|" & artUrl
                    end if
                end tell
            end if
        end tell
        return ""
        """

        Task.detached { [weak self] in
            defer { Task { @MainActor in self?.isUpdating = false } }

            if let result = AppleScriptRunner.run(musicScript), !result.isEmpty {
                await self?.parseMediaInfo(result)
                return
            }

            if let result = AppleScriptRunner.run(spotifyScript), !result.isEmpty {
                await self?.parseMediaInfo(result)
                return
            }

            await MainActor.run {
                self?.isPlaying = false
                self?.trackTitle = ""
                self?.artistName = ""
                self?.albumArtwork = nil
            }
        }
    }

    private func parseMediaInfo(_ info: String) {
        let components = info.split(separator: "|", omittingEmptySubsequences: false).map(String.init)

        guard components.count >= 3 else { return }

        let newTitle = components[0]
        let newArtist = components[1]
        let newIsPlaying = components[2] == "playing"
        let trackId = components.count > 4 ? components[4] : ""
        let source = components.count > 5 ? components[5] : ""
        let artUrl = components.count > 6 ? components[6] : ""

        trackTitle = newTitle
        artistName = newArtist
        isPlaying = newIsPlaying

        if trackId != currentTrackId {
            currentTrackId = trackId
            loadArtwork(source: source, artworkUrl: artUrl)
        }
    }

    private func loadArtwork(source: String, artworkUrl: String) {
        if source == "spotify" && !artworkUrl.isEmpty {
            // Spotify: URLSession async로 이미지 다운로드
            Task.detached { [weak self] in
                guard let url = URL(string: artworkUrl) else { return }
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    guard let image = NSImage(data: data) else { return }
                    await MainActor.run { self?.albumArtwork = image }
                } catch {
                    await MainActor.run { self?.albumArtwork = nil }
                }
            }
        } else if source == "music" {
            // Apple Music: AppleScript로 아트워크를 임시 파일로 저장
            Task.detached { [weak self] in
                let saveScript = """
                tell application "Music"
                    try
                        set artData to data of artwork 1 of current track
                        set tmpPath to (POSIX path of (path to temporary items)) & "notchbar_art.jpg"
                        set fileRef to open for access tmpPath with write permission
                        set eof fileRef to 0
                        write artData to fileRef
                        close access fileRef
                        return tmpPath
                    on error
                        return ""
                    end try
                end tell
                """

                if let path = AppleScriptRunner.run(saveScript), !path.isEmpty {
                    let image = NSImage(contentsOfFile: path)
                    await MainActor.run { self?.albumArtwork = image }
                } else {
                    await MainActor.run { self?.albumArtwork = nil }
                }
            }
        }
    }

}
