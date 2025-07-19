//
//  Extensions.swift
//  HealthcareCallApp
//
//  Useful extensions and utility functions
//

import Foundation
import UIKit
import CoreData

// MARK: - String Extensions

extension String {
    
    /// Validates if string is a valid UK phone number
    var isValidUKPhoneNumber: Bool {
        let patterns = [
            "^\\+44\\s?[1-9]\\d{8,9}$",
            "^\\+44\\s?\\d{2}\\s?\\d{4}\\s?\\d{4}$",
            "^\\+44\\s?\\d{3}\\s?\\d{3}\\s?\\d{4}$",
            "^\\+44\\s?\\d{4}\\s?\\d{6}$"
        ]
        
        for pattern in patterns {
            let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
            if predicate.evaluate(with: self) {
                return true
            }
        }
        return false
    }
    
    /// Formats a UK phone number
    var formattedUKPhoneNumber: String {
        let digits = self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if digits.hasPrefix("44") && digits.count >= 12 {
            let areaCode = String(digits.dropFirst(2).prefix(2))
            let remaining = String(digits.dropFirst(4))
            return "+44 \(areaCode) \(remaining.formattedPhoneNumberPart)"
        } else if digits.hasPrefix("0") && digits.count >= 11 {
            let areaCode = String(digits.dropFirst(1).prefix(2))
            let remaining = String(digits.dropFirst(3))
            return "+44 \(areaCode) \(remaining.formattedPhoneNumberPart)"
        } else if digits.count >= 10 {
            let areaCode = String(digits.prefix(2))
            let remaining = String(digits.dropFirst(2))
            return "+44 \(areaCode) \(remaining.formattedPhoneNumberPart)"
        }
        
        return self
    }
    
    private var formattedPhoneNumberPart: String {
        if count == 8 {
            let firstPart = String(prefix(4))
            let secondPart = String(suffix(4))
            return "\(firstPart) \(secondPart)"
        } else if count == 7 {
            let firstPart = String(prefix(3))
            let secondPart = String(suffix(4))
            return "\(firstPart) \(secondPart)"
        }
        return self
    }
    
    /// Removes whitespace and newlines
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Checks if string is empty or contains only whitespace
    var isBlank: Bool {
        return self.trimmed.isEmpty
    }
    
    /// Converts string to title case
    var titleCased: String {
        return self.capitalized
    }
}

// MARK: - Date Extensions

extension Date {
    
    /// Returns a formatted string for display
    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Returns a short time string (e.g., "2:30 PM")
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Returns a relative time string (e.g., "2 hours ago")
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Checks if date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Checks if date is yesterday
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// Checks if date is tomorrow
    var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }
    
    /// Returns the start of the day
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Returns the end of the day
    var endOfDay: Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: self)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? self
    }
    
    /// Returns the weekday (0 = Sunday, 1 = Monday, etc.)
    var weekday: Int {
        return Calendar.current.component(.weekday, from: self) - 1
    }
    
    /// Adds specified number of minutes
    func addingMinutes(_ minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
    
    /// Adds specified number of hours
    func addingHours(_ hours: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }
    
    /// Adds specified number of days
    func addingDays(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}

// MARK: - UIView Extensions

extension UIView {
    
    /// Adds multiple subviews at once
    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }
    
    /// Rounds specific corners
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    /// Adds shadow
    func addShadow(color: UIColor = .black, opacity: Float = 0.1, offset: CGSize = CGSize(width: 0, height: 2), radius: CGFloat = 4) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }
    
    /// Adds border
    func addBorder(color: UIColor, width: CGFloat) {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
    }
    
    /// Fades in the view
    func fadeIn(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        alpha = 0
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1
        }) { _ in
            completion?()
        }
    }
    
    /// Fades out the view
    func fadeOut(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0
        }) { _ in
            completion?()
        }
    }
    
    /// Shakes the view (useful for error indication)
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        layer.add(animation, forKey: "shake")
    }
    
    /// Pulses the view (useful for highlighting)
    func pulse() {
        UIView.animate(withDuration: 0.3, animations: {
            self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.transform = .identity
            }
        }
    }
}

