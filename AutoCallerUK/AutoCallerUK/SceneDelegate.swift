//
//  SceneDelegate.swift
//  HealthcareCallApp
//
//  Scene management for iOS 13+
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Create window
        window = UIWindow(windowScene: windowScene)
        
        // Setup root view controller
        setupRootViewController()
        
        // Make window key and visible
        window?.makeKeyAndVisible()
        
        // Handle any notification that launched the app
        handleLaunchNotification(connectionOptions)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        // Refresh app data
        refreshAppData()
        
        // Update badge count
        updateBadgeCount()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .sceneDidBecomeActive, object: nil)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        
        // Save any pending data
        DataManager.shared.save()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        
        // Refresh notifications
        CallScheduler.shared.rescheduleAllNotifications()
        
        // Update UI
        refreshAppData()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
        // Save Core Data context
        DataManager.shared.save()
        
        // Update badge count
        updateBadgeCount()
    }
    
    // MARK: - Setup
    
    private func setupRootViewController() {
        // Create main storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Check if we should use tab bar or navigation controller
        if let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
            // Using tab bar controller
            setupTabBarController(tabBarController)
            window?.rootViewController = tabBarController
        } else {
            // Fallback to navigation controller with dashboard
            let dashboardVC = MainDashboardViewController()
            let navigationController = UINavigationController(rootViewController: dashboardVC)
            setupNavigationController(navigationController)
            window?.rootViewController = navigationController
        }
    }
    
    private func setupTabBarController(_ tabBarController: UITabBarController) {
        // Configure tab bar appearance
        tabBarController.tabBar.tintColor = .systemBlue
        tabBarController.tabBar.backgroundColor = .systemBackground
        
        // Setup view controllers
        var viewControllers: [UIViewController] = []
        
        // Dashboard tab
        let dashboardVC = MainDashboardViewController()
        let dashboardNav = UINavigationController(rootViewController: dashboardVC)
        dashboardNav.tabBarItem = UITabBarItem(
            title: "Dashboard",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        viewControllers.append(dashboardNav)
        
        // Call Log tab
        let callLogVC = CallLogViewController()
        let callLogNav = UINavigationController(rootViewController: callLogVC)
        callLogNav.tabBarItem = UITabBarItem(
            title: "Call Log",
            image: UIImage(systemName: "phone.badge.checkmark"),
            selectedImage: UIImage(systemName: "phone.badge.checkmark.fill")
        )
        viewControllers.append(callLogNav)
        
        // Settings tab (placeholder for future implementation)
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gear"),
            selectedImage: UIImage(systemName: "gear.fill")
        )
        viewControllers.append(settingsNav)
        
        tabBarController.viewControllers = viewControllers
        
        // Set default selected tab
        tabBarController.selectedIndex = 0
    }
    
    private func setupNavigationController(_ navigationController: UINavigationController) {
        // Configure navigation bar
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationBar.tintColor = .white
        
        // Set navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBlue
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
    }
    
    // MARK: - Notification Handling
    
    private func handleLaunchNotification(_ connectionOptions: UIScene.ConnectionOptions) {
        // Check if app was launched from a notification
        if let notificationResponse = connectionOptions.notificationResponse {
            handleNotificationResponse(notificationResponse)
        }
    }
    
    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        // Navigate to appropriate screen based on notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.navigateToNotificationContent(userInfo: userInfo)
        }
    }
    
    private func navigateToNotificationContent(userInfo: [AnyHashable: Any]) {
        guard let setupIDString = userInfo["setupID"] as? String,
              let setupID = UUID(uuidString: setupIDString) else {
            return
        }
        
        // Navigate to dashboard and highlight the specific setup
        if let tabBarController = window?.rootViewController as? UITabBarController {
            tabBarController.selectedIndex = 0 // Dashboard tab
            
            if let navigationController = tabBarController.selectedViewController as? UINavigationController,
               let dashboardVC = navigationController.topViewController as? MainDashboardViewController {
                // Highlight specific setup (implementation would depend on dashboard structure)
                dashboardVC.highlightSetup(with: setupID)
            }
        }
    }
    
    // MARK: - Data Refresh
    
    private func refreshAppData() {
        // Refresh call setups and logs
        NotificationCenter.default.post(name: .dataRefreshRequested, object: nil)
        
        // Check for any pending notifications
        CallScheduler.shared.getPendingNotifications { notifications in
            print("Pending notifications: \(notifications.count)")
        }
    }
    
    private func updateBadgeCount() {
        // Update app badge with pending calls or notifications
        let pendingSetups = DataManager.shared.getScheduledCallSetups()
        let todaysPendingCalls = pendingSetups.filter { setup in
            guard let nextCall = setup.nextCallDate else { return false }
            return Calendar.current.isDateInToday(nextCall)
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = todaysPendingCalls.count
        }
    }
    
    // MARK: - Deep Linking
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleDeepLink(url)
    }
    
    private func handleDeepLink(_ url: URL) {
        // Handle custom URL schemes
        // Example: healthcarecall://setup/new or healthcarecall://log
        
        guard url.scheme == "healthcarecall" else { return }
        
        switch url.host {
        case "setup":
            if url.path == "/new" {
                presentNewSetupScreen()
            }
        case "log":
            navigateToCallLog()
        default:
            break
        }
    }
    
    private func presentNewSetupScreen() {
        guard let tabBarController = window?.rootViewController as? UITabBarController,
              let navigationController = tabBarController.selectedViewController as? UINavigationController else {
            return
        }
        
        let setupVC = CallSetupViewController()
        let setupNav = UINavigationController(rootViewController: setupVC)
        navigationController.present(setupNav, animated: true)
    }
    
    private func navigateToCallLog() {
        guard let tabBarController = window?.rootViewController as? UITabBarController else {
            return
        }
        
        // Switch to call log tab
        tabBarController.selectedIndex = 1
    }
    
    // MARK: - State Restoration
    
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        // Return user activity for state restoration
        let activity = NSUserActivity(activityType: "com.healthcarecall.dashboard")
        activity.title = "Healthcare Call Manager"
        activity.userInfo = ["lastScreen": "dashboard"]
        return activity
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // Handle state restoration
        if userActivity.activityType == "com.healthcarecall.dashboard" {
            // Restore to dashboard
            if let tabBarController = window?.rootViewController as? UITabBarController {
                tabBarController.selectedIndex = 0
            }
        }
    }
}

// MARK: - Settings View Controller (Placeholder)

class SettingsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground
        
        // Add placeholder content
        let label = UILabel()
        label.text = "Settings\n(Coming Soon)"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - Extensions

extension MainDashboardViewController {
    func highlightSetup(with id: UUID) {
        // Implementation to highlight specific setup
        // This would scroll to and highlight the setup in the table view
        print("Highlighting setup with ID: \(id)")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let sceneDidBecomeActive = Notification.Name("sceneDidBecomeActive")
    static let dataRefreshRequested = Notification.Name("dataRefreshRequested")
}