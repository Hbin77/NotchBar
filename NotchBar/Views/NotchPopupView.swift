//
//  NotchPopupView.swift
//  NotchBar
//
//  노치에서 확장되는 팝업 — 섹션별 카드 디자인
//
//  구조:
//  ╭──────╮
//  │ stem │
//  ╭╯      ╰╮
//  │ 🎵 음악  │  ← Now Playing 섹션
//  │─────────│
//  │ 🌤 │ 📅  │  ← 날씨 + 캘린더 섹션
//  │─────────│
//  │ 💻 시스템 │  ← 시스템 모니터 섹션
//  │─────────│
//  │ 🎛 제어판 │  ← 볼륨, 밝기, 토글
//  ╰─────────╯
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
    @State private var contentVisible = false

    var body: some View {
        ZStack {
            if viewModel.isExpanded {
                expandedPanel
                    .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .top)))
            }
        }
        .animation(NotchDesign.Anim.expand, value: viewModel.isExpanded)
        .onChange(of: viewModel.isExpanded) { expanded in
            if expanded {
                loadSettings()
                withAnimation(NotchDesign.Anim.contentAppear.delay(0.06)) {
                    contentVisible = true
                }
            } else {
                contentVisible = false
            }
        }
    }

    // MARK: - Panel

    private var expandedPanel: some View {
        ZStack {
            notchBackground
            panelContent
        }
    }

    private var notchBackground: some View {
        let shape = NotchConnectedShape(
            notchWidth: viewModel.notchWidth,
            stemHeight: viewModel.stemHeight
        )
        return shape
            .fill(Color.black.opacity(0.92))
            .background(shape.fill(.ultraThinMaterial))
            .clipShape(shape)
            .overlay(
                shape.stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.15), .white.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
            )
            .shadow(color: .black.opacity(0.55), radius: 35, y: 12)
    }

    // MARK: - Content

    private var panelContent: some View {
        VStack(spacing: 0) {
            // stem + S-curve 여백
            Spacer().frame(height: viewModel.stemHeight + 28)

            // 섹션들
            VStack(spacing: NotchDesign.Spacing.sm + 2) {
                nowPlayingSection
                infoRow
                systemSection
                controlSection
            }
            .padding(.horizontal, NotchDesign.Spacing.xl)
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : -6)

            Spacer(minLength: NotchDesign.Spacing.lg)
        }
        .foregroundColor(.white)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 🎵 Now Playing 섹션
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var nowPlayingSection: some View {
        HStack(spacing: NotchDesign.Spacing.md) {
            // 앨범아트
            Group {
                if let art = media.albumArtwork {
                    Image(nsImage: art).resizable().aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "music.note")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.25))
                    }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.3), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(media.trackTitle.isEmpty ? "재생 중인 음악 없음" : media.trackTitle)
                    .font(NotchDesign.Font.title)
                    .lineLimit(1)
                    .foregroundColor(media.trackTitle.isEmpty ? .white.opacity(0.3) : .white)

                if !media.artistName.isEmpty {
                    Text(media.artistName)
                        .font(NotchDesign.Font.caption)
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }

                Spacer().frame(height: 2)

                // 재생 컨트롤
                HStack(spacing: 18) {
                    mediaBtn("backward.fill", 13) { media.previousTrack() }
                    mediaBtn(media.isPlaying ? "pause.fill" : "play.fill", 18, primary: true) { media.playPause() }
                    mediaBtn("forward.fill", 13) { media.nextTrack() }
                }
            }

            Spacer()
        }
        .sectionCard()
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 🌤📅 날씨 + 캘린더 섹션
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var infoRow: some View {
        HStack(spacing: NotchDesign.Spacing.sm + 2) {
            // 날씨 카드
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 8))
                    Text(weather.locationName)
                        .font(NotchDesign.Font.captionSecondary)
                }
                .foregroundColor(.white.opacity(0.35))

                HStack(spacing: 6) {
                    Image(systemName: weather.condition.icon)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 20))
                    Text(String(format: "%.0f°", weather.temperature))
                        .font(.system(size: 22, weight: .light, design: .rounded))
                }

                Text(weather.conditionDescription)
                    .font(NotchDesign.Font.captionSecondary)
                    .foregroundColor(.white.opacity(0.4))
            }
            .sectionCard()

            // 캘린더 카드
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                    Text("오늘 일정")
                        .font(NotchDesign.Font.captionSecondary)
                        .foregroundColor(.white.opacity(0.35))
                }

                if let event = calendar.upcomingEvent {
                    Text(event.title)
                        .font(NotchDesign.Font.caption)
                        .lineLimit(1)
                    Text(event.timeString)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                } else {
                    Text("일정 없음")
                        .font(NotchDesign.Font.body)
                        .foregroundColor(.white.opacity(0.3))
                    Text(" ")
                        .font(NotchDesign.Font.captionSecondary)
                }
            }
            .sectionCard()
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 💻 시스템 모니터 섹션
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var systemSection: some View {
        HStack(spacing: NotchDesign.Spacing.lg) {
            // CPU
            statItem(
                icon: "cpu",
                label: "CPU",
                value: String(format: "%.0f%%", system.cpuUsage),
                progress: system.cpuUsage / 100,
                color: system.cpuUsage > 80 ? .red : system.cpuUsage > 50 ? .orange : .green
            )

            thinDivider

            // Memory
            statItem(
                icon: "memorychip",
                label: "MEM",
                value: formatGB(system.memoryUsed),
                progress: system.memoryUsage / 100,
                color: system.memoryUsage > 80 ? .red : system.memoryUsage > 60 ? .orange : .blue
            )

            thinDivider

            // Battery
            HStack(spacing: 6) {
                Image(systemName: system.isCharging ? "battery.100.bolt" : "battery.75")
                    .font(.system(size: 14))
                    .foregroundColor(system.isCharging ? .green : system.batteryLevel <= 20 ? .red : .white.opacity(0.6))
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(system.batteryLevel)%")
                        .font(NotchDesign.Font.monoRounded)
                    if !system.batteryTimeRemaining.isEmpty {
                        Text(system.batteryTimeRemaining)
                            .font(NotchDesign.Font.captionSecondary)
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
            }
        }
        .sectionCard()
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 🎛 제어판 섹션
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var controlSection: some View {
        HStack(spacing: 0) {
            // 볼륨 슬라이더
            HStack(spacing: 6) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.35))
                miniSlider(value: $volume) { setVolume($0) }
            }

            Spacer()

            // 빠른 토글
            HStack(spacing: 8) {
                toggleBtn("moon.fill", "다크", isDarkMode) { toggleDarkMode() }
                toggleBtn("camera.fill", "캡처", false) { takeScreenshot() }
                toggleBtn("gear", "설정", false) { openSettings() }
            }
        }
        .sectionCard()
    }

    // MARK: - Components

    private func mediaBtn(_ icon: String, _ size: CGFloat, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: primary ? .semibold : .regular))
                .foregroundColor(.white.opacity(primary ? 0.95 : 0.55))
                .frame(width: primary ? 36 : 26, height: primary ? 36 : 26)
                .background(Circle().fill(.white.opacity(primary ? 0.12 : 0)))
        }
        .buttonStyle(.plain)
    }

    private func statItem(icon: String, label: String, value: String, progress: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            // 원형 프로그레스
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.06), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: min(progress, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(color.opacity(0.8))
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(NotchDesign.Font.captionSecondary)
                    .foregroundColor(.white.opacity(0.35))
                Text(value)
                    .font(NotchDesign.Font.monoRounded)
            }
        }
    }

    private func toggleBtn(_ icon: String, _ label: String, _ active: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 2) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(active ? .white : .white.opacity(0.5))
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(active ? Color.accentColor : .white.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.3))
        }
    }

    private func miniSlider(value: Binding<Double>, onChange: @escaping (Double) -> Void) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.08)).frame(height: 3)
                Capsule().fill(Color.accentColor.opacity(0.6))
                    .frame(width: max(w * value.wrappedValue, 3), height: 3)
                Circle().fill(.white).frame(width: 10, height: 10)
                    .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
                    .offset(x: w * value.wrappedValue - 5)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                let v = min(max(g.location.x / w, 0), 1)
                value.wrappedValue = v; onChange(v)
            })
        }
        .frame(width: 100, height: 16)
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.06))
            .frame(width: 0.5, height: 28)
    }

    private func formatGB(_ bytes: UInt64) -> String {
        String(format: "%.1fG", Double(bytes) / 1_073_741_824)
    }

    // MARK: - Actions

    private func loadSettings() {
        isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if let r = AppleScriptRunner.run("output volume of (get volume settings)"), let v = Int(r) {
            volume = Double(v) / 100
        }
    }

    private func setVolume(_ v: Double) {
        let clamped = min(max(Int(v * 100), 0), 100)
        AppleScriptRunner.run("set volume output volume \(clamped)")
    }

    private func toggleDarkMode() {
        isDarkMode.toggle()
        AppleScriptRunner.run("tell application \"System Events\" to tell appearance preferences to set dark mode to \(isDarkMode)")
    }

    private func takeScreenshot() {
        AppleScriptRunner.run("tell application \"System Events\" to keystroke \"4\" using {command down, shift down}")
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

// MARK: - Section Card Modifier

private struct SectionCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(NotchDesign.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: NotchDesign.CornerRadius.card)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: NotchDesign.CornerRadius.card)
                    .stroke(.white.opacity(0.06), lineWidth: 0.5)
            )
    }
}

private extension View {
    func sectionCard() -> some View {
        modifier(SectionCardModifier())
    }
}
