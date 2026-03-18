//
//  AppleScriptRunner.swift
//  NotchBar
//
//  AppleScript 실행 공통 유틸리티
//

import Foundation
import os.log

enum AppleScriptRunner {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "NotchBar",
        category: "AppleScript"
    )

    @discardableResult
    nonisolated static func run(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let output = script.executeAndReturnError(&error)

        if let error {
            logger.debug("AppleScript error: \(error)")
            return nil
        }

        return output.stringValue
    }
}
