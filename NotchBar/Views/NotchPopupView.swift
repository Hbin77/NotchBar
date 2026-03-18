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
    @StateObject private var calendarManager = CalendarManager.shared
    
    @State private var appearAnimation = false
    
    var body: some View {
        ZStack {
            // 배경 - 개선된 글래스모피즘
            backgroundView
            
            if isExpanded {
                expandedContent
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : -10)
            } else {
                collapsedContent
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
        .onChange(of: isExpanded) { _, newValue in
            if newValue {
                withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                    appearAnimation = true
                }
            } else {
                appearAnimation = false
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: isExpanded ? 24 : 12)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: isExpanded ? 24 : 12)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: isExpanded ? 20 : 10, y: 5)
    }
    
    // MARK: - Collapsed Content (노치 기본 상태)
    
    private var collapsedContent: some View {
        HStack(spacing: 8) {
            // 미디어 아이콘 (애니메이션)
            if mediaManager.isPlaying {
                Image(systemName: "music.note")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            // 다음 일정 미리보기
            if let event = calendarManager.upcomingEvent,
               event.minutesUntilStart <= 15 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                    Text("\(event.minutesUntilStart)분")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Expanded Content (확장 상태)
    
    private var expandedContent: some View {
        VStack(spacing: 12) {
            // 상단: 미디어 플레이어
            MediaWidgetView()
                .padding(.horizontal, 4)
            
            dividerView
            
            // 중단: 위젯 그리드 (3열)
            HStack(alignment: .top, spacing: 12) {
                // 날씨
                WeatherWidgetView()
                    .frame(maxWidth: .infinity)
                
                // 캘린더
                CalendarWidgetView()
                    .frame(maxWidth: .infinity)
                
                // 시스템 모니터
                SystemWidgetView()
                    .frame(maxWidth: .infinity)
            }
            
            dividerView
            
            // 하단: 빠른 설정
            QuickSettingsView()
        }
        .padding(16)
    }
    
    private var dividerView: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.15), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
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
