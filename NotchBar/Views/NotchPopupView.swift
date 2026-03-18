//
//  NotchPopupView.swift
//  NotchBar
//
//  노치에서 자연스럽게 확장되는 프리미엄 팝업
//

import SwiftUI

// MARK: - Notch Shape (노치에서 이어지는 커스텀 형태)

struct NotchShape: Shape {
    var notchWidth: CGFloat
    var notchRadius: CGFloat = 12
    var bodyRadius: CGFloat = 28

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let midX = rect.midX
        let notchHalf = notchWidth / 2
        let shoulderWidth: CGFloat = 24  // 노치→본체 전환 곡선 폭

        // 시작: 왼쪽 노치 안쪽 상단
        p.move(to: CGPoint(x: midX - notchHalf + notchRadius, y: rect.minY))

        // 노치 상단 (평평)
        p.addLine(to: CGPoint(x: midX + notchHalf - notchRadius, y: rect.minY))

        // 노치 오른쪽 상단 라운드
        p.addQuadCurve(
            to: CGPoint(x: midX + notchHalf, y: rect.minY + notchRadius),
            control: CGPoint(x: midX + notchHalf, y: rect.minY)
        )

        // 오른쪽 어깨 곡선 (노치→본체)
        p.addLine(to: CGPoint(x: midX + notchHalf, y: rect.minY + 26))
        p.addCurve(
            to: CGPoint(x: midX + notchHalf + shoulderWidth + bodyRadius, y: rect.minY + 50),
            control1: CGPoint(x: midX + notchHalf, y: rect.minY + 44),
            control2: CGPoint(x: midX + notchHalf + shoulderWidth, y: rect.minY + 50)
        )

        // 오른쪽 벽
        p.addLine(to: CGPoint(x: rect.maxX - bodyRadius, y: rect.minY + 50))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + 50 + bodyRadius),
            control: CGPoint(x: rect.maxX, y: rect.minY + 50)
        )

        // 오른쪽 하단까지
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bodyRadius))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - bodyRadius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )

        // 하단
        p.addLine(to: CGPoint(x: rect.minX + bodyRadius, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - bodyRadius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )

        // 왼쪽 벽
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 50 + bodyRadius))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + bodyRadius, y: rect.minY + 50),
            control: CGPoint(x: rect.minX, y: rect.minY + 50)
        )

        // 왼쪽 어깨 곡선
        p.addLine(to: CGPoint(x: midX - notchHalf - shoulderWidth - bodyRadius, y: rect.minY + 50))
        p.addCurve(
            to: CGPoint(x: midX - notchHalf, y: rect.minY + 26),
            control1: CGPoint(x: midX - notchHalf - shoulderWidth, y: rect.minY + 50),
            control2: CGPoint(x: midX - notchHalf, y: rect.minY + 44)
        )

        // 왼쪽 노치 안쪽
        p.addLine(to: CGPoint(x: midX - notchHalf, y: rect.minY + notchRadius))
        p.addQuadCurve(
            to: CGPoint(x: midX - notchHalf + notchRadius, y: rect.minY),
            control: CGPoint(x: midX - notchHalf, y: rect.minY)
        )

        p.closeSubpath()
        return p
    }
}

// MARK: - Main View

struct NotchPopupView: View {

    @ObservedObject var viewModel: NotchViewModel

    @StateObject private var mediaManager = MediaManager.shared
    @StateObject private var calendarManager = CalendarManager.shared

    @AppStorage("showMediaWidget") private var showMediaWidget = true
    @AppStorage("showWeatherWidget") private var showWeatherWidget = true
    @AppStorage("showCalendarWidget") private var showCalendarWidget = true
    @AppStorage("showSystemWidget") private var showSystemWidget = true
    @AppStorage("showQuickSettings") private var showQuickSettings = true

    @State private var showMedia = false
    @State private var showWidgets = false
    @State private var showSettings = false

    private let notchWidth: CGFloat = NotchDetector.getNotchWidth() + 8

    var body: some View {
        ZStack {
            if viewModel.isExpanded {
                // 다층 배경
                notchBackground

                // 콘텐츠
                VStack(spacing: 16) {
                    Spacer().frame(height: 52) // 노치+어깨 영역 아래부터 시작

                    // 미디어 플레이어
                    if showMediaWidget {
                        MediaWidgetView()
                            .sectionTransition(isVisible: showMedia, index: 0)
                    }

                    // 위젯 그리드
                    HStack(alignment: .top, spacing: 14) {
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
                    .sectionTransition(isVisible: showWidgets, index: 1)

                    // 구분선
                    if showQuickSettings {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.clear, .white.opacity(0.06), .clear],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(height: 0.5)
                            .opacity(showSettings ? 1 : 0)

                        QuickSettingsView()
                            .sectionTransition(isVisible: showSettings, index: 2)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .onChange(of: viewModel.isExpanded) { _, expanded in
            if expanded { animateIn() } else { animateOut() }
        }
    }

    // MARK: - Notch-Integrated Background

    private var notchBackground: some View {
        ZStack {
            // 레이어 1: 딥 블랙 베이스
            NotchShape(notchWidth: notchWidth)
                .fill(Color.black.opacity(0.85))

            // 레이어 2: 블러 글라스
            NotchShape(notchWidth: notchWidth)
                .fill(.ultraThinMaterial)
                .opacity(0.6)

            // 레이어 3: 미묘한 그라데이션 오버레이
            NotchShape(notchWidth: notchWidth)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.clear,
                            Color.black.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // 레이어 4: 테두리 하이라이트
            NotchShape(notchWidth: notchWidth)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05), .white.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.5), radius: 40, y: 15)
        .shadow(color: .black.opacity(0.3), radius: 15, y: 5)
    }

    // MARK: - Animations

    private func animateIn() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(0.05)) {
            showMedia = true
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(0.12)) {
            showWidgets = true
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(0.19)) {
            showSettings = true
        }
    }

    private func animateOut() {
        withAnimation(.easeIn(duration: 0.1)) {
            showSettings = false
            showWidgets = false
            showMedia = false
        }
    }
}

// MARK: - Section Transition Modifier

extension View {
    func sectionTransition(isVisible: Bool, index: Int) -> some View {
        self
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 12)
            .scaleEffect(isVisible ? 1 : 0.96, anchor: .top)
    }
}

// MARK: - Preview

#Preview {
    NotchPopupView(viewModel: {
        let vm = NotchViewModel()
        vm.isExpanded = true
        return vm
    }())
    .frame(width: 700, height: 460)
    .background(Color.black)
}
