//
//  NotchPopupView.swift
//  NotchBar
//
//  메인 팝업 뷰 (노치 확장 시 표시)
//

import SwiftUI

struct NotchPopupView: View {
    
    var isExpanded: Bool = false
    
    @StateObject private var mediaManager = MediaManager.shared
    @StateObject private var systemMonitor = SystemMonitor.shared
    @StateObject private var weatherManager = WeatherManager.shared
    
    var body: some View {
        ZStack {
            // 배경
            RoundedRectangle(cornerRadius: isExpanded ? 20 : 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: isExpanded ? 20 : 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            if isExpanded {
                expandedContent
            } else {
                collapsedContent
            }
        }
        .animation(.spring(response: 0.3), value: isExpanded)
    }
    
    // MARK: - Collapsed Content (노치 기본 상태)
    
    private var collapsedContent: some View {
        HStack(spacing: 8) {
            // 미디어 아이콘
            if mediaManager.isPlaying {
                Image(systemName: "music.note")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Expanded Content (확장 상태)
    
    private var expandedContent: some View {
        VStack(spacing: 16) {
            // 상단: 미디어 플레이어
            MediaWidgetView()
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // 중단: 위젯 그리드
            HStack(spacing: 16) {
                // 날씨
                WeatherWidgetView()
                
                // 시스템 모니터
                SystemWidgetView()
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // 하단: 빠른 설정
            QuickSettingsView()
        }
        .padding(16)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        NotchPopupView(isExpanded: false)
            .frame(width: 180, height: 38)
        
        NotchPopupView(isExpanded: true)
            .frame(width: 400, height: 200)
    }
    .padding()
    .background(Color.black)
}
