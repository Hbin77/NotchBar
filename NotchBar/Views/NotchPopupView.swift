//
//  NotchPopupView.swift
//  NotchBar
//
//  2가지 상태:
//  - 접힌 상태: 노치 안에 앨범아트 + 이퀄라이저 아이콘 (순수 검정)
//  - 펼친 상태: 큰 둥근 패널에 모든 위젯 (순수 검정)
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
            // 배경 — 항상 순수 검정 (노치와 동일 색상)
            if viewModel.isExpanded {
                expandedBackground
            } else {
                collapsedBackground
            }

            // 콘텐츠
            if viewModel.isExpanded {
                expandedContent
                    .transition(.opacity)
            } else {
                collapsedContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isExpanded)
        .onAppear { loadSettings() }
    }

    // MARK: - 접힌 상태 (노치 안)

    private var collapsedBackground: some View {
        // 노치와 동일한 검정 + 하단만 둥글게 — 노치가 확장된 것처럼 보임
        UnevenRoundedRectangle(
            topLeadingRadius: 0, bottomLeadingRadius: 14,
            bottomTrailingRadius: 14, topTrailingRadius: 0
        )
        .fill(Color.black)
    }

    private var collapsedContent: some View {
        HStack {
            // 왼쪽: 앨범아트
            if let art = media.albumArtwork {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Spacer()

            // 오른쪽: 이퀄라이저 아이콘 (재생 중일 때)
            if media.isPlaying {
                Image(systemName: "waveform")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .symbolEffect(.variableColor.iterative, isActive: true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    // MARK: - 펼친 상태 (큰 패널)

    private var expandedBackground: some View {
        RoundedRectangle(cornerRadius: 26)
            .fill(Color.black)
            .shadow(color: .black.opacity(0.6), radius: 30, y: 10)
    }

    private var expandedContent: some View {
        VStack(spacing: 0) {
            // 상단 여백 (노치/메뉴바 영역)
            Spacer().frame(height: 44)

            // 미디어 플레이어
            mediaSection
                .padding(.horizontal, 20)

            Spacer().frame(height: 16)

            // 구분선
            thinLine

            Spacer().frame(height: 14)

            // 정보 카드 행
            HStack(spacing: 12) {
                weatherCard
                calendarCard
                systemCard
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 14)

            thinLine

            Spacer().frame(height: 12)

            // 하단 도구
            toolsRow
                .padding(.horizontal, 20)

            Spacer().frame(height: 16)
        }
        .foregroundColor(.white)
    }

    // MARK: - Media Section

    private var mediaSection: some View {
        HStack(spacing: 14) {
            // 앨범아트
            Group {
                if let art = media.albumArtwork {
                    Image(nsImage: art).resizable().aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Color.white.opacity(0.06)
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.2))
                    }
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(media.trackTitle.isEmpty ? "음악을 재생하세요" : media.trackTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(media.trackTitle.isEmpty ? .white.opacity(0.3) : .white)

                if !media.artistName.isEmpty {
                    Text(media.artistName)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }

                Spacer().frame(height: 4)

                HStack(spacing: 20) {
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
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: weather.condition.icon)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 16))
                Text(String(format: "%.0f°", weather.temperature))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
            }
            Text(weather.conditionDescription)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.05)))
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: "calendar").font(.system(size: 12)).foregroundColor(.cyan)
                if let event = calendar.upcomingEvent {
                    Text(event.title)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                } else {
                    Text("일정 없음")
                        .font(.system(size: 11))
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
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.05)))
    }

    private var systemCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                sysChip(String(format: "%.0f%%", system.cpuUsage), .green)
                sysChip(formatGB(system.memoryUsed), .orange)
            }
            HStack(spacing: 3) {
                Image(systemName: system.isCharging ? "bolt.fill" : "battery.75")
                    .font(.system(size: 9))
                    .foregroundColor(.green)
                Text("\(system.batteryLevel)%")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.05)))
    }

    // MARK: - Tools Row

    private var toolsRow: some View {
        HStack(spacing: 10) {
            // 볼륨 슬라이더
            HStack(spacing: 4) {
                Image(systemName: "speaker.fill").font(.system(size: 9)).foregroundColor(.white.opacity(0.35))
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
            Text(val).font(.system(size: 10, weight: .medium, design: .rounded))
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
        Rectangle().fill(.white.opacity(0.06)).frame(height: 0.5).padding(.horizontal, 20)
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
