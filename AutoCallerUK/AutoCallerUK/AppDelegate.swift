//
//  AppDelegate.swift
//  HealthcareCallApp
//
//  App lifecycle and setup
//

import UIKit
import CoreData
import UserNotifications
import CallKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Setup Core Data
        setupCoreData()
        
        // Setup notifications
        setupNotifications()
        
        // Setup CallKit monitoring
        setupCallMonitoring()
        
        // Request notification permissions
        requestNotificationPermissions()
        
        // Create demo data if needed
        createDemoDataIfNeeded()
        
        // Configure appearance
        configureAppearance()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
    }
    
    // MARK: - Core Data Setup
    
    private func setupCoreData() {
        // Core Data is initialized through DataManager.shared
        _ = DataManager.shared
        print("Core Data stack initialized")
    }
    
    // MARK: - Notifications Setup
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        // Setup notification categories and actions
        setupNotificationCategories()
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
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([callCategory])
    }
    
    private func requestNotificationPermissions() {
        CallScheduler.shared.requestNotificationPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permissions granted")
                    // Schedule any pending notifications
                    CallScheduler.shared.rescheduleAllNotifications()
                } else {
                    print("Notification permissions denied")
                    self.showNotificationPermissionAlert()
                }
            }
        }
    }
    
    private func showNotificationPermissionAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let alert = UIAlertController(
            title: "Notification Permission Required",
            message: "To receive call reminders, please enable notifications in Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        rootViewController.present(alert, animated: true)
    }
    
    // MARK: - CallKit Setup
    
    private func setupCallMonitoring() {
        CallStateMonitor.shared.startMonitoring()
        print("Call monitoring started")
    }
    
    // MARK: - Demo Data
    
    private func createDemoDataIfNeeded() {
        #if DEBUG
        // Only create demo data in debug builds
        DataManager.shared.createDemoData()
        #endif
    }
    
    // MARK: - Appearance Configuration
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .systemBlue
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().tintColor = .white
        
        // Configure tab bar appearance if using tab bar controller
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure other UI elements
        UITableView.appearance().backgroundColor = .systemGroupedBackground
        UITableViewCell.appearance().backgroundColor = .clear
    }
    
    // MARK: - Background Tasks
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Save Core Data context when app enters background
        DataManager.shared.save()
        
        // Schedule background app refresh if needed
        scheduleBackgroundAppRefresh()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Refresh data when app comes to foreground
        refreshAppData()
    }
    
    private func scheduleBackgroundAppRefresh() {
        // Schedule background app refresh for call scheduling
        let request = BGAppRefreshTaskRequest(identifier: "com.healthcarecall.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    private func refreshAppData() {
        // Check for any missed calls or updates
        CallScheduler.shared.rescheduleAllNotifications()
        
        // Post notification to refresh UI
        NotificationCenter.default.post(name: .appDidBecomeActive, object: nil)
    }
    
    // MARK: - Error Handling
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - Memory Management
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        // Clear any cached data if needed
        print("Received memory warning")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        // Handle different notification actions
        switch actionIdentifier {
        case "SNOOZE_ACTION":
            handleSnoozeAction(userInfo: userInfo)
            
        case "CALL_ACTION":
            handleCallAction(userInfo: userInfo)
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            handleNotificationTap(userInfo: userInfo)
            
        default:
            break
        }
        
        completionHandler()
    }
    
    private func handleSnoozeAction(userInfo: [AnyHashable: Any]) {
        guard let setupIDString = userInfo["setupID"] as? String,
              let setupID = UUID(uuidString: setupIDString),
              let setup = DataManager.shared.fetchCallSetup(by: setupID) else {
            return
        }
        
        CallScheduler.shared.snoozeSetup(setup)
        
        // Show confirmation
        showLocalNotification(title: "Setup Snoozed", body: "\(setup.name) has been snoozed for 1 hour")
    }
    
    private func handleCallAction(userInfo: [AnyHashable: Any]) {
        guard let setupIDString = userInfo["setupID"] as? String,
              let setupID = UUID(uuidString: setupIDString),
              let setup = DataManager.shared.fetchCallSetup(by: setupID) else {
            return
        }
        
        CallScheduler.shared.initiateCall(for: setup)
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Navigate to appropriate screen
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        // If app was launched from notification, navigate to dashboard
        if let tabBarController = window.rootViewController as? UITabBarController {
            tabBarController.selectedIndex = 0 // Dashboard tab
        } else if let navigationController = window.rootViewController as? UINavigationController {
            navigationController.popToRootViewController(animated: true)
        }
    }
    
    private func showLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Background Tasks

import BackgroundTasks

extension AppDelegate {
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.healthcarecall.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule next background refresh
        scheduleBackgroundAppRefresh()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform background work
        DispatchQueue.global(qos: .background).async {
            // Check for scheduled calls and update notifications
            CallScheduler.shared.rescheduleAllNotifications()
            
            // Mark task as completed
            task.setTaskCompleted(success: true)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
}
