//
//  WeatherWidgetView.swift
//  NotchBar
//
//  날씨 위젯 — 프리미엄 디자인
//

import SwiftUI

struct WeatherWidgetView: View {

    @StateObject private var weather = WeatherManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 위치
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.system(size: 9))
                Text(weather.locationName)
                    .font(NotchDesign.Font.captionSecondary)
            }
            .foregroundStyle(.tertiary)

            // 온도 + 아이콘
            HStack(spacing: 8) {
                Image(systemName: weather.condition.icon)
                    .font(.system(size: 24))
                    .symbolRenderingMode(.multicolor)

                Text(String(format: "%.0f°", weather.temperature))
                    .font(NotchDesign.Font.largeTitle)
            }

            // 상태 + 습도
            HStack(spacing: 8) {
                Text(weather.conditionDescription)
                    .font(NotchDesign.Font.caption)

                HStack(spacing: 2) {
                    Image(systemName: "humidity.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.cyan.opacity(0.7))
                    Text("\(weather.humidity)%")
                        .font(NotchDesign.Font.captionSecondary)
                        .foregroundColor(.secondary)
                }
            }
        }
        .widgetCard()
    }
}

#Preview {
    WeatherWidgetView()
        .padding()
        .frame(width: 160)
        .background(Color.black.opacity(0.8))
}
