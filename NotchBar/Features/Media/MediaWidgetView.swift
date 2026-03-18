//
//  MediaWidgetView.swift
//  NotchBar
//
//  미디어 플레이어 위젯 — 프리미엄 대형 디자인
//

import SwiftUI

struct MediaWidgetView: View {

    @StateObject private var mediaManager = MediaManager.shared

    var body: some View {
        HStack(spacing: 16) {
            // 대형 앨범 아트
            albumArtView

            // 트랙 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(mediaManager.trackTitle.isEmpty ? "재생 중인 음악 없음" : mediaManager.trackTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(mediaManager.trackTitle.isEmpty ? .secondary : .primary)

                if !mediaManager.artistName.isEmpty {
                    Text(mediaManager.artistName)
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 컨트롤
            HStack(spacing: 20) {
                ControlButton(icon: "backward.fill", size: 16) {
                    mediaManager.previousTrack()
                }

                ControlButton(icon: mediaManager.isPlaying ? "pause.fill" : "play.fill", size: 26, isPrimary: true) {
                    mediaManager.playPause()
                }

                ControlButton(icon: "forward.fill", size: 16) {
                    mediaManager.nextTrack()
                }
            }
        }
        .widgetCard()
    }

    // MARK: - Album Art (대형)

    private var albumArtView: some View {
        Group {
            if let artwork = mediaManager.albumArtwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
    }
}

// MARK: - Control Button

private struct ControlButton: View {
    let icon: String
    let size: CGFloat
    var isPrimary: Bool = false
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: isPrimary ? .medium : .regular))
                .foregroundColor(isPrimary ? .white : .primary.opacity(0.8))
                .frame(width: isPrimary ? 46 : 32, height: isPrimary ? 46 : 32)
                .background(
                    Circle()
                        .fill(isPrimary ? Color.accentColor.opacity(isHovering ? 0.9 : 0.7) : Color.white.opacity(isHovering ? 0.1 : 0))
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(NotchDesign.Anim.hover, value: isHovering)
        .onHover { isHovering = $0 }
    }
}

#Preview {
    MediaWidgetView()
        .padding()
        .frame(width: 500)
        .background(Color.black.opacity(0.9))
}
