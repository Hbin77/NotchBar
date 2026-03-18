//
//  CalendarManager.swift
//  NotchBar
//
//  캘린더 이벤트 관리 (EventKit)
//

import Foundation
import EventKit
import Combine

@MainActor
class CalendarManager: ObservableObject {
    
    static let shared = CalendarManager()
    
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
            await MainActor.run {
                authorizationStatus = granted ? .authorized : .denied
                if granted {
                    fetchTodayEvents()
                    startAutoRefresh()
                }
            }
            return granted
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }
    
    // MARK: - Fetch Events
    
    func fetchTodayEvents() {
        guard authorizationStatus == .authorized else { return }
        
        isLoading = true
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )
        
        let ekEvents = eventStore.events(matching: predicate)
        
        todayEvents = ekEvents
            .filter { !$0.isAllDay } // 종일 일정 제외 (선택적)
            .sorted { $0.startDate < $1.startDate }
            .map { CalendarEvent(from: $0) }
        
        // 다음 일정 찾기
        let now = Date()
        upcomingEvent = todayEvents.first { $0.endDate > now }
        
        isLoading = false
    }
    
    // MARK: - Auto Refresh
    
    private func startAutoRefresh() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchTodayEvents()
            }
        }
    }
    
    deinit {
        timer?.invalidate()
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
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startDate)
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
