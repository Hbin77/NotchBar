//
//  SystemMonitor.swift
//  NotchBar
//
//  시스템 리소스 모니터링 (CPU, Memory, Battery)
//

import Foundation
import IOKit.ps
import Combine

@MainActor
class SystemMonitor: ObservableObject {

    // MARK: - Singleton

    static let shared = SystemMonitor()

    // MARK: - Published Properties

    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var memoryUsed: UInt64 = 0
    @Published var memoryTotal: UInt64 = 0
    @Published var batteryLevel: Int = 100
    @Published var isCharging: Bool = false
    @Published var batteryTimeRemaining: String = ""

    // MARK: - Private Properties

    private var timer: Timer?
    private var previousTotalTicks: Int64 = 0
    private var previousUsedTicks: Int64 = 0
    private let hostPort = mach_host_self()  // 캐시하여 포트 누수 방지

    // MARK: - Initialization

    private init() {
        memoryTotal = getPhysicalMemory()
        startMonitoring()
    }

    // MARK: - Public Methods

    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStats()
            }
        }
        updateStats()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private Methods

    private func updateStats() {
        updateCPU()
        updateMemory()
        updateBattery()
    }

    // MARK: - CPU

    private func updateCPU() {
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0

        let err = host_processor_info(
            hostPort,
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )

        guard err == KERN_SUCCESS, let cpuInfo = cpuInfo else { return }

        var totalUser: Int64 = 0
        var totalSystem: Int64 = 0
        var totalIdle: Int64 = 0

        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            totalUser += Int64(cpuInfo[offset + Int(CPU_STATE_USER)])
            totalSystem += Int64(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            totalIdle += Int64(cpuInfo[offset + Int(CPU_STATE_IDLE)])
        }

        let totalTicks = totalUser + totalSystem + totalIdle
        let usedTicks = totalUser + totalSystem

        let deltaTotalTicks = totalTicks - previousTotalTicks
        let deltaUsedTicks = usedTicks - previousUsedTicks

        if previousTotalTicks > 0 && deltaTotalTicks > 0 {
            cpuUsage = Double(deltaUsedTicks) / Double(deltaTotalTicks) * 100
        }

        previousTotalTicks = totalTicks
        previousUsedTicks = usedTicks

        let cpuInfoSize = vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<integer_t>.stride)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), cpuInfoSize)
    }

    // MARK: - Memory

    private func updateMemory() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize

        let used = active + wired + compressed

        memoryUsed = used
        memoryUsage = Double(used) / Double(memoryTotal) * 100
    }

    private func getPhysicalMemory() -> UInt64 {
        var size: size_t = MemoryLayout<UInt64>.size
        var memory: UInt64 = 0
        sysctlbyname("hw.memsize", &memory, &size, nil, 0)
        return memory
    }

    // MARK: - Battery

    private func updateBattery() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source as CFTypeRef)?.takeUnretainedValue() as? [String: Any]
        else {
            return
        }

        if let capacity = description[kIOPSCurrentCapacityKey] as? Int {
            batteryLevel = capacity
        }

        if let charging = description[kIOPSIsChargingKey] as? Bool {
            isCharging = charging
        }

        if let timeRemaining = description[kIOPSTimeToEmptyKey] as? Int, timeRemaining > 0 {
            let hours = timeRemaining / 60
            let minutes = timeRemaining % 60
            batteryTimeRemaining = String(format: "%d:%02d", hours, minutes)
        } else if let timeToFull = description[kIOPSTimeToFullChargeKey] as? Int, timeToFull > 0 {
            let hours = timeToFull / 60
            let minutes = timeToFull % 60
            batteryTimeRemaining = String(format: "%d:%02d 충전", hours, minutes)
        } else {
            batteryTimeRemaining = ""
        }
    }
}
