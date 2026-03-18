//
//  NotchPopupView.swift
//  NotchBar
//
//  노치에서 확장되는 팝업 — 스와이프 페이지 디자인
//  좌우 스와이프로 섹션 이동: 음악 → 정보 → 시스템 → 제어판
//

import SwiftUI

struct NotchPopupView: View {

    @ObservedObject var viewModel: NotchViewModel

    @StateObject private var media = MediaManager.shared
    @StateObject private var weather = WeatherManager.shared
    @StateObject private var system = SystemMonitor.shared
    @StateObject private var calendar = CalendarManager.shared

    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    @State private var volume: Double = 0.5
    @State private var isDarkMode = false
    @State private var contentVisible = false

    private let pageCount = 4
    private let pageLabels = ["음악", "정보", "시스템", "제어판"]
    private let pageIcons = ["music.note", "cloud.sun.fill", "cpu", "slider.horizontal.3"]

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
                currentPage = 0
                dragOffset = 0
            }
        }
    }

    // MARK: - Panel

    private var expandedPanel: some View {
        ZStack {
            notchBackground

            VStack(spacing: 0) {
                Spacer().frame(height: viewModel.stemHeight + 26)

                // 탭 인디케이터
                tabIndicator
                    .padding(.horizontal, NotchDesign.Spacing.xl)
                    .padding(.bottom, NotchDesign.Spacing.sm)

                // 페이지 콘텐츠
                pageContent
                    .opacity(contentVisible ? 1 : 0)
                    .offset(y: contentVisible ? 0 : -6)

                Spacer(minLength: NotchDesign.Spacing.md)

                // 페이지 도트
                pageDots
                    .padding(.bottom, NotchDesign.Spacing.md)
            }
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

    // MARK: - Tab Indicator

    private var tabIndicator: some View {
        HStack(spacing: 0) {
            ForEach(0..<pageCount, id: \.self) { i in
                Button {
                    withAnimation(NotchDesign.Anim.expand) {
                        currentPage = i
                        dragOffset = 0
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: pageIcons[i])
                            .font(.system(size: 9))
                        Text(pageLabels[i])
                            .font(NotchDesign.Font.caption)
                    }
                    .foregroundColor(currentPage == i ? .white : .white.opacity(0.35))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(currentPage == i ? Color.white.opacity(0.1) : .clear)
                    )
                }
                .buttonStyle(.plain)

                if i < pageCount - 1 { Spacer() }
            }
        }
    }

    // MARK: - Page Content (Swipeable)

    private var pageContent: some View {
        GeometryReader { geo in
            let pageWidth = geo.size.width
            let totalOffset = -CGFloat(currentPage) * pageWidth + dragOffset

            HStack(spacing: 0) {
                // Page 0: 음악
                musicPage
                    .frame(width: pageWidth)
                    .padding(.horizontal, NotchDesign.Spacing.xl)

                // Page 1: 정보 (날씨 + 캘린더)
                infoPage
                    .frame(width: pageWidth)
                    .padding(.horizontal, NotchDesign.Spacing.xl)

                // Page 2: 시스템
                systemPage
                    .frame(width: pageWidth)
                    .padding(.horizontal, NotchDesign.Spacing.xl)

                // Page 3: 제어판
                controlPage
                    .frame(width: pageWidth)
                    .padding(.horizontal, NotchDesign.Spacing.xl)
            }
            .offset(x: totalOffset)
            .animation(NotchDesign.Anim.expand, value: currentPage)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = pageWidth * 0.2
                        let velocity = value.predictedEndTranslation.width

                        withAnimation(NotchDesign.Anim.expand) {
                            if value.translation.width < -threshold || velocity < -200 {
                                currentPage = min(currentPage + 1, pageCount - 1)
                            } else if value.translation.width > threshold || velocity > 200 {
                                currentPage = max(currentPage - 1, 0)
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
        .clipped()
        .foregroundColor(.white)
    }

    // MARK: - Page Dots

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { i in
                Circle()
                    .fill(currentPage == i ? Color.white.opacity(0.8) : Color.white.opacity(0.2))
                    .frame(width: currentPage == i ? 6 : 4, height: currentPage == i ? 6 : 4)
                    .animation(NotchDesign.Anim.quick, value: currentPage)
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Page 0: 🎵 음악
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var musicPage: some View {
        VStack(spacing: NotchDesign.Spacing.lg) {
            // 대형 앨범아트
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
                            .font(.system(size: 36))
                            .foregroundColor(.white.opacity(0.2))
                    }
                }
            }
            .frame(width: 140, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.4), radius: 12, y: 6)

            // 트랙 정보
            VStack(spacing: 4) {
                Text(media.trackTitle.isEmpty ? "재생 중인 음악 없음" : media.trackTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(media.trackTitle.isEmpty ? .white.opacity(0.3) : .white)

                if !media.artistName.isEmpty {
                    Text(media.artistName)
                        .font(NotchDesign.Font.body)
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }
            }

            // 컨트롤
            HStack(spacing: 28) {
                mediaBtn("backward.fill", 16) { media.previousTrack() }
                mediaBtn(media.isPlaying ? "pause.fill" : "play.fill", 22, primary: true) { media.playPause() }
                mediaBtn("forward.fill", 16) { media.nextTrack() }
            }
        }
        .frame(maxHeight: .infinity)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Page 1: 🌤📅 정보
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var infoPage: some View {
        VStack(spacing: NotchDesign.Spacing.md) {
            // 날씨 카드
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: weather.condition.icon)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 32))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.0f°", weather.temperature))
                            .font(.system(size: 36, weight: .light, design: .rounded))
                        Text(weather.conditionDescription)
                            .font(NotchDesign.Font.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "humidity.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.cyan.opacity(0.7))
                            Text("\(weather.humidity)%")
                                .font(NotchDesign.Font.monoRounded)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 8))
                            Text(weather.locationName)
                                .font(NotchDesign.Font.captionSecondary)
                        }
                        .foregroundColor(.white.opacity(0.35))
                    }
                }
            }
            .sectionCard()

            // 캘린더 카드
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.cyan)
                    Text("오늘 일정")
                        .font(NotchDesign.Font.caption)
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text(todayString)
                        .font(NotchDesign.Font.captionSecondary)
                        .foregroundColor(.white.opacity(0.25))
                }

                if calendar.todayEvents.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green.opacity(0.6))
                        Text("오늘 일정 없음")
                            .font(NotchDesign.Font.body)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(Array(calendar.todayEvents.prefix(4))) { event in
                        HStack(spacing: 8) {
                            Text(event.timeString)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(event.isOngoing ? .cyan : .white.opacity(0.5))
                                .frame(width: 40, alignment: .leading)

                            Circle()
                                .fill(event.isOngoing ? Color.cyan : .white.opacity(0.2))
                                .frame(width: 5, height: 5)

                            Text(event.title)
                                .font(NotchDesign.Font.caption)
                                .lineLimit(1)

                            Spacer()

                            if event.isOngoing {
                                Text("진행 중")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.cyan.opacity(0.15)))
                            }
                        }
                    }
                }
            }
            .sectionCard()

            Spacer()
        }
        .frame(maxHeight: .infinity)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Page 2: 💻 시스템
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var systemPage: some View {
        VStack(spacing: NotchDesign.Spacing.md) {
            // CPU
            systemRow(
                icon: "cpu", label: "CPU",
                value: String(format: "%.1f%%", system.cpuUsage),
                progress: system.cpuUsage / 100,
                color: system.cpuUsage > 80 ? .red : system.cpuUsage > 50 ? .orange : .green
            )

            // Memory
            systemRow(
                icon: "memorychip", label: "메모리",
                value: "\(formatGB(system.memoryUsed)) / \(formatGB(system.memoryTotal))",
                progress: system.memoryUsage / 100,
                color: system.memoryUsage > 80 ? .red : system.memoryUsage > 60 ? .orange : .blue
            )

            // Battery
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.06), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: Double(system.batteryLevel) / 100)
                            .stroke(
                                system.batteryLevel <= 20 ? Color.red : .green,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        Image(systemName: system.isCharging ? "bolt.fill" : "battery.100")
                            .font(.system(size: 12))
                            .foregroundColor(system.isCharging ? .green : .white.opacity(0.5))
                    }
                    .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("배터리")
                            .font(NotchDesign.Font.caption)
                            .foregroundColor(.white.opacity(0.5))
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(system.batteryLevel)")
                                .font(.system(size: 24, weight: .light, design: .rounded))
                            Text("%")
                                .font(NotchDesign.Font.caption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }

                    Spacer()

                    if system.isCharging {
                        Label("충전 중", systemImage: "bolt.fill")
                            .font(NotchDesign.Font.captionSecondary)
                            .foregroundColor(.green)
                    } else if !system.batteryTimeRemaining.isEmpty {
                        Text(system.batteryTimeRemaining)
                            .font(NotchDesign.Font.monoRounded)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .sectionCard()

            Spacer()
        }
        .frame(maxHeight: .infinity)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Page 3: 🎛 제어판
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var controlPage: some View {
        VStack(spacing: NotchDesign.Spacing.md) {
            // 볼륨
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    Text("볼륨")
                        .font(NotchDesign.Font.caption)
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text("\(Int(volume * 100))%")
                        .font(NotchDesign.Font.monoRounded)
                        .foregroundColor(.white.opacity(0.4))
                }
                wideSlider(value: $volume) { setVolume($0) }
            }
            .sectionCard()

            // 빠른 토글
            HStack(spacing: NotchDesign.Spacing.md) {
                controlToggle(
                    icon: isDarkMode ? "moon.fill" : "sun.max.fill",
                    label: "다크 모드",
                    isActive: isDarkMode,
                    action: toggleDarkMode
                )

                controlToggle(
                    icon: "camera.fill",
                    label: "스크린샷",
                    isActive: false,
                    action: takeScreenshot
                )

                controlToggle(
                    icon: "gear",
                    label: "설정",
                    isActive: false,
                    action: openSettings
                )
            }

            Spacer()
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Shared Components

    private func mediaBtn(_ icon: String, _ size: CGFloat, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: primary ? .semibold : .regular))
                .foregroundColor(.white.opacity(primary ? 0.95 : 0.5))
                .frame(width: primary ? 48 : 32, height: primary ? 48 : 32)
                .background(
                    Circle().fill(.white.opacity(primary ? 0.12 : 0.04))
                )
        }
        .buttonStyle(.plain)
    }

    private func systemRow(icon: String, label: String, value: String, progress: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.06), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: min(progress, 1))
                        .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(color.opacity(0.8))
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(NotchDesign.Font.caption)
                        .foregroundColor(.white.opacity(0.5))
                    Text(value)
                        .font(NotchDesign.Font.monoRounded)
                }

                Spacer()

                Text(String(format: "%.0f%%", progress * 100))
                    .font(.system(size: 18, weight: .light, design: .rounded))
                    .foregroundColor(color)
            }
        }
        .sectionCard()
    }

    private func controlToggle(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isActive ? .white : .white.opacity(0.5))
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isActive ? Color.accentColor : .white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(isActive ? 0.1 : 0.04), lineWidth: 0.5)
                    )

                Text(label)
                    .font(NotchDesign.Font.captionSecondary)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .sectionCard()
    }

    private func wideSlider(value: Binding<Double>, onChange: @escaping (Double) -> Void) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.06)).frame(height: 6)
                Capsule().fill(Color.accentColor.opacity(0.7))
                    .frame(width: max(w * value.wrappedValue, 6), height: 6)
                Circle().fill(.white).frame(width: 14, height: 14)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .offset(x: max(w * value.wrappedValue - 7, 0))
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                let v = min(max(g.location.x / w, 0), 1)
                value.wrappedValue = v; onChange(v)
            })
        }
        .frame(height: 20)
    }

    private func formatGB(_ bytes: UInt64) -> String {
        String(format: "%.1fG", Double(bytes) / 1_073_741_824)
    }

    private var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "M/d (E)"
        f.locale = Locale(identifier: "ko_KR")
        return f.string(from: Date())
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
