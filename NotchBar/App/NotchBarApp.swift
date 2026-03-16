//
//  NotchBarApp.swift
//  NotchBar
//
//  MacBook 노치 유틸리티 앱
//

import SwiftUI

@main
struct NotchBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
