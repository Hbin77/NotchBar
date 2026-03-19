//
//  BrightnessHelper.swift
//  NotchBar
//
//  DisplayServices private framework를 통한 밝기 제어
//  Apple Silicon + macOS 12+ 에서 동작
//

import Foundation
import CoreGraphics
import IOKit.graphics

enum BrightnessHelper {

    // DisplayServices.framework private API
    private typealias SetBrightnessFunc = @convention(c) (UInt32, Float) -> Int32
    private typealias GetBrightnessFunc = @convention(c) (UInt32, UnsafeMutablePointer<Float>) -> Int32

    private static let handle: UnsafeMutableRawPointer? = {
        dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY)
    }()

    static func set(_ value: Float) {
        let clamped = min(max(value, 0), 1)

        // 1차: DisplayServicesSetBrightness (macOS 12+, Apple Silicon)
        if let handle,
           let sym = dlsym(handle, "DisplayServicesSetBrightness") {
            let fn = unsafeBitCast(sym, to: SetBrightnessFunc.self)
            _ = fn(CGMainDisplayID(), clamped)
            return
        }

        // 2차: CoreDisplay_Display_SetUserBrightness
        if let coreDisplay = dlopen("/System/Library/Frameworks/CoreDisplay.framework/CoreDisplay", RTLD_LAZY),
           let sym = dlsym(coreDisplay, "CoreDisplay_Display_SetUserBrightness") {
            let fn = unsafeBitCast(sym, to: SetBrightnessFunc.self)
            _ = fn(CGMainDisplayID(), clamped)
            return
        }

        // 3차: IOKit 폴백
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"), &iterator) == kIOReturnSuccess else { return }
        defer { IOObjectRelease(iterator) }
        var service = IOIteratorNext(iterator)
        while service != 0 {
            IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, clamped)
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
    }

    static func get() -> Float {
        // 1차: DisplayServicesGetBrightness
        if let handle,
           let sym = dlsym(handle, "DisplayServicesGetBrightness") {
            let fn = unsafeBitCast(sym, to: GetBrightnessFunc.self)
            var value: Float = 0.5
            _ = fn(CGMainDisplayID(), &value)
            return value
        }

        // 2차: CoreDisplay
        if let coreDisplay = dlopen("/System/Library/Frameworks/CoreDisplay.framework/CoreDisplay", RTLD_LAZY),
           let sym = dlsym(coreDisplay, "CoreDisplay_Display_GetUserBrightness") {
            let fn = unsafeBitCast(sym, to: GetBrightnessFunc.self)
            var value: Float = 0.5
            _ = fn(CGMainDisplayID(), &value)
            return value
        }

        // 3차: IOKit 폴백
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"), &iterator) == kIOReturnSuccess else { return 0.5 }
        defer { IOObjectRelease(iterator) }
        let service = IOIteratorNext(iterator)
        guard service != 0 else { return 0.5 }
        defer { IOObjectRelease(service) }
        var br: Float = 0.5
        IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &br)
        return br
    }
}
