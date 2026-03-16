//
//  SettingsView.swift
//  NotchBar
//
//  앱 설정 화면
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMediaWidget") private var showMediaWidget = true
    @AppStorage("showWeatherWidget") private var showWeatherWidget = true
    @AppStorage("showSystemWidget") private var showSystemWidget = true
    @AppStorage("showQuickSettings") private var showQuickSettings = true
    @AppStorage("hoverDelay") private var hoverDelay = 0.3
    @AppStorage("unhoverDelay") private var unhoverDelay = 0.5
    
    var body: some View {
        TabView {
            // 일반 설정
            generalSettings
                .tabItem {
                    Label("일반", systemImage: "gear")
                }
            
            // 위젯 설정
            widgetSettings
                .tabItem {
                    Label("위젯", systemImage: "square.grid.2x2")
                }
            
            // 정보
            aboutView
                .tabItem {
                    Label("정보", systemImage: "info.circle")
                }
        }
        .frame(width: 400, height: 300)
    }
    
    // MARK: - General Settings
    
    private var generalSettings: some View {
        Form {
            Section {
                Toggle("로그인 시 자동 시작", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }
            
            Section("호버 설정") {
                HStack {
                    Text("팝업 표시 지연")
                    Spacer()
                    TextField("", value: $hoverDelay, format: .number)
                        .frame(width: 50)
                    Text("초")
                }
                
                HStack {
                    Text("팝업 숨김 지연")
                    Spacer()
                    TextField("", value: $unhoverDelay, format: .number)
                        .frame(width: 50)
                    Text("초")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - Widget Settings
    
    private var widgetSettings: some View {
        Form {
            Section("표시할 위젯") {
                Toggle("미디어 플레이어", isOn: $showMediaWidget)
                Toggle("날씨", isOn: $showWeatherWidget)
                Toggle("시스템 모니터", isOn: $showSystemWidget)
                Toggle("빠른 설정", isOn: $showQuickSettings)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - About View
    
    private var aboutView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.topthird.inset.filled")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("NotchBar")
                .font(.title)
                .fontWeight(.bold)
            
            Text("버전 1.0.0")
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.horizontal, 40)
            
            Text("MacBook 노치를 활용한 유틸리티 앱")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Link("GitHub", destination: URL(string: "https://github.com/Hbin77/NotchBar")!)
                .font(.caption)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Helpers
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("로그인 시작 설정 오류: \(error)")
            }
        }
    }
}

#Preview {
    SettingsView()
}
