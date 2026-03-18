//
//  NotchPopupView.swift
//  NotchBar
//
//  좌우 분할 카드 — 왼쪽: 앨범아트 풀사이즈 / 오른쪽: 모든 정보
//

import SwiftUI

struct NotchPopupView: View {

    @ObservedObject var viewModel: NotchViewModel

    @StateObject private var media = MediaManager.shared
    @StateObject private var weather = WeatherManager.shared
    @StateObject private var system = SystemMonitor.shared
    @StateObject private var calendar = CalendarManager.shared

    @State private var volume: Double = 0.5
    @State private var isDarkMode = false

    var body: some View {
        ZStack {
            if viewModel.isExpanded {
                // 배경
                RoundedRectangle(cornerRadius: 22)
                    .fill(.black.opacity(0.85))
                    .background(RoundedRectangle(cornerRadius: 22).fill(.ultraThinMaterial))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 30, y: 10)

                // 좌우 분할
                HStack(spacing: 0) {
                    leftPanel
                        .frame(width: 170)

                    rightPanel
                        .frame(maxWidth: .infinity)
                }
                .padding(10)
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.isExpanded)
        .onAppear { loadSettings() }
    }

    // MARK: - Left Panel (앨범아트 + 트랙정보 오버레이)

    private var leftPanel: some View {
        ZStack(alignment: .bottom) {
            // 앨범 아트 풀사이즈
            Group {
                if let art = media.albumArtwork {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(
                        colors: [.indigo.opacity(0.6), .purple.opacity(0.4), .blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 36, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.2))
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 하단 오버레이
            VStack(spacing: 8) {
                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text(media.trackTitle.isEmpty ? "No Music" : media.trackTitle)
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                    if !media.artistName.isEmpty {
                        Text(media.artistName)
                            .font(.system(size: 9))
                            .opacity(0.7)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 16) {
                    btn("backward.fill", 12) { media.previousTrack() }
                    btn(media.isPlaying ? "pause.fill" : "play.fill", 15, bg: true) { media.playPause() }
                    btn("forward.fill", 12) { media.nextTrack() }
                }
            }
            .padding(12)
            .foregroundColor(.white)
            .background(
                LinearGradient(colors: [.clear, .black.opacity(0.75)],
                               startPoint: .top, endPoint: .bottom)
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.06), lineWidth: 0.5))
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 날씨
            HStack(spacing: 8) {
                Image(systemName: weather.condition.icon)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 24))
                VStack(alignment: .leading, spacing: 1) {
                    Text(String(format: "%.0f°", weather.temperature))
                        .font(.system(size: 22, weight: .light, design: .rounded))
                    Text(weather.conditionDescription + " · " + weather.locationName)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
            }

            Spacer()
            divider
            Spacer()

            // 일정
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.cyan.opacity(0.7))
                    .frame(width: 3, height: 30)
                if let event = calendar.upcomingEvent {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        Text(event.timeString + (event.isOngoing ? " · 진행 중" : ""))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }
                } else {
                    Text("오늘 남은 일정 없음")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.35))
                }
                Spacer()
            }

            Spacer()
            divider
            Spacer()

            // 시스템
            HStack(spacing: 14) {
                sysItem("cpu", String(format: "%.0f%%", system.cpuUsage), system.cpuUsage > 60 ? .orange : .green)
                sysItem("memorychip", formatGB(system.memoryUsed), system.memoryUsage > 70 ? .orange : .blue)
                sysItem(system.isCharging ? "bolt.fill" : "battery.75", "\(system.batteryLevel)%",
                        system.batteryLevel <= 20 ? .red : .green)
                Spacer()
            }

            Spacer()
            divider
            Spacer()

            // 도구
            HStack(spacing: 8) {
                miniSlider(icon: "speaker.fill", value: $volume) { setVolume($0) }
                Spacer()
                toolPill("moon.fill", isDarkMode) { toggleDarkMode() }
                toolPill("camera.fill", false) { takeScreenshot() }
                toolPill("gear", false) { openSettings() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .foregroundColor(.white)
    }

    // MARK: - Subviews

    private func btn(_ icon: String, _ size: CGFloat, bg: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: bg ? .semibold : .regular))
                .frame(width: bg ? 34 : 24, height: bg ? 34 : 24)
                .background(Circle().fill(.white.opacity(bg ? 0.2 : 0)))
        }
        .buttonStyle(.plain)
    }

    private func sysItem(_ icon: String, _ val: String, _ color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10)).foregroundColor(color)
            Text(val).font(.system(size: 12, weight: .medium, design: .rounded))
        }
    }

    private func toolPill(_ icon: String, _ active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(active ? .white : .white.opacity(0.5))
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7).fill(active ? Color.accentColor : .white.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    private func miniSlider(icon: String, value: Binding<Double>, onChange: @escaping (Double) -> Void) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9)).foregroundColor(.white.opacity(0.35))
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.08)).frame(height: 3)
                    Capsule().fill(Color.accentColor.opacity(0.6)).frame(width: max(w * value.wrappedValue, 3), height: 3)
                    Circle().fill(.white).frame(width: 9, height: 9)
                        .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                        .offset(x: w * value.wrappedValue - 4.5)
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                    let v = min(max(g.location.x / w, 0), 1)
                    value.wrappedValue = v; onChange(v)
                })
            }
            .frame(width: 80, height: 16)
        .clipped()
        }
    }

    private var divider: some View {
        Rectangle().fill(.white.opacity(0.06)).frame(height: 0.5)
    }

    private func formatGB(_ bytes: UInt64) -> String {
        String(format: "%.1fG", Double(bytes) / 1_073_741_824)
    }

    // MARK: - Actions

    private func loadSettings() {
        isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if let r = runAS("output volume of (get volume settings)"), let v = Int(r) { volume = Double(v) / 100 }
    }
    private func setVolume(_ v: Double) { runAS("set volume output volume \(Int(v * 100))") }
    private func toggleDarkMode() {
        isDarkMode.toggle()
        runAS("tell application \"System Events\" to tell appearance preferences to set dark mode to \(isDarkMode)")
    }
    private func takeScreenshot() {
        runAS("tell application \"System Events\" to keystroke \"4\" using {command down, shift down}")
    }
    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    @discardableResult private func runAS(_ s: String) -> String? {
        var e: NSDictionary?; guard let sc = NSAppleScript(source: s) else { return nil }
        return sc.executeAndReturnError(&e).stringValue
    }
}

#Preview {
    ZStack { Color.black
        NotchPopupView(viewModel: { let v = NotchViewModel(); v.isExpanded = true; return v }())
            .frame(width: 540, height: 280)
    }
}
