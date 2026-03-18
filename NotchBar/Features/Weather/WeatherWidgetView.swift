//
//  WeatherWidgetView.swift
//  NotchBar
//
//  날씨 위젯
//

import SwiftUI

struct WeatherWidgetView: View {
    
    @StateObject private var weather = WeatherManager.shared
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 위치
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.system(size: 9))
                Text(weather.locationName)
                    .font(.system(size: 10))
            }
            .foregroundColor(.secondary)
            
            // 온도 + 아이콘
            HStack(spacing: 8) {
                Image(systemName: weather.condition.icon)
                    .font(.system(size: 24))
                    .symbolRenderingMode(.multicolor)
                    .symbolEffect(.bounce, value: isHovering)
                
                Text(String(format: "%.0f°", weather.temperature))
                    .font(.system(size: 28, weight: .light, design: .rounded))
            }
            
            // 상태 + 습도
            HStack(spacing: 8) {
                Text(weather.conditionDescription)
                    .font(.system(size: 11))
                
                Text("💧 \(weather.humidity)%")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
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
}

#Preview {
    WeatherWidgetView()
        .padding()
        .frame(width: 150)
        .background(.ultraThinMaterial)
}
