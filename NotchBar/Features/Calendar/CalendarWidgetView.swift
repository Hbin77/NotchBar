//
//  CalendarWidgetView.swift
//  NotchBar
//
//  캘린더 위젯 뷰
//

import SwiftUI

struct CalendarWidgetView: View {
    
    @StateObject private var manager = CalendarManager.shared
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 헤더
            headerView
            
            // 콘텐츠
            if manager.authorizationStatus != .authorized {
                authorizationView
            } else if manager.isLoading {
                loadingView
            } else if manager.todayEvents.isEmpty {
                emptyView
            } else {
                eventsListView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(isHovering ? 0.15 : 0.1))
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 11))
                .foregroundColor(.accentColor)
            
            Text("오늘 일정")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(todayDateString)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Authorization
    
    private var authorizationView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
            
            Text("캘린더 접근 필요")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Button("권한 허용") {
                Task {
                    await manager.requestAccess()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.7)
            Text("로딩 중...")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty
    
    private var emptyView: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 14))
                .foregroundColor(.green)
            
            Text("오늘 일정 없음")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
    
    // MARK: - Events List
    
    private var eventsListView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(manager.todayEvents.prefix(3)) { event in
                EventRowView(event: event)
            }
            
            if manager.todayEvents.count > 3 {
                Text("+\(manager.todayEvents.count - 3)개 더")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: Date())
    }
}

// MARK: - EventRowView

struct EventRowView: View {
    let event: CalendarEvent
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 8) {
            // 시간
            Text(event.timeString)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(event.isOngoing ? .accentColor : .primary)
            
            // 캘린더 컬러 인디케이터
            Circle()
                .fill(calendarColor)
                .frame(width: 6, height: 6)
            
            // 제목
            Text(event.title)
                .font(.system(size: 11))
                .lineLimit(1)
                .foregroundColor(event.isOngoing ? .primary : .secondary)
            
            Spacer()
            
            // 진행 중 뱃지
            if event.isOngoing {
                Text("진행 중")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor))
            } else if event.isUpcoming && event.minutesUntilStart <= 30 {
                Text("\(event.minutesUntilStart)분 후")
                    .font(.system(size: 9))
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(event.isOngoing ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color.white.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private var calendarColor: Color {
        if let cgColor = event.calendarColor {
            return Color(cgColor: cgColor)
        }
        return .accentColor
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CalendarWidgetView()
            .frame(width: 200)
    }
    .padding()
    .background(Color.black)
}
