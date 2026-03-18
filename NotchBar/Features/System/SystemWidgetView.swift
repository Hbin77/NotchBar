//
//  SystemWidgetView.swift
//  NotchBar
//
//  시스템 모니터 위젯
//

import SwiftUI

struct SystemWidgetView: View {
    
    @StateObject private var monitor = SystemMonitor.shared
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 헤더
            HStack(spacing: 6) {
                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                    .font(.system(size: 11))
                    .foregroundColor(.accentColor)
                
                Text("시스템")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // CPU
            StatRowView(
                icon: "cpu",
                label: "CPU",
                value: String(format: "%.0f%%", monitor.cpuUsage),
                progress: monitor.cpuUsage / 100,
                color: cpuColor
            )
            
            // Memory
            StatRowView(
                icon: "memorychip",
                label: "메모리",
                value: formatBytes(monitor.memoryUsed),
                progress: monitor.memoryUsage / 100,
                color: memoryColor
            )
            
            // Battery
            HStack(spacing: 6) {
                Image(systemName: batteryIcon)
                    .font(.system(size: 11))
                    .foregroundColor(batteryColor)
                    .symbolEffect(.pulse, options: .repeating, isActive: monitor.isCharging)
                
                Text("\(monitor.batteryLevel)%")
                    .font(.system(size: 11, weight: .medium))
                
                if !monitor.batteryTimeRemaining.isEmpty {
                    Text("(\(monitor.batteryTimeRemaining))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
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
    
    // MARK: - Helpers
    
    private var cpuColor: Color {
        if monitor.cpuUsage > 80 { return .red }
        if monitor.cpuUsage > 50 { return .orange }
        return .green
    }
    
    private var memoryColor: Color {
        if monitor.memoryUsage > 80 { return .red }
        if monitor.memoryUsage > 60 { return .orange }
        return .blue
    }
    
    private var batteryIcon: String {
        if monitor.isCharging {
            return "battery.100.bolt"
        }
        switch monitor.batteryLevel {
        case 0...10: return "battery.0"
        case 11...25: return "battery.25"
        case 26...50: return "battery.50"
        case 51...75: return "battery.75"
        default: return "battery.100"
        }
    }
    
    private var batteryColor: Color {
        if monitor.isCharging { return .green }
        if monitor.batteryLevel <= 20 { return .red }
        return .primary
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.1fGB", gb)
    }
}

// MARK: - StatRowView

struct StatRowView: View {
    let icon: String
    let label: String
    let value: String
    let progress: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 14)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
            
            // 프로그레스 바
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * min(progress, 1.0))
                }
            }
            .frame(height: 4)
            
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .frame(width: 45, alignment: .trailing)
        }
    }
}

#Preview {
    SystemWidgetView()
        .padding()
        .frame(width: 180)
        .background(.ultraThinMaterial)
}
