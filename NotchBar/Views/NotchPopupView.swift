//
//  NotchPopupView.swift
//  NotchBar
//
//  노치 팝업 — 3단 레이아웃: 미디어 / 정보 / 도구
//

import SwiftUI

struct NotchPopupView: View {

    @ObservedObject var viewModel: NotchViewModel

    @StateObject private var media = MediaManager.shared
    @StateObject private var weather = WeatherManager.shared
    @StateObject private var system = SystemMonitor.shared
    @StateObject private var calendar = CalendarManager.shared

    // 빠른 설정 상태
    @State private var volume: Double = 0.5
    @State private var brightness: Double = 0.5
    @State private var isDarkMode = false

    var body: some View {
        ZStack {
            if viewModel.isExpanded {
                background

                VStack(spacing: 12) {
                    // 1단: 미디어 플레이어
                    mediaSection

                    thinDivider

                    // 2단: 정보 카드 (날씨, 일정, 시스템)
                    infoCards

                    thinDivider

                    // 3단: 빠른 도구
                    toolsBar
                }
                .padding(16)
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.isExpanded)
        .onAppear { loadSettings() }
    }

    // MARK: - Background

    private var background: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.black.opacity(0.82))
            .background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .white.opacity(0.03)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
    }

    // MARK: - 1. Media Section

    private var mediaSection: some View {
        HStack(spacing: 14) {
            // 앨범 아트
            Group {
                if let art = media.albumArtwork {
                    Image(nsImage: art).resizable().aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        LinearGradient(colors: [.purple.opacity(0.5), .blue.opacity(0.4)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                        Image(systemName: "music.note")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.25), radius: 8, y: 3)

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)

                Text(media.trackTitle.isEmpty ? "음악을 재생하세요" : media.trackTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(media.trackTitle.isEmpty ? .white.opacity(0.35) : .white)

                if !media.artistName.isEmpty {
                    Text(media.artistName)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                        .padding(.top, 1)
                }

                Spacer(minLength: 0)

                HStack(spacing: 20) {
                    ctrlBtn("backward.fill", 14) { media.previousTrack() }
                    ctrlBtn(media.isPlaying ? "pause.fill" : "play.fill", 18, primary: true) { media.playPause() }
                    ctrlBtn("forward.fill", 14) { media.nextTrack() }
                }

                Spacer(minLength: 0)
            }
            .frame(height: 80)

            Spacer(minLength: 0)
        }
    }

    // MARK: - 2. Info Cards

    private var infoCards: some View {
        HStack(spacing: 10) {
            // 날씨
            infoCard {
                HStack(spacing: 6) {
                    Image(systemName: weather.condition.icon)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(String(format: "%.0f°", weather.temperature))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        Text(weather.conditionDescription)
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer(minLength: 0)
                }
            }

            // 일정
            infoCard {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.cyan.opacity(0.8))
                    VStack(alignment: .leading, spacing: 1) {
                        if let event = calendar.upcomingEvent {
                            Text(event.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(event.timeString)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                        } else {
                            Text("일정 없음")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.35))
                        }
                    }
                    Spacer(minLength: 0)
                }
            }

            // 시스템
            infoCard {
                HStack(spacing: 8) {
                    miniRing(system.cpuUsage / 100, "CPU", .green)
                    miniRing(system.memoryUsage / 100, "MEM", .orange)
                    Spacer(minLength: 0)
                    HStack(spacing: 2) {
                        Image(systemName: system.isCharging ? "bolt.fill" : "battery.75")
                            .font(.system(size: 9))
                            .foregroundColor(system.batteryLevel <= 20 ? .red : .green)
                        Text("\(system.batteryLevel)%")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    private func infoCard<C: View>(@ViewBuilder content: () -> C) -> some View {
        content()
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.06), lineWidth: 0.5))
            )
    }

    // MARK: - 3. Tools Bar

    private var toolsBar: some View {
        HStack(spacing: 14) {
            // 밝기 슬라이더
            HStack(spacing: 5) {
                Image(systemName: "sun.min").font(.system(size: 9)).foregroundColor(.white.opacity(0.35))
                miniSlider(value: $brightness) { setBrightness($0) }
                Image(systemName: "sun.max").font(.system(size: 9)).foregroundColor(.white.opacity(0.35))
            }

            // 볼륨 슬라이더
            HStack(spacing: 5) {
                Image(systemName: "speaker.fill").font(.system(size: 9)).foregroundColor(.white.opacity(0.35))
                miniSlider(value: $volume) { setVolume($0) }
                Image(systemName: "speaker.wave.3.fill").font(.system(size: 9)).foregroundColor(.white.opacity(0.35))
            }

            Spacer()

            // 빠른 액션 버튼들
            HStack(spacing: 8) {
                toolBtn("moon.fill", "다크", isDarkMode) { toggleDarkMode() }
                toolBtn("camera.fill", "캡처", false) { takeScreenshot() }
                toolBtn("timer", "타이머", false) { openTimer() }
                toolBtn("gear", "설정", false) { openSettings() }
            }
        }
    }

    private func toolBtn(_ icon: String, _ label: String, _ active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(active ? .white : .white.opacity(0.5))
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(active ? Color.accentColor : .white.opacity(0.06))
                    )
                Text(label)
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mini Slider

    private func miniSlider(value: Binding<Double>, onChange: @escaping (Double) -> Void) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.08)).frame(height: 4)
                Capsule().fill(Color.accentColor.opacity(0.7)).frame(width: max(w * value.wrappedValue, 4), height: 4)
                Circle().fill(.white).frame(width: 10, height: 10)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .offset(x: w * value.wrappedValue - 5)
            }
            .frame(height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let v = min(max(g.location.x / w, 0), 1)
                        value.wrappedValue = v
                        onChange(v)
                    }
            )
        }
        .frame(width: 70, height: 16)
    }

    // MARK: - Helpers

    private var thinDivider: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.clear, .white.opacity(0.06), .clear],
                                 startPoint: .leading, endPoint: .trailing))
            .frame(height: 0.5)
    }

    private func ctrlBtn(_ icon: String, _ size: CGFloat, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: primary ? .medium : .regular))
                .foregroundColor(.white.opacity(primary ? 0.95 : 0.55))
                .frame(width: primary ? 36 : 26, height: primary ? 36 : 26)
                .background(Circle().fill(.white.opacity(primary ? 0.12 : 0)))
        }
        .buttonStyle(.plain)
    }

    private func miniRing(_ value: Double, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 1) {
            ZStack {
                Circle().stroke(.white.opacity(0.06), lineWidth: 2)
                Circle().trim(from: 0, to: min(value, 1))
                    .stroke(color.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 20, height: 20)
            Text(label).font(.system(size: 7, weight: .medium)).foregroundColor(.white.opacity(0.3))
        }
    }

    // MARK: - Actions

    private func loadSettings() {
        isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if let v = getVolume() { volume = v }
    }

    private func setBrightness(_ val: Double) {
        runAS("tell application \"System Events\" to set brightness of first display to \(val)")
    }

    private func setVolume(_ val: Double) {
        runAS("set volume output volume \(Int(val * 100))")
    }

    private func getVolume() -> Double? {
        guard let r = runAS("output volume of (get volume settings)"), let v = Int(r) else { return nil }
        return Double(v) / 100
    }

    private func toggleDarkMode() {
        isDarkMode.toggle()
        runAS("""
        tell application "System Events" to tell appearance preferences to set dark mode to \(isDarkMode)
        """)
    }

    private func takeScreenshot() {
        // Cmd+Shift+4 시뮬레이션
        runAS("""
        tell application "System Events" to keystroke "4" using {command down, shift down}
        """)
    }

    private func openTimer() {
        NSWorkspace.shared.open(URL(string: "clock://timer")!)
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @discardableResult
    private func runAS(_ src: String) -> String? {
        var err: NSDictionary?
        guard let s = NSAppleScript(source: src) else { return nil }
        let o = s.executeAndReturnError(&err)
        return o.stringValue
    }
}

#Preview {
    ZStack {
        Color.black
        NotchPopupView(viewModel: {
            let vm = NotchViewModel()
            vm.isExpanded = true
            return vm
        }())
        .frame(width: 580, height: 340)
    }
}
