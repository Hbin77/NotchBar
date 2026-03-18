//
//  MediaWidgetView.swift
//  NotchBar
//
//  미디어 플레이어 위젯
//

import SwiftUI

struct MediaWidgetView: View {
    
    @StateObject private var mediaManager = MediaManager.shared
    @State private var isHovering = false
    @State private var artworkRotation: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // 앨범 아트
            albumArtView
            
            // 트랙 정보
            VStack(alignment: .leading, spacing: 2) {
                Text(mediaManager.trackTitle.isEmpty ? "재생 중인 음악 없음" : mediaManager.trackTitle)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                if !mediaManager.artistName.isEmpty {
                    Text(mediaManager.artistName)
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 컨트롤 버튼
            if mediaManager.isPlaying || !mediaManager.trackTitle.isEmpty {
                playbackControls
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(isHovering ? 0.15 : 0.1))
        )
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    // MARK: - Subviews
    
    private var albumArtView: some View {
        Group {
            if let artwork = mediaManager.albumArtwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 48, height: 48)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        .rotationEffect(.degrees(mediaManager.isPlaying ? artworkRotation : 0))
        .onAppear {
            if mediaManager.isPlaying {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    artworkRotation = 360
                }
            }
        }
        .onChange(of: mediaManager.isPlaying) { _, isPlaying in
            if isPlaying {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    artworkRotation = 360
                }
            } else {
                withAnimation(.easeOut(duration: 0.5)) {
                    artworkRotation = 0
                }
            }
        }
    }
    
    private var playbackControls: some View {
        HStack(spacing: 12) {
            // 이전 트랙
            MediaControlButton(icon: "backward.fill", size: 14) {
                mediaManager.previousTrack()
            }
            
            // 재생/일시정지
            MediaControlButton(
                icon: mediaManager.isPlaying ? "pause.fill" : "play.fill",
                size: 20,
                isPrimary: true
            ) {
                mediaManager.playPause()
            }
            
            // 다음 트랙
            MediaControlButton(icon: "forward.fill", size: 14) {
                mediaManager.nextTrack()
            }
        }
    }
}

// MARK: - MediaControlButton

struct MediaControlButton: View {
    let icon: String
    let size: CGFloat
    var isPrimary: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: isPrimary ? .semibold : .regular))
                .foregroundColor(isPrimary ? .accentColor : .primary)
                .frame(width: isPrimary ? 36 : 28, height: isPrimary ? 36 : 28)
                .background(
                    Circle()
                        .fill(isPrimary ? Color.accentColor.opacity(0.2) : Color.clear)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = hovering
            }
        }
    }
}

#Preview {
    MediaWidgetView()
        .padding()
        .frame(width: 350)
        .background(.ultraThinMaterial)
}
