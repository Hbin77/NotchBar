//
//  CalendarWidgetView.swift
//  NotchBar
//
//  캘린더 위젯 — 프리미엄 디자인
//

import SwiftUI

struct CalendarWidgetView: View {

    @StateObject private var manager = CalendarManager.shared

    private static let todayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M/d (E)"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 헤더
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(.accentColor)

                Text("오늘 일정")
                    .font(NotchDesign.Font.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(Self.todayFormatter.string(from: Date()))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

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
        .widgetCard()
    }

    // MARK: - Authorization

    private var authorizationView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 20))
                .foregroundColor(.secondary)

            Text("캘린더 접근 필요")
                .font(NotchDesign.Font.caption)
                .foregroundColor(.secondary)

            Button("권한 허용") {
                Task { await manager.requestAccess() }
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
                .font(NotchDesign.Font.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Empty

    private var emptyView: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)

            Text("오늘 일정 없음")
                .font(NotchDesign.Font.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Events List

    private var eventsListView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(manager.todayEvents.prefix(3))) { event in
                EventRowView(event: event)
            }

            if manager.todayEvents.count > 3 {
                Text("+\(manager.todayEvents.count - 3)개 더")
                    .font(NotchDesign.Font.captionSecondary)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - EventRowView

struct EventRowView: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 8) {
            Text(event.timeString)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(event.isOngoing ? .accentColor : .primary)

            Circle()
                .fill(calendarColor)
                .frame(width: 6, height: 6)

            Text(event.title)
                .font(NotchDesign.Font.caption)
                .lineLimit(1)
                .foregroundColor(event.isOngoing ? .primary : .secondary)

            Spacer()

            if event.isOngoing {
                Text("진행 중")
                    .font(NotchDesign.Font.tiny)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(Capsule().fill(Color.accentColor.opacity(0.15)))
                    )
            } else if event.isUpcoming && event.minutesUntilStart <= 30 {
                Text("\(event.minutesUntilStart)분 후")
                    .font(NotchDesign.Font.tiny)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(event.isOngoing ? Color.accentColor.opacity(0.08) : Color.clear)
        )
    }

    private var calendarColor: Color {
        if let cgColor = event.calendarColor {
            return Color(cgColor: cgColor)
        }
        return .accentColor
    }
}

#Preview {
    CalendarWidgetView()
        .frame(width: 200)
        .padding()
        .background(Color.black.opacity(0.8))
}
