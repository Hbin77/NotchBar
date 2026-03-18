//
//  NotchPopupView.swift
//  NotchBar
//
//  노치에서 자연스럽게 확장되는 팝업 패널
//  - 접힌 상태: 숨김
//  - 펼친 상태: 노치 연결 Shape + 위젯 패널
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
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .animation(NotchDesign.Anim.expand, value: viewModel.isExpanded)
        .onChange(of: viewModel.isExpanded) { expanded in
            if expanded {
                loadSettings()
                withAnimation(NotchDesign.Anim.contentAppear.delay(0.08)) {
                    contentVisible = true
                }
            } else {
                contentVisible = false
            }
        }
    }

    // MARK: - Expanded Panel

    private var expandedPanel: some View {
        ZStack {
            // 노치 연결 배경
            notchBackground

            // 콘텐츠 (노치 stem 아래에 배치)
            VStack(spacing: 0) {
                // 노치 stem 영역 (빈 공간)
                Spacer()
                    .frame(height: viewModel.menuBarHeight + 18)

                // 메인 콘텐츠
                expandedContent
                    .opacity(contentVisible ? 1 : 0)
                    .offset(y: contentVisible ? 0 : -8)
            }
        }
    }

    private var notchBackground: some View {
        NotchConnectedShape(
            notchWidth: viewModel.notchWidth,
            notchHeight: viewModel.menuBarHeight,
            cornerRadius: NotchDesign.CornerRadius.notch
        )
        .fill(Color.black.opacity(0.92))
        .background(
            NotchConnectedShape(
                notchWidth: viewModel.notchWidth,
                notchHeight: viewModel.menuBarHeight,
                cornerRadius: NotchDesign.CornerRadius.notch
            )
            .fill(.ultraThinMaterial)
        )
        .clipShape(
            NotchConnectedShape(
                notchWidth: viewModel.notchWidth,
                notchHeight: viewModel.menuBarHeight,
                cornerRadius: NotchDesign.CornerRadius.notch
            )
        )
        .overlay(
            NotchConnectedShape(
                notchWidth: viewModel.notchWidth,
                notchHeight: viewModel.menuBarHeight,
                cornerRadius: NotchDesign.CornerRadius.notch
            )
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.12), .white.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 0.5
            )
        )
        .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
    }

    // MARK: - Content

    private var expandedContent: some View {
        VStack(spacing: 0) {
            // 미디어 플레이어
            mediaSection
                .padding(.horizontal, NotchDesign.Spacing.xl)

            Spacer().frame(height: NotchDesign.Spacing.lg)

            thinLine

            Spacer().frame(height: NotchDesign.Spacing.md + 2)

            // 정보 카드 행
            HStack(spacing: NotchDesign.Spacing.md) {
                weatherCard
                calendarCard
                systemCard
            }
            .padding(.horizontal, NotchDesign.Spacing.xl)

            Spacer().frame(height: NotchDesign.Spacing.md + 2)

            thinLine

            Spacer().frame(height: NotchDesign.Spacing.md)

            // 하단 도구
            toolsRow
                .padding(.horizontal, NotchDesign.Spacing.xl)

            Spacer().frame(height: NotchDesign.Spacing.lg)
        }
        .foregroundColor(.white)
    }

    // MARK: - Media Section

    private var mediaSection: some View {
        HStack(spacing: NotchDesign.Spacing.md + 2) {
            // 앨범아트
            Group {
                if let art = media.albumArtwork {
                    Image(nsImage: art).resizable().aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.2))
                    }
                }
            }
            .frame(width: 68, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: NotchDesign.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: NotchDesign.CornerRadius.card)
                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(media.trackTitle.isEmpty ? "음악을 재생하세요" : media.trackTitle)
                    .font(NotchDesign.Font.title)
                    .lineLimit(1)
                    .foregroundColor(media.trackTitle.isEmpty ? .white.opacity(0.3) : .white)

                if !media.artistName.isEmpty {
                    Text(media.artistName)
                        .font(NotchDesign.Font.caption)
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }

                Spacer().frame(height: NotchDesign.Spacing.xs)

                HStack(spacing: NotchDesign.Spacing.xl) {
                    ctrlBtn("backward.fill", 13) { media.previousTrack() }
                    ctrlBtn(media.isPlaying ? "pause.fill" : "play.fill", 17, primary: true) { media.playPause() }
                    ctrlBtn("forward.fill", 13) { media.nextTrack() }
                }
            }
            Spacer()
        }
    }

    // MARK: - Info Cards

    private var weatherCard: some View {
        VStack(alignment: .leading, spacing: NotchDesign.Spacing.xs) {
            HStack(spacing: 5) {
                Image(systemName: weather.condition.icon)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 16))
                Text(String(format: "%.0f°", weather.temperature))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
            }
            Text(weather.conditionDescription)
                .font(NotchDesign.Font.tiny)
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NotchDesign.Spacing.sm + 2)
        .background(RoundedRectangle(cornerRadius: NotchDesign.CornerRadius.button).fill(.white.opacity(0.05)))
        .overlay(
            RoundedRectangle(cornerRadius: NotchDesign.CornerRadius.button)
                .stroke(.white.opacity(0.06), lineWidth: 0.5)
        )
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: NotchDesign.Spacing.xs) {
            HStack(spacing: 5) {
                Image(systemName: "calendar").font(.system(size: 12)).foregroundColor(.cyan)
                if let event = calendar.upcomingEvent {
                    Text(event.title)
                        .font(NotchDesign.Font.caption)
                        .lineLimit(1)
                } else {
                    Text("일정 없음")
                        .font(NotchDesign.Font.caption)
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            if let event = calendar.upcomingEvent {
                Text(event.timeString)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NotchDesign.Spacing.sm + 2)
        .background(RoundedRectangle(cornerRadius: NotchDesign.CornerRadius.button).fill(.white.opacity(0.05)))
        .overlay(
            RoundedRectangle(cornerRadius: NotchDesign.CornerRadius.button)
                .stroke(.white.opacity(0.06), lineWidth: 0.5)
        )
    }

    private var systemCard: some View {
        VStack(alignment: .leading, spacing: NotchDesign.Spacing.xs) {
            HStack(spacing: NotchDesign.Spacing.sm) {
                sysChip(String(format: "%.0f%%", system.cpuUsage), .green)
                sysChip(formatGB(system.memoryUsed), .orange)
            }
            HStack(spacing: 3) {
                Image(systemName: system.isCharging ? "bolt.fill" : "battery.75")
                    .font(NotchDesign.Font.tiny)
                    .foregroundColor(.green)
                Text("\(system.batteryLevel)%")
                    .font(NotchDesign.Font.monoRounded)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NotchDesign.Spacing.sm + 2)
        .background(RoundedRectangle(cornerRadius: NotchDesign.CornerRadius.button).fill(.white.opacity(0.05)))
        .overlay(
            RoundedRectangle(cornerRadius: NotchDesign.CornerRadius.button)
                .stroke(.white.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - Tools Row

    private var toolsRow: some View {
        HStack(spacing: NotchDesign.Spacing.sm + 2) {
            HStack(spacing: NotchDesign.Spacing.xs) {
                Image(systemName: "speaker.fill")
                    .font(NotchDesign.Font.tiny)
                    .foregroundColor(.white.opacity(0.35))
                miniSlider(value: $volume) { setVolume($0) }
            }

            Spacer()

            toolBtn("moon.fill", isDarkMode) { toggleDarkMode() }
            toolBtn("camera.fill", false) { takeScreenshot() }
            toolBtn("gear", false) { openSettings() }
        }
    }

    // MARK: - Subviews

    private func ctrlBtn(_ icon: String, _ size: CGFloat, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: primary ? .semibold : .regular))
                .foregroundColor(.white.opacity(primary ? 0.95 : 0.55))
                .frame(width: primary ? 34 : 24, height: primary ? 34 : 24)
                .background(Circle().fill(.white.opacity(primary ? 0.12 : 0)))
        }
        .buttonStyle(.plain)
    }

    private func toolBtn(_ icon: String, _ active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(active ? .white : .white.opacity(0.5))
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 8).fill(active ? Color.accentColor : .white.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    private func sysChip(_ val: String, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color.opacity(0.7)).frame(width: 5, height: 5)
            Text(val).font(NotchDesign.Font.monoRounded)
        }
    }

    private func miniSlider(value: Binding<Double>, onChange: @escaping (Double) -> Void) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.08)).frame(height: 3)
                Capsule().fill(Color.accentColor.opacity(0.6)).frame(width: max(w * value.wrappedValue, 3), height: 3)
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
        .frame(width: 90, height: 16)
    }

    private var thinLine: some View {
        Rectangle().fill(.white.opacity(0.06)).frame(height: 0.5).padding(.horizontal, NotchDesign.Spacing.xl)
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
