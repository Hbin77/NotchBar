//
//  SystemMonitor.swift
//  NotchBar
//
//  시스템 리소스 모니터링 (CPU, Memory, Battery)
//

import Foundation
import IOKit.ps
import Combine

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
    private var previousCPUInfo: host_cpu_load_info?
    
    // MARK: - Initialization
    
    private init() {
        memoryTotal = getPhysicalMemory()
        startMonitoring()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        // 2초마다 업데이트
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateStats()
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
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )
        
        guard err == KERN_SUCCESS, let cpuInfo = cpuInfo else { return }
        
        var totalUser: Int32 = 0
        var totalSystem: Int32 = 0
        var totalIdle: Int32 = 0
        
        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            totalUser += cpuInfo[offset + Int(CPU_STATE_USER)]
            totalSystem += cpuInfo[offset + Int(CPU_STATE_SYSTEM)]
            totalIdle += cpuInfo[offset + Int(CPU_STATE_IDLE)]
        }
        
        let totalTicks = totalUser + totalSystem + totalIdle
        let usedTicks = totalUser + totalSystem
        
        if totalTicks > 0 {
            DispatchQueue.main.async { [weak self] in
                self?.cpuUsage = Double(usedTicks) / Double(totalTicks) * 100
            }
        }
        
        // 메모리 해제
        let cpuInfoSize = vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<integer_t>.stride)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), cpuInfoSize)
    }
    
    // MARK: - Memory
    
    private func updateMemory() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return }
        
        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        
        let used = active + wired + compressed
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.memoryUsed = used
            self.memoryUsage = Double(used) / Double(self.memoryTotal) * 100
        }
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
        
        DispatchQueue.main.async { [weak self] in
            if let capacity = description[kIOPSCurrentCapacityKey] as? Int {
                self?.batteryLevel = capacity
            }
            
            if let isCharging = description[kIOPSIsChargingKey] as? Bool {
                self?.isCharging = isCharging
            }
            
            if let timeRemaining = description[kIOPSTimeToEmptyKey] as? Int, timeRemaining > 0 {
                let hours = timeRemaining / 60
                let minutes = timeRemaining % 60
                self?.batteryTimeRemaining = String(format: "%d:%02d", hours, minutes)
            } else if let timeToFull = description[kIOPSTimeToFullChargeKey] as? Int, timeToFull > 0 {
                let hours = timeToFull / 60
                let minutes = timeToFull % 60
                self?.batteryTimeRemaining = String(format: "%d:%02d 충전", hours, minutes)
            } else {
                self?.batteryTimeRemaining = ""
            }
        }
    }
}
