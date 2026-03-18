//
//  NotchPopupView.swift
//  NotchBar
//
//  NotchNook 스타일 — 노치가 확장되는 컴팩트 바
//  노치와 같은 순수 검정 배경으로 경계가 보이지 않음
//

import SwiftUI

struct NotchPopupView: View {

    @ObservedObject var viewModel: NotchViewModel

    @StateObject private var media = MediaManager.shared
    @StateObject private var weather = WeatherManager.shared
    @StateObject private var system = SystemMonitor.shared
    @StateObject private var calendar = CalendarManager.shared

    var body: some View {
        ZStack {
            if viewModel.isExpanded {
                // 순수 검정 배경 — 노치와 동일한 색상으로 경계 없이 이어짐
                UnevenRoundedRectangle(
                    topLeadingRadius: 0, bottomLeadingRadius: 18,
                    bottomTrailingRadius: 18, topTrailingRadius: 0
                )
                .fill(Color.black)
                .shadow(color: .black.opacity(0.5), radius: 15, y: 5)

                // 콘텐츠: 한 줄 바
                HStack(spacing: 12) {
                    // 앨범아트 (작은 정사각형)
                    albumArt
                        .frame(width: 36, height: 36)

                    // 곡 정보
                    if !media.trackTitle.isEmpty {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(media.trackTitle)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                            Text(media.artistName)
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: 120, alignment: .leading)
                    }

                    // 재생 컨트롤
                    HStack(spacing: 14) {
                        ctrlBtn("backward.fill", 10) { media.previousTrack() }
                        ctrlBtn(media.isPlaying ? "pause.fill" : "play.fill", 13) { media.playPause() }
                        ctrlBtn("forward.fill", 10) { media.nextTrack() }
                    }

                    // 구분선
                    divider

                    // 날씨 (컴팩트)
                    HStack(spacing: 4) {
                        Image(systemName: weather.condition.icon)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 13))
                        Text(String(format: "%.0f°", weather.temperature))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }

                    divider

                    // 시스템 (컴팩트)
                    HStack(spacing: 6) {
                        sysChip("cpu", system.cpuUsage, .green)
                        sysChip("memorychip", system.memoryUsage, .orange)
                        HStack(spacing: 2) {
                            Image(systemName: system.isCharging ? "bolt.fill" : "battery.75")
                                .font(.system(size: 8))
                                .foregroundColor(.green)
                            Text("\(system.batteryLevel)%")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                        }
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.top, 10) // 노치 높이 고려
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isExpanded)
    }

    // MARK: - Components

    private var albumArt: some View {
        Group {
            if let art = media.albumArtwork {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.white.opacity(0.08)
                    Image(systemName: "music.note")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func ctrlBtn(_ icon: String, _ size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .frame(width: 0.5, height: 20)
    }

    private func sysChip(_ icon: String, _ value: Double, _ color: Color) -> some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color.opacity(0.7))
                .frame(width: 5, height: 5)
            Text(String(format: "%.0f%%", value))
                .font(.system(size: 9, weight: .medium, design: .rounded))
        }
    }
}

#Preview {
    ZStack {
        Color.gray
        NotchPopupView(viewModel: { let v = NotchViewModel(); v.isExpanded = true; return v }())
            .frame(width: 400, height: 56)
    }
}
