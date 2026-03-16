//
//  QuickSettingsView.swift
//  NotchBar
//
//  빠른 설정 (밝기, 볼륨, 다크모드 등)
//

import SwiftUI
import AppKit

struct QuickSettingsView: View {
    
    @State private var brightness: Double = 0.5
    @State private var volume: Double = 0.5
    @State private var isDarkMode: Bool = false
    
    var body: some View {
        HStack(spacing: 20) {
            // 밝기
            HStack(spacing: 8) {
                Image(systemName: "sun.min")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Slider(value: $brightness, in: 0...1)
                    .frame(width: 80)
                    .onChange(of: brightness) { _, newValue in
                        setBrightness(newValue)
                    }
                
                Image(systemName: "sun.max")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            // 볼륨
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Slider(value: $volume, in: 0...1)
                    .frame(width: 80)
                    .onChange(of: volume) { _, newValue in
                        setVolume(newValue)
                    }
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 빠른 토글 버튼들
            HStack(spacing: 12) {
                // 다크모드
                QuickToggleButton(
                    icon: isDarkMode ? "moon.fill" : "sun.max.fill",
                    isActive: isDarkMode,
                    action: toggleDarkMode
                )
                
                // 방해 금지
                QuickToggleButton(
                    icon: "moon.zzz.fill",
                    isActive: false,
                    action: toggleDoNotDisturb
                )
                
                // AirDrop
                QuickToggleButton(
                    icon: "airplayaudio",
                    isActive: false,
                    action: toggleAirDrop
                )
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    // MARK: - Settings Control
    
    private func loadCurrentSettings() {
        // 현재 다크모드 상태
        isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        
        // 현재 볼륨 (AppleScript)
        if let vol = getSystemVolume() {
            volume = vol
        }
    }
    
    private func setBrightness(_ value: Double) {
        // 밝기 조절 (IOKit 또는 AppleScript)
        let script = "tell application \"System Events\" to set brightness of first display to \(value)"
        runAppleScript(script)
    }
    
    private func setVolume(_ value: Double) {
        let volumePercent = Int(value * 100)
        let script = "set volume output volume \(volumePercent)"
        runAppleScript(script)
    }
    
    private func getSystemVolume() -> Double? {
        let script = "output volume of (get volume settings)"
        guard let result = runAppleScript(script) else { return nil }
        if let vol = Int(result) {
            return Double(vol) / 100.0
        }
        return nil
    }
    
    private func toggleDarkMode() {
        isDarkMode.toggle()
        let script = """
        tell application "System Events"
            tell appearance preferences
                set dark mode to \(isDarkMode ? "true" : "false")
            end tell
        end tell
        """
        runAppleScript(script)
    }
    
    private func toggleDoNotDisturb() {
        // 방해 금지 모드 토글 (macOS 12+에서는 Focus로 변경됨)
        let script = """
        tell application "System Events"
            keystroke "D" using {command down, shift down, control down}
        end tell
        """
        runAppleScript(script)
    }
    
    private func toggleAirDrop() {
        // Finder에서 AirDrop 열기
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app"))
        let script = "tell application \"Finder\" to activate"
        runAppleScript(script)
    }
    
    @discardableResult
    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let output = script.executeAndReturnError(&error)
        return output.stringValue
    }
}

// MARK: - QuickToggleButton

struct QuickToggleButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(isActive ? .white : .primary)
                .frame(width: 28, height: 28)
                .background(isActive ? Color.accentColor : Color.secondary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickSettingsView()
        .padding()
        .frame(width: 380)
        .background(.ultraThinMaterial)
}
