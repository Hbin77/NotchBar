//
//  NotchPopupView.swift
//  NotchBar
//
//  메인 팝업 뷰 (노치 확장 시 표시)
//

import SwiftUI

struct NotchPopupView: View {

    @ObservedObject var viewModel: NotchViewModel

    @StateObject private var mediaManager = MediaManager.shared
    @StateObject private var calendarManager = CalendarManager.shared

    @AppStorage("showMediaWidget") private var showMediaWidget = true
    @AppStorage("showWeatherWidget") private var showWeatherWidget = true
    @AppStorage("showSystemWidget") private var showSystemWidget = true
    @AppStorage("showCalendarWidget") private var showCalendarWidget = true
    @AppStorage("showQuickSettings") private var showQuickSettings = true

    @State private var appearAnimation = false
    
    var body: some View {
        ZStack {
            // 배경 - 개선된 글래스모피즘
            backgroundView

            if viewModel.isExpanded {
                expandedContent
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : -10)
            } else {
                collapsedContent
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isExpanded)
        .onChange(of: viewModel.isExpanded) { _, newValue in
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
        RoundedRectangle(cornerRadius: viewModel.isExpanded ? 24 : 12)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: viewModel.isExpanded ? 24 : 12)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: viewModel.isExpanded ? 20 : 10, y: 5)
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
            if showMediaWidget {
                MediaWidgetView()
                    .padding(.horizontal, 4)

                dividerView
            }

            // 중단: 위젯 그리드
            HStack(alignment: .top, spacing: 12) {
                if showWeatherWidget {
                    WeatherWidgetView()
                        .frame(maxWidth: .infinity)
                }

                if showCalendarWidget {
                    CalendarWidgetView()
                        .frame(maxWidth: .infinity)
                }

                if showSystemWidget {
                    SystemWidgetView()
                        .frame(maxWidth: .infinity)
                }
            }

            if showQuickSettings {
                dividerView

                QuickSettingsView()
            }
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
        NotchPopupView(viewModel: NotchViewModel())
            .frame(width: 180, height: 38)

        NotchPopupView(viewModel: {
            let vm = NotchViewModel()
            vm.isExpanded = true
            return vm
        }())
            .frame(width: 400, height: 200)
    }
    .padding()
    .background(Color.black)
}
