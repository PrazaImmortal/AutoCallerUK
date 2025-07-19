//
//  CallStateMonitor.swift
//  HealthcareCallApp
//
//  CallKit integration for call monitoring and state management
//

import Foundation
import CallKit
import UIKit

class CallStateMonitor: NSObject {
    
    static let shared = CallStateMonitor()
    
    private let callObserver = CXCallObserver()
    private let dataManager = DataManager.shared
    private var activeCallEntries: [UUID: CallLogEntry] = [:]
    
    override init() {
        super.init()
        setupCallObserver()
    }
    
    // MARK: - Setup
    
    private func setupCallObserver() {
        callObserver.setDelegate(self, queue: nil)
    }
    
    // MARK: - Call Monitoring
    
    func startMonitoring() {
        // Monitor is automatically started when delegate is set
        print("Call monitoring started")
    }
    
    func stopMonitoring() {
        callObserver.setDelegate(nil, queue: nil)
        print("Call monitoring stopped")
    }
    
    // MARK: - Call Management
    
    func initiateCall(to phoneNumber: String, for setup: CallSetup) -> CallLogEntry {
        // Create call log entry
        let logEntry = dataManager.createCallLogEntry()
        logEntry.setupID = setup.id ?? UUID()  // Use a fallback UUID if nil
        logEntry.providerName = setup.name ?? "Unknown"  // Use a fallback string if nil
        logEntry.phoneNumber = phoneNumber
        logEntry.callStatus = .inProgress
        logEntry.callIdentifier = UUID().uuidString
        
        dataManager.save()
        
        // Store active call entry
        if let callUUID = UUID(uuidString: logEntry.callIdentifier ?? "") {
            activeCallEntries[callUUID] = logEntry
        }
        
        // Initiate the actual call
        makePhoneCall(to: phoneNumber)
        
        return logEntry
    }
    
