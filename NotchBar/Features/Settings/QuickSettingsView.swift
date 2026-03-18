//
//  QuickSettingsView.swift
//  NotchBar
//
//  빠른 설정 — 프리미엄 디자인
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
            SliderControl(
                value: $brightness,
                iconLow: "sun.min",
                iconHigh: "sun.max",
                onChange: setBrightness
            )

            // 볼륨
            SliderControl(
                value: $volume,
                iconLow: "speaker.fill",
                iconHigh: "speaker.wave.3.fill",
                onChange: setVolume
            )

            Spacer()

            // 빠른 토글 버튼들
            HStack(spacing: 10) {
                QuickToggle(
                    icon: isDarkMode ? "moon.fill" : "sun.max.fill",
                    label: "다크",
                    isActive: isDarkMode,
                    action: toggleDarkMode
                )

                QuickToggle(
                    icon: "moon.zzz.fill",
                    label: "집중",
                    isActive: false,
                    action: toggleDoNotDisturb
                )

                QuickToggle(
                    icon: "airplayaudio",
                    label: "AirDrop",
                    isActive: false,
                    action: toggleAirDrop
                )
            }
        }
        .onAppear { loadCurrentSettings() }
    }

    // MARK: - Settings Control

    private func loadCurrentSettings() {
        isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if let vol = getSystemVolume() { volume = vol }
    }

    private func setBrightness(_ value: Double) {
        let script = "tell application \"System Events\" to set brightness of first display to \(value)"
        runAppleScript(script)
    }

    private func setVolume(_ value: Double) {
        let script = "set volume output volume \(Int(value * 100))"
        runAppleScript(script)
    }

    private func getSystemVolume() -> Double? {
        guard let result = runAppleScript("output volume of (get volume settings)") else { return nil }
        if let vol = Int(result) { return Double(vol) / 100.0 }
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
        let script = """
        tell application "System Events"
            keystroke "D" using {command down, shift down, control down}
        end tell
        """
        runAppleScript(script)
    }

    private func toggleAirDrop() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app"))
        runAppleScript("tell application \"Finder\" to activate")
    }

    @discardableResult
    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let output = script.executeAndReturnError(&error)
        return output.stringValue
    }
}

// MARK: - Slider Control

private struct SliderControl: View {
    @Binding var value: Double
    let iconLow: String
    let iconHigh: String
    let onChange: (Double) -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconLow)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)

            CustomSlider(value: $value, onChange: onChange)
                .frame(width: 80)

            Image(systemName: iconHigh)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Custom Slider (Apple Control Center 스타일)

private struct CustomSlider: View {
    @Binding var value: Double
    let onChange: (Double) -> Void

    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let thumbX = width * value

            ZStack(alignment: .leading) {
                // 트랙 배경
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 4)

                // 채워진 부분
                Capsule()
                    .fill(Color.accentColor.opacity(0.8))
                    .frame(width: max(thumbX, 4), height: 4)

                // 썸
                Circle()
                    .fill(Color.white)
                    .frame(width: isDragging ? 14 : 12, height: isDragging ? 14 : 12)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .offset(x: thumbX - 6)
            }
            .frame(height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let newValue = min(max(gesture.location.x / width, 0), 1)
                        value = newValue
                        onChange(newValue)
                    }
                    .onEnded { _ in
                        withAnimation(NotchDesign.Anim.hover) {
                            isDragging = false
                        }
                    }
            )
        }
        .frame(height: 20)
    }
}

// MARK: - Quick Toggle Button

private struct QuickToggle: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 3) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(isActive ? .white : .secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isActive ? Color.accentColor : Color.white.opacity(isHovering ? 0.1 : 0.06))
                    )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(NotchDesign.Anim.hover) {
                    isHovering = hovering
                }
            }

            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    QuickSettingsView()
        .padding()
        .frame(width: 400)
        .background(Color.black.opacity(0.8))
}
