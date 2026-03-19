//
//  NotchPopupView.swift
//  NotchBar
//
//  노치 팝업 — 스와이프 페이지 디자인
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
    @State private var brightness: Double = 0.5
    @State private var isWiFiOn = false
    @State private var isBluetoothOn = false
    @State private var contentVisible = false

    private let pageCount = 4
    private let tabs: [(icon: String, label: String)] = [
        ("music.note", "음악"),
        ("cloud.sun.fill", "정보"),
        ("cpu", "시스템"),
        ("slider.horizontal.3", "제어판"),
    ]

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
        let shape = NotchConnectedShape(
            notchWidth: viewModel.notchWidth,
            stemHeight: viewModel.stemHeight
        )
        return ZStack {
            // 배경
            shape
                .fill(Color.black.opacity(0.92))
                .background(shape.fill(.ultraThinMaterial))
                .overlay(
                    shape.stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.12), .white.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
                )
                .shadow(color: .black.opacity(0.5), radius: 30, y: 10)

            // 콘텐츠
            VStack(spacing: 0) {
                Spacer().frame(height: viewModel.stemHeight + 20)

                tabBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                pagerContent
                    .opacity(contentVisible ? 1 : 0)

                pageDots
                    .padding(.vertical, 8)
            }
            .clipShape(shape)
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(0..<pageCount, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        currentPage = i
                        dragOffset = 0
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: tabs[i].icon)
                            .font(.system(size: 8))
                        Text(tabs[i].label)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(currentPage == i ? .white : .white.opacity(0.3))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(currentPage == i ? .white.opacity(0.1) : .clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Pager

    private var pagerContent: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let offset = -CGFloat(currentPage) * w + dragOffset

            HStack(spacing: 0) {
                musicPage.frame(width: w)
                infoPage.frame(width: w)
                systemPage.frame(width: w)
                controlPage.frame(width: w)
            }
            .offset(x: offset)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: currentPage)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { v in
                        dragOffset = v.translation.width
                    }
                    .onEnded { v in
                        let threshold = w * 0.15
                        let vel = v.predictedEndTranslation.width
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            if v.translation.width < -threshold || vel < -150 {
                                currentPage = min(currentPage + 1, pageCount - 1)
                            } else if v.translation.width > threshold || vel > 150 {
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
        HStack(spacing: 5) {
            ForEach(0..<pageCount, id: \.self) { i in
                Circle()
                    .fill(currentPage == i ? .white.opacity(0.7) : .white.opacity(0.15))
                    .frame(width: currentPage == i ? 6 : 4, height: currentPage == i ? 6 : 4)
            }
        }
        .animation(.easeOut(duration: 0.2), value: currentPage)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 🎵 음악 페이지
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var musicPage: some View {
        HStack(spacing: 20) {
            // 왼쪽: 앨범아트 (고정 크기)
            Group {
                if let art = media.albumArtwork {
                    Image(nsImage: art).resizable().aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [.purple.opacity(0.25), .blue.opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        Image(systemName: "music.note")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.06), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.35), radius: 12, y: 6)

            // 오른쪽: 트랙 정보 + 컨트롤 (세로 중앙 정렬)
            VStack(spacing: 16) {
                // 트랙 정보
                VStack(spacing: 4) {
                    Text(media.trackTitle.isEmpty ? "재생 중인 음악 없음" : media.trackTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(media.trackTitle.isEmpty ? .white.opacity(0.25) : .white)
                    if !media.artistName.isEmpty {
                        Text(media.artistName)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                            .lineLimit(1)
                    }
                }

                // 재생 컨트롤
                HStack(spacing: 24) {
                    mediaBtn("backward.fill", 15) { media.previousTrack() }
                    mediaBtn(media.isPlaying ? "pause.fill" : "play.fill", 22, primary: true) { media.playPause() }
                    mediaBtn("forward.fill", 15) { media.nextTrack() }
                }

                // 볼륨
                HStack(spacing: 6) {
                    Image(systemName: "speaker.fill").font(.system(size: 9)).foregroundColor(.white.opacity(0.25))
                    wideSlider(value: $volume) { setVolume($0) }
                    Image(systemName: "speaker.wave.3.fill").font(.system(size: 9)).foregroundColor(.white.opacity(0.25))
                }
                .padding(.horizontal, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 🌤📅 정보 페이지
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var infoPage: some View {
        VStack(spacing: 8) {
            // 날씨
            HStack(spacing: 10) {
                Image(systemName: weather.condition.icon)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 26))

                VStack(alignment: .leading, spacing: 1) {
                    Text(String(format: "%.0f°", weather.temperature))
                        .font(.system(size: 28, weight: .light, design: .rounded))
                    Text(weather.conditionDescription)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 3) {
                        Image(systemName: "humidity.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.cyan.opacity(0.6))
                        Text("\(weather.humidity)%")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "location.fill").font(.system(size: 7))
                        Text(weather.locationName).font(.system(size: 9))
                    }
                    .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.04)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.05), lineWidth: 0.5))

            // 캘린더
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar").font(.system(size: 10)).foregroundColor(.cyan)
                    Text("오늘 일정").font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text(todayString).font(.system(size: 9)).foregroundColor(.white.opacity(0.2))
                }

                if calendar.todayEvents.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 12)).foregroundColor(.green.opacity(0.5))
                        Text("오늘 일정 없음").font(.system(size: 11)).foregroundColor(.white.opacity(0.35))
                    }
                    .padding(.vertical, 6)
                } else {
                    ForEach(Array(calendar.todayEvents.prefix(4))) { event in
                        HStack(spacing: 6) {
                            Text(event.timeString)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(event.isOngoing ? .cyan : .white.opacity(0.4))
                                .frame(width: 36, alignment: .leading)
                            Circle().fill(event.isOngoing ? Color.cyan : .white.opacity(0.15)).frame(width: 4, height: 4)
                            Text(event.title).font(.system(size: 10)).lineLimit(1)
                            Spacer()
                            if event.isOngoing {
                                Text("진행 중").font(.system(size: 7, weight: .medium)).foregroundColor(.cyan)
                                    .padding(.horizontal, 4).padding(.vertical, 1)
                                    .background(Capsule().fill(Color.cyan.opacity(0.12)))
                            }
                        }
                    }
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.04)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.05), lineWidth: 0.5))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 💻 시스템 페이지
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var systemPage: some View {
        VStack(spacing: 8) {
            sysRow(icon: "cpu", label: "CPU",
                   value: String(format: "%.1f%%", system.cpuUsage),
                   pct: system.cpuUsage / 100,
                   color: system.cpuUsage > 80 ? .red : system.cpuUsage > 50 ? .orange : .green)

            sysRow(icon: "memorychip", label: "메모리",
                   value: "\(formatGB(system.memoryUsed)) / \(formatGB(system.memoryTotal))",
                   pct: system.memoryUsage / 100,
                   color: system.memoryUsage > 80 ? .red : system.memoryUsage > 60 ? .orange : .blue)

            // 배터리
            HStack(spacing: 10) {
                ZStack {
                    Circle().stroke(.white.opacity(0.06), lineWidth: 3)
                    Circle().trim(from: 0, to: Double(system.batteryLevel) / 100)
                        .stroke(system.batteryLevel <= 20 ? Color.red : .green,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: system.isCharging ? "bolt.fill" : "battery.100")
                        .font(.system(size: 10))
                        .foregroundColor(system.isCharging ? .green : .white.opacity(0.4))
                }
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 1) {
                    Text("배터리").font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(system.batteryLevel)").font(.system(size: 20, weight: .light, design: .rounded))
                        Text("%").font(.system(size: 10)).foregroundColor(.white.opacity(0.35))
                    }
                }
                Spacer()
                if system.isCharging {
                    Label("충전 중", systemImage: "bolt.fill").font(.system(size: 9)).foregroundColor(.green)
                } else if !system.batteryTimeRemaining.isEmpty {
                    Text(system.batteryTimeRemaining).font(.system(size: 10, design: .rounded)).foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.04)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.05), lineWidth: 0.5))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 🎛 제어판 페이지
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var controlPage: some View {
        VStack(spacing: 8) {
            // 볼륨
            sliderRow(icon: "speaker.wave.2.fill", label: "볼륨",
                      value: $volume, pctText: "\(Int(volume * 100))%") { setVolume($0) }

            // 밝기
            sliderRow(icon: "sun.max.fill", label: "밝기",
                      value: $brightness, pctText: "\(Int(brightness * 100))%") { setBrightness($0) }

            // 토글 버튼
            HStack(spacing: 6) {
                ctrlToggle(icon: isDarkMode ? "moon.fill" : "sun.max.fill", label: "다크 모드", active: isDarkMode) { toggleDarkMode() }
                ctrlToggle(icon: "camera.fill", label: "스크린샷", active: false) { takeScreenshot() }
                ctrlToggle(icon: isWiFiOn ? "wifi" : "wifi.slash", label: "Wi-Fi", active: isWiFiOn) { openWiFiSettings() }
                ctrlToggle(icon: "bluetooth", label: "블루투스", active: isBluetoothOn) { openBluetoothSettings() }
                ctrlToggle(icon: "gearshape.fill", label: "설정", active: false) { openSettings() }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Components

    private func mediaBtn(_ icon: String, _ size: CGFloat, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: primary ? .semibold : .regular))
                .foregroundColor(.white.opacity(primary ? 0.9 : 0.45))
                .frame(width: primary ? 42 : 28, height: primary ? 42 : 28)
                .background(Circle().fill(.white.opacity(primary ? 0.1 : 0.03)))
        }
        .buttonStyle(.plain)
    }

    private func sysRow(icon: String, label: String, value: String, pct: Double, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().stroke(.white.opacity(0.06), lineWidth: 3)
                Circle().trim(from: 0, to: min(pct, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: icon).font(.system(size: 10)).foregroundColor(color.opacity(0.7))
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
                Text(value).font(.system(size: 11, weight: .medium, design: .rounded))
            }
            Spacer()
            Text(String(format: "%.0f%%", pct * 100))
                .font(.system(size: 16, weight: .light, design: .rounded))
                .foregroundColor(color)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.05), lineWidth: 0.5))
    }

    private func sliderRow(icon: String, label: String, value: Binding<Double>, pctText: String, onChange: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon).font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
                Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.4))
                Spacer()
                Text(pctText).font(.system(size: 10, design: .rounded)).foregroundColor(.white.opacity(0.3))
            }
            wideSlider(value: value, onChange: onChange)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.05), lineWidth: 0.5))
    }

    private func ctrlToggle(icon: String, label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(active ? .white : .white.opacity(0.4))
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(active ? Color.accentColor : .white.opacity(0.05))
                    )
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.04), lineWidth: 0.5))
                Text(label).font(.system(size: 7)).foregroundColor(.white.opacity(0.3))
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func wideSlider(value: Binding<Double>, onChange: @escaping (Double) -> Void) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.06)).frame(height: 5)
                Capsule().fill(Color.accentColor.opacity(0.65))
                    .frame(width: max(w * value.wrappedValue, 5), height: 5)
                Circle().fill(.white).frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .offset(x: max(w * value.wrappedValue - 6, 0))
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                let v = min(max(g.location.x / w, 0), 1)
                value.wrappedValue = v; onChange(v)
            })
        }
        .frame(height: 18)
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
        // IOKit에서 현재 밝기 읽기
        var iterator: io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"), &iterator) == kIOReturnSuccess {
            let service = IOIteratorNext(iterator)
            if service != 0 {
                var br: Float = 0.5
                IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &br)
                brightness = Double(br)
                IOObjectRelease(service)
            }
            IOObjectRelease(iterator)
        }
        // Wi-Fi 상태
        let wifiResult = Process.run("/usr/sbin/networksetup", args: ["-getairportpower", "en0"])
        isWiFiOn = wifiResult?.contains("On") ?? false
        // 블루투스 상태
        let btResult = AppleScriptRunner.run("""
        do shell script "defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState 2>/dev/null || echo 1"
        """)
        isBluetoothOn = btResult != "0"
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
        dismissAndRun {
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            task.arguments = ["-i", "-s"]
            try? task.run()
        }
    }

    private func setBrightness(_ v: Double) {
        let clamped = min(max(v, 0), 1)
        // IOKit을 통한 디스플레이 밝기 설정
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"), &iterator)
        guard result == kIOReturnSuccess else { return }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, Float(clamped))
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
    }

    private func dismissAndRun(_ action: @escaping () -> Void) {
        viewModel.isExpanded = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { action() }
    }

    private func openWiFiSettings() {
        dismissAndRun {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.wifi-settings-extension")!)
        }
    }

    private func openBluetoothSettings() {
        dismissAndRun {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings")!)
        }
    }

    private func openSettings() {
        dismissAndRun {
            NSApp.activate(ignoringOtherApps: true)
            if NSApp.responds(to: Selector(("showSettingsWindow:"))) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } else {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }
        }
    }
}

// MARK: - Process Helper

private extension Process {
    static func run(_ path: String, args: [String]) -> String? {
        let task = Process()
        task.launchPath = path
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do { try task.run() } catch { return nil }
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
