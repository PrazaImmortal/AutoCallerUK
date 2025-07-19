//
//  CallScheduler.swift
//  HealthcareCallApp
//
//  Notification scheduling and management service
//

import Foundation
import UserNotifications
import UIKit

class CallScheduler {
    
    static let shared = CallScheduler()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let dataManager = DataManager.shared
    
    private init() {
        setupNotificationCategories()
    }
    
    // MARK: - Notification Setup
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    private func setupNotificationCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 1 Hour",
            options: []
        )
        
        let callAction = UNNotificationAction(
            identifier: "CALL_ACTION",
            title: "Call Now",
            options: [.foreground]
        )
        
        let callCategory = UNNotificationCategory(
            identifier: "CALL_REMINDER",
            actions: [callAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([callCategory])
    }
    
    // MARK: - Schedule Management
    
    func scheduleNotifications(for setup: CallSetup) {
        // Remove existing notifications for this setup
        cancelNotifications(for: setup)
        
        // Don't schedule if setup is inactive or snoozed
        guard setup.isActive && !setup.isCurrentlySnoozed else { return }
        
        _ = Calendar.current
        _ = Date()
        
        // Schedule for each selected weekday
        for weekday in setup.weekdaysArray {
            // Create date components for the notification
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday == 0 ? 1 : weekday + 1 // Convert to Calendar weekday format
            dateComponents.hour = Int(setup.hour)
            dateComponents.minute = Int(setup.minute)
            
            // Create the trigger
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "Healthcare Call Reminder"
            content.body = "Time to call \(setup.name ?? "Unknown") at \(setup.phoneNumber ?? "Unknown")"
            content.sound = .default
            content.categoryIdentifier = "CALL_REMINDER"
            content.userInfo = [
                "setupID": setup.id?.uuidString ?? "",
                "providerName": setup.name ?? "Unknown",
                "phoneNumber": setup.phoneNumber ?? "Unknown",
                "weekday": weekday
            ]
            
            // Create the request
            let identifier = "call_\(setup.id?.uuidString ?? UUID().uuidString)_\(weekday)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            // Schedule the notification
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
    
    func cancelNotifications(for setup: CallSetup) {
        let identifiers = setup.weekdaysArray.map { "call_\(setup.id?.uuidString ?? UUID().uuidString)_\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func rescheduleAllNotifications() {
        let setups = dataManager.fetchAllCallSetups()
        
        // Cancel all existing notifications
        cancelAllNotifications()
        
        // Reschedule for active setups
        for setup in setups {
            scheduleNotifications(for: setup)
        }
    }
    
    // MARK: - Snooze Management
    
    func snoozeSetup(_ setup: CallSetup, for duration: TimeInterval = 3600) { // Default 1 hour
        setup.snoozeUntil = Date().addingTimeInterval(duration)
        dataManager.save()
        
        // Cancel current notifications
        cancelNotifications(for: setup)
        
        // Schedule a notification to resume
        scheduleResumeNotification(for: setup)
    }
    
    func unsnoozeSetup(_ setup: CallSetup) {
        setup.snoozeUntil = nil
        dataManager.save()
        
        // Cancel resume notification
        let resumeIdentifier = "resume_\(setup.id?.uuidString ?? UUID().uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [resumeIdentifier])
        
        // Reschedule regular notifications
        scheduleNotifications(for: setup)
    }
    
    private func scheduleResumeNotification(for setup: CallSetup) {
        guard let snoozeUntil = setup.snoozeUntil else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Call Setup Resumed"
        content.body = "\(setup.name ?? "Unknown") call reminders have been resumed"
        content.sound = .default
        content.userInfo = ["setupID": setup.id?.uuidString ?? "", "action": "resume"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: snoozeUntil.timeIntervalSinceNow, repeats: false)
        let identifier = "resume_\(setup.id?.uuidString ?? UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling resume notification: \(error)")
            }
        }
    }
    
    // MARK: - Call Initiation
    
    func initiateCall(for setup: CallSetup) {
        // Create call log entry
        let logEntry = dataManager.createCallLogEntry()
        logEntry.setupID = setup.id ?? UUID()
        logEntry.providerName = setup.name ?? "Unknown"
        logEntry.phoneNumber = setup.phoneNumber ?? "Unknown"
        logEntry.callStatus = .inProgress
        
        dataManager.save()
        
        // Attempt to make the call
        makeCall(to: setup.phoneNumber ?? "Unknown") { [weak self] success, duration in
            self?.handleCallResult(logEntry: logEntry, setup: setup, success: success, duration: duration)
        }
    }
    
    private func makeCall(to phoneNumber: String, completion: @escaping (Bool, Int32) -> Void) {
        // Clean phone number for calling
        let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        
        guard let url = URL(string: "tel://\(cleanNumber)") else {
            completion(false, 0)
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                // Simulate call duration and success rate for demo
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    let callSuccess = Bool.random() // 50% success rate for demo
                    let duration: Int32 = callSuccess ? Int32.random(in: 30...300) : 0
                    completion(callSuccess, duration)
                }
            }
        } else {
            completion(false, 0)
        }
    }
    
    private func handleCallResult(logEntry: CallLogEntry, setup: CallSetup, success: Bool, duration: Int32) {
        logEntry.callStatus = success ? .success : .failed
        logEntry.duration = duration
        
        if !success && logEntry.attempts < setup.retryAttempts {
            // Schedule retry
            scheduleRetry(for: setup, logEntry: logEntry)
        }
        
        dataManager.save()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .callCompleted, object: logEntry)
        
        // Show local notification about call result
        showCallResultNotification(setup: setup, success: success, duration: duration)
    }
    
    private func scheduleRetry(for setup: CallSetup, logEntry: CallLogEntry) {
        let retryDelay = TimeInterval(setup.retryDelay * 60) // Convert minutes to seconds
        
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
            logEntry.attempts += 1
            logEntry.timestamp = Date()
            
            self?.makeCall(to: setup.phoneNumber ?? "Unknown") { success, duration in
                self?.handleCallResult(logEntry: logEntry, setup: setup, success: success, duration: duration)
            }
        }
    }
    
    private func showCallResultNotification(setup: CallSetup, success: Bool, duration: Int32) {
        let content = UNMutableNotificationContent()
        content.title = success ? "Call Completed" : "Call Failed"
        
        if success {
            let minutes = duration / 60
            let seconds = duration % 60
            content.body = "Successfully called \(setup.name ?? "Unknown"). Duration: \(minutes):\(String(format: "%02d", seconds))"
        } else {
            content.body = "Failed to reach \(setup.name ?? "Unknown"). Will retry if configured."
        }
        
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "call_result_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    // MARK: - Notification Handling
    
    func handleNotificationAction(identifier: String, userInfo: [AnyHashable: Any]) {
        guard let setupIDString = userInfo["setupID"] as? String,
              let setupID = UUID(uuidString: setupIDString),
              let setup = dataManager.fetchCallSetup(by: setupID) else {
            return
        }
        
        switch identifier {
        case "SNOOZE_ACTION":
            snoozeSetup(setup)
            
        case "CALL_ACTION":
            initiateCall(for: setup)
            
        default:
            break
        }
    }
    
    // MARK: - Utility
    
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
    
    func getNotificationSettings(completion: @escaping (UNNotificationSettings) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings)
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let callCompleted = Notification.Name("callCompleted")
    static let callScheduled = Notification.Name("callScheduled")
    static let setupSnoozed = Notification.Name("setupSnoozed")
}