// MARK: - UIViewController Extensions

extension UIViewController {
    
    /// Shows an alert with title and message
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    /// Shows a confirmation alert
    func showConfirmation(title: String, message: String, confirmTitle: String = "Confirm", cancelTitle: String = "Cancel", onConfirm: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            onConfirm()
        })
        present(alert, animated: true)
    }
    
    /// Shows a toast message
    func showToast(message: String, duration: TimeInterval = 2.0) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 8
        toastLabel.clipsToBounds = true
        
        view.addSubview(toastLabel)
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            toastLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            toastLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            toastLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: duration, options: [], animations: {
                toastLabel.alpha = 0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
    
    /// Hides keyboard when tapping outside
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UIColor Extensions

extension UIColor {
    
    /// Creates color from hex string
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            } else if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255
                    a = 1.0
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
    
    /// Returns hex string representation
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format:"#%06x", rgb)
    }
}

// MARK: - Array Extensions

extension Array where Element == Int {
    
    /// Converts weekday array to readable string
    var weekdayString: String {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sortedDays = self.sorted()
        return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
    }
    
    /// Converts weekday array to full day names
    var fullWeekdayString: String {
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let sortedDays = self.sorted()
        return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
    }
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    
    private enum Keys {
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let notificationPermissionRequested = "notificationPermissionRequested"
        static let lastAppVersion = "lastAppVersion"
    }
    
    var hasLaunchedBefore: Bool {
        get { return bool(forKey: Keys.hasLaunchedBefore) }
        set { set(newValue, forKey: Keys.hasLaunchedBefore) }
    }
    
    var notificationPermissionRequested: Bool {
        get { return bool(forKey: Keys.notificationPermissionRequested) }
        set { set(newValue, forKey: Keys.notificationPermissionRequested) }
    }
    
    var lastAppVersion: String? {
        get { return string(forKey: Keys.lastAppVersion) }
        set { set(newValue, forKey: Keys.lastAppVersion) }
    }
}

// MARK: - Bundle Extensions

extension Bundle {
    
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var appName: String {
        return infoDictionary?["CFBundleDisplayName"] as? String ?? "Healthcare Call App"
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let callSetupUpdated = Notification.Name("callSetupUpdated")
    static let callLogUpdated = Notification.Name("callLogUpdated")
    static let notificationPermissionChanged = Notification.Name("notificationPermissionChanged")
}

// MARK: - Core Data Extensions

extension NSManagedObjectContext {
    
    /// Performs a save operation with error handling
    func saveWithErrorHandling() {
        if hasChanges {
            do {
                try save()
            } catch {
                print("Core Data save error: \(error)")
                rollback()
            }
        }
    }
    
    /// Performs operation on background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let backgroundContext = DataManager.shared.backgroundContext
        backgroundContext.perform {
            block(backgroundContext)
            backgroundContext.saveWithErrorHandling()
        }
    }
}

// MARK: - Utility Functions

struct AppUtilities {
    
    /// Formats duration in seconds to readable string
    static func formatDuration(_ seconds: Int32) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    /// Generates a unique identifier
    static func generateUniqueID() -> String {
        return UUID().uuidString
    }
    
    /// Validates email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Opens phone app with number
    static func makePhoneCall(to phoneNumber: String) {
        let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        guard let url = URL(string: "tel://\(cleanNumber)") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    /// Opens settings app
    static func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
    
    /// Haptic feedback
    static func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// Success haptic feedback
    static func successHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Error haptic feedback
    static func errorHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

// MARK: - Constants

struct AppConstants {
    
    struct Colors {
        static let primary = UIColor.systemBlue
        static let secondary = UIColor.systemGray
        static let success = UIColor.systemGreen
        static let error = UIColor.systemRed
        static let warning = UIColor.systemOrange
    }
    
    struct Fonts {
        static let title = UIFont.systemFont(ofSize: 24, weight: .bold)
        static let subtitle = UIFont.systemFont(ofSize: 18, weight: .semibold)
        static let body = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let caption = UIFont.systemFont(ofSize: 12, weight: .regular)
    }
    
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
}