    private func makePhoneCall(to phoneNumber: String) {
        let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        
        guard let url = URL(string: "tel://\(cleanNumber)") else {
            print("Invalid phone number: \(phoneNumber)")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                if !success {
                    print("Failed to initiate call to \(phoneNumber)")
                }
            }
        } else {
            print("Device cannot make phone calls")
        }
    }
    
    // MARK: - Call State Handling
    
    private func handleCallStarted(_ call: CXCall) {
        print("Call started: \(call.uuid)")
        
        // Find matching log entry by phone number or create new one
        let phoneNumber = extractPhoneNumber(from: call)
        updateCallLogForStartedCall(callUUID: call.uuid, phoneNumber: phoneNumber)
    }
    
    private func handleCallEnded(_ call: CXCall) {
        print("Call ended: \(call.uuid)")
        
        // Update call log entry
        if let logEntry = activeCallEntries[call.uuid] {
            updateCallLogForEndedCall(logEntry: logEntry, call: call)
            activeCallEntries.removeValue(forKey: call.uuid)
        } else {
            // Handle calls not initiated by our app
            handleExternalCallEnded(call)
        }
    }
    
    private func updateCallLogForStartedCall(callUUID: UUID, phoneNumber: String?) {
        // Try to find existing log entry
        if let logEntry = activeCallEntries[callUUID] {
            logEntry.callStatus = .inProgress
            logEntry.timestamp = Date()
        } else if let phoneNumber = phoneNumber {
            // Create new entry for external call
            let logEntry = dataManager.createCallLogEntry()
            logEntry.callIdentifier = callUUID.uuidString
            logEntry.phoneNumber = phoneNumber
            logEntry.providerName = "Unknown"
            logEntry.setupID = UUID() // Placeholder
            logEntry.callStatus = .inProgress
            
            activeCallEntries[callUUID] = logEntry
        }
        
        dataManager.save()
    }
    
    private func updateCallLogForEndedCall(logEntry: CallLogEntry, call: CXCall) {
        let callDuration = Date().timeIntervalSince(logEntry.timestamp)
        
        // Determine if call was successful based on duration
        let wasSuccessful = callDuration > 5.0 // Consider calls longer than 5 seconds as successful
        
        logEntry.callStatus = wasSuccessful ? .success : .failed
        logEntry.duration = Int32(callDuration)
        
        dataManager.save()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .callCompleted, object: logEntry)
        
        // Handle retry logic if call failed
        if !wasSuccessful {
            handleFailedCall(logEntry: logEntry)
        }
    }
    
    private func handleExternalCallEnded(_ call: CXCall) {
        // Handle calls not initiated by our app
        let phoneNumber = extractPhoneNumber(from: call)
        print("External call ended to: \(phoneNumber ?? "unknown")")
    }
    
    private func handleFailedCall(logEntry: CallLogEntry) {
        // Find the associated setup
        guard let setup = dataManager.fetchCallSetup(by: logEntry.setupID) else { return }
        
        // Check if we should retry
        if logEntry.attempts < setup.retryAttempts {
            scheduleRetry(for: setup, logEntry: logEntry)
        }
    }
    
    private func scheduleRetry(for setup: CallSetup, logEntry: CallLogEntry) {
        let retryDelay = TimeInterval(setup.retryDelay * 60) // Convert minutes to seconds
        
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
            logEntry.attempts += 1
            logEntry.timestamp = Date()
            logEntry.callStatus = .inProgress
            
            self?.dataManager.save()
            
            // Initiate retry call
            self?.makePhoneCall(to: setup.phoneNumber ?? "")

        }
    }
    
    // MARK: - Utility Methods
    
    private func extractPhoneNumber(from call: CXCall) -> String? {
        // In a real implementation, you might extract this from call details
        // For now, we'll return nil as CallKit doesn't directly provide this
        return nil
    }
    
    func getActiveCallsCount() -> Int {
        return callObserver.calls.count
    }
    
    func hasActiveCalls() -> Bool {
        return !callObserver.calls.isEmpty
    }
    
    func getActiveCallDetails() -> [(UUID, Bool)] {
        return callObserver.calls.map { ($0.uuid, $0.hasEnded) }
    }
    
    // MARK: - Statistics
    
    func getCallStatistics() -> CallStatistics {
        let allLogs = dataManager.fetchAllCallLogs()
        
        let totalCalls = allLogs.count
        let successfulCalls = allLogs.filter { $0.isSuccessful }.count
        let failedCalls = totalCalls - successfulCalls
        let sCalls = Int(successfulCalls)
        let averageDuration = allLogs
            .compactMap { $0.duration > 0 ? $0.duration : nil }
            .reduce(0) { $0 + Int($1) } / max(1, sCalls)
        
        let today = Calendar.current.startOfDay(for: Date())
        let todaysCalls = allLogs.filter { Calendar.current.startOfDay(for: $0.timestamp) == today }.count
        
        return CallStatistics(
            totalCalls: totalCalls,
            successfulCalls: successfulCalls,
            failedCalls: failedCalls,
            averageDuration: Int32(averageDuration),
            todaysCalls: todaysCalls
        )
    }
}

// MARK: - CXCallObserverDelegate

extension CallStateMonitor: CXCallObserverDelegate {
    
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        print("Call state changed: \(call.uuid), hasEnded: \(call.hasEnded), hasConnected: \(call.hasConnected)")
        
        if call.hasConnected && !call.hasEnded {
            handleCallStarted(call)
        } else if call.hasEnded {
            handleCallEnded(call)
        }
    }
}

// MARK: - Call Statistics Model

struct CallStatistics {
    let totalCalls: Int
    let successfulCalls: Int
    let failedCalls: Int
    let averageDuration: Int32
    let todaysCalls: Int
    
    var successRate: Double {
        guard totalCalls > 0 else { return 0.0 }
        return Double(successfulCalls) / Double(totalCalls) * 100.0
    }
    
    var formattedAverageDuration: String {
        let minutes = averageDuration / 60
        let seconds = averageDuration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Call Event Types

enum CallEvent {
    case started(UUID)
    case connected(UUID)
    case ended(UUID, duration: TimeInterval)
    case failed(UUID, error: Error?)
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let callStateChanged = Notification.Name("callStateChanged")
    static let callStatisticsUpdated = Notification.Name("callStatisticsUpdated")
}
