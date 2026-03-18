//
//  CalendarManager.swift
//  NotchBar
//
//  캘린더 이벤트 관리 (EventKit)
//

import Foundation
import EventKit
import Combine
import os.log

@MainActor
class CalendarManager: ObservableObject {

    static let shared = CalendarManager()

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "NotchBar", category: "Calendar")

    // MARK: - Published Properties

    @Published var todayEvents: [CalendarEvent] = []
    @Published var upcomingEvent: CalendarEvent?
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false

    // MARK: - Private

    private let eventStore = EKEventStore()
    private var timer: Timer?

    // MARK: - Init

    private init() {
        checkAuthorization()
    }

    // MARK: - Authorization

    func checkAuthorization() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)

        if authorizationStatus == .authorized {
            fetchTodayEvents()
            startAutoRefresh()
        }
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            authorizationStatus = granted ? .authorized : .denied
            if granted {
                fetchTodayEvents()
                startAutoRefresh()
            }
            return granted
        } catch {
            Self.logger.error("Calendar access error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Fetch Events

    func fetchTodayEvents() {
        guard authorizationStatus == .authorized else { return }

        isLoading = true

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            isLoading = false
            return
        }

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )

        let ekEvents = eventStore.events(matching: predicate)

        todayEvents = ekEvents
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .map { CalendarEvent(from: $0) }

        // 다음 일정 찾기
        let now = Date()
        upcomingEvent = todayEvents.first { $0.endDate > now }

        isLoading = false
    }

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchTodayEvents()
            }
        }
    }

    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - CalendarEvent Model

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let calendarColor: CGColor?
    let isAllDay: Bool

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier ?? UUID().uuidString
        self.title = ekEvent.title ?? "제목 없음"
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.location = ekEvent.location
        self.calendarColor = ekEvent.calendar?.cgColor
        self.isAllDay = ekEvent.isAllDay
    }

    var timeString: String {
        Self.timeFormatter.string(from: startDate)
    }

    var isOngoing: Bool {
        let now = Date()
        return startDate <= now && endDate > now
    }

    var isUpcoming: Bool {
        return startDate > Date()
    }

    var minutesUntilStart: Int {
        return Int(startDate.timeIntervalSinceNow / 60)
    }
}
