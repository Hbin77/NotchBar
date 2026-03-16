//
//  MediaWidgetView.swift
//  NotchBar
//
//  미디어 플레이어 위젯
//

import SwiftUI

struct MediaWidgetView: View {
    
    @StateObject private var mediaManager = MediaManager.shared
    
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
        .frame(width: 44, height: 44)
        .background(Color.secondary.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var playbackControls: some View {
        HStack(spacing: 16) {
            // 이전 트랙
            Button(action: { mediaManager.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            
            // 재생/일시정지
            Button(action: { mediaManager.playPause() }) {
                Image(systemName: mediaManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            
            // 다음 트랙
            Button(action: { mediaManager.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    MediaWidgetView()
        .padding()
        .frame(width: 350)
        .background(.ultraThinMaterial)
}
