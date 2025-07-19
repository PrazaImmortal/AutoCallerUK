//
//  ValidationService.swift
//  HealthcareCallApp
//
//  Form validation and conflict detection service
//

import Foundation
import UIKit

class ValidationService {
    
    static let shared = ValidationService()
    
    private let dataManager = DataManager.shared
    
    private init() {}
    
    // MARK: - Validation Results
    
    struct ValidationResult {
        let isValid: Bool
        let errors: [ValidationError]
        
        var errorMessages: [String] {
            return errors.map { $0.message }
        }
    }
    
    enum ValidationError {
        case emptyName
        case invalidPhoneNumber
        case invalidTime
        case noWeekdaysSelected
        case invalidRetryAttempts
        case invalidRetryDelay
        case timeConflict([CallSetup])
        case custom(String)
        
        var message: String {
            switch self {
            case .emptyName:
                return "Name is required"
            case .invalidPhoneNumber:
                return "Please enter a valid UK phone number"
            case .invalidTime:
                return "Please select both hour and minute"
            case .noWeekdaysSelected:
                return "Please select at least one day"
            case .invalidRetryAttempts:
                return "Retry attempts must be between 1 and 10"
            case .invalidRetryDelay:
                return "Retry delay must be between 1 and 60 minutes"
            case .timeConflict(let setups):
                let names = setups.map { $0.name ?? "Unknown" }.joined(separator: ", ")
                return "This time conflicts with existing setup(s): \(names)"
            case .custom(let message):
                return message
            }
        }
    }
    
    // MARK: - Call Setup Validation
    
    func validateCallSetup(_ setup: CallSetup) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Name validation
        if (setup.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyName)
        }
        
        // Phone number validation
        if !isValidUKPhoneNumber(setup.phoneNumber ?? "").isValid {
            errors.append(.invalidPhoneNumber)
        }
        
        // Time validation
        if !isValidTime(hour: Int(setup.hour), minute: Int(setup.minute)) {
            errors.append(.invalidTime)
        }
        
        // Weekdays validation
        if setup.weekdaysArray.isEmpty {
            errors.append(.noWeekdaysSelected)
        }
        
        // Retry attempts validation
        if setup.retryAttempts < 1 || setup.retryAttempts > 10 {
            errors.append(.invalidRetryAttempts)
        }
        
        // Retry delay validation
        if setup.retryDelay < 1 || setup.retryDelay > 60 {
            errors.append(.invalidRetryDelay)
        }
        
        // Time conflict validation
        let conflicts = checkTimeConflicts(for: setup)
        if !conflicts.isEmpty {
            errors.append(.timeConflict(conflicts))
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Individual Field Validation
    
    func validateName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return ValidationResult(isValid: false, errors: [.emptyName])
        }
        
        if trimmedName.count > 100 {
            return ValidationResult(isValid: false, errors: [.custom("Name must be less than 100 characters")])
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
    
    func validatePhoneNumber(_ phoneNumber: String) -> ValidationResult {
        if !isValidUKPhoneNumber(phoneNumber).isValid {
            return ValidationResult(isValid: false, errors: [.invalidPhoneNumber])
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
    
    func validateTime(hour: Int, minute: Int) -> ValidationResult {
        if !isValidTime(hour: hour, minute: minute) {
            return ValidationResult(isValid: false, errors: [.invalidTime])
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
    
    func validateWeekdays(_ weekdays: [Int]) -> ValidationResult {
        if weekdays.isEmpty {
            return ValidationResult(isValid: false, errors: [.noWeekdaysSelected])
        }
        
        // Check if all weekdays are valid (0-6)
        let invalidDays = weekdays.filter { $0 < 0 || $0 > 6 }
        if !invalidDays.isEmpty {
            return ValidationResult(isValid: false, errors: [.custom("Invalid weekday selection")])
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
    
    func validateRetryAttempts(_ attempts: Int) -> ValidationResult {
        if attempts < 1 || attempts > 10 {
            return ValidationResult(isValid: false, errors: [.invalidRetryAttempts])
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
    
    func validateRetryDelay(_ delay: Int) -> ValidationResult {
        if delay < 1 || delay > 60 {
            return ValidationResult(isValid: false, errors: [.invalidRetryDelay])
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
    
    // MARK: - Helper Methods
    
    private func isValidUKPhoneNumber(_ phoneNumber: String) -> ValidationResult {
        // UK phone number patterns
        let patterns = [
            "^\\+44\\s?[1-9]\\d{8,9}$",           // +44 followed by area code and number
            "^\\+44\\s?\\d{2}\\s?\\d{4}\\s?\\d{4}$", // +44 XX XXXX XXXX format
            "^\\+44\\s?\\d{3}\\s?\\d{3}\\s?\\d{4}$", // +44 XXX XXX XXXX format
            "^\\+44\\s?\\d{4}\\s?\\d{6}$"           // +44 XXXX XXXXXX format
        ]
        
        for pattern in patterns {
            let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
            if predicate.evaluate(with: phoneNumber) {
                return ValidationResult(isValid: true, errors: [])
            }
        }
        
        return ValidationResult(isValid: false, errors: [.invalidPhoneNumber])
    }
    
    private func isValidTime(hour: Int, minute: Int) -> Bool {
        return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59
    }
    
    // MARK: - Conflict Detection
    
    func checkTimeConflicts(for setup: CallSetup) -> [CallSetup] {
        let allSetups = dataManager.fetchAllCallSetups()
        
        return allSetups.filter { existingSetup in
            // Skip self when editing
            guard existingSetup.id != setup.id else { return false }
            
            // Check if times match
            guard existingSetup.hour == setup.hour && existingSetup.minute == setup.minute else { return false }
            
            // Check if any weekdays overlap
            let existingDays = Set(existingSetup.weekdaysArray)
            let newDays = Set(setup.weekdaysArray)
            
            return !existingDays.isDisjoint(with: newDays)
        }
    }
    
    func hasTimeConflict(hour: Int, minute: Int, weekdays: [Int], excludingSetupID: UUID? = nil) -> Bool {
        let allSetups = dataManager.fetchAllCallSetups()
        
        for setup in allSetups {
            // Skip excluded setup
            if let excludingID = excludingSetupID, let setupID = setup.id, setupID == excludingID {
                continue
            }
            
            // Check time match
            if Int(setup.hour) == hour && Int(setup.minute) == minute {
                // Check weekday overlap
                let existingDays = Set(setup.weekdaysArray)
                let newDays = Set(weekdays)
                
                if !existingDays.isDisjoint(with: newDays) {
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - Phone Number Formatting
    
    func formatUKPhoneNumber(_ input: String) -> String {
        // Remove all non-digit characters
        let digits = input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // Handle different input formats
        if digits.hasPrefix("44") && digits.count >= 12 {
            // Already has country code
            let areaCode = String(digits.dropFirst(2).prefix(2))
            let remaining = String(digits.dropFirst(4))
            return formatNumberParts(countryCode: "44", areaCode: areaCode, number: remaining)
        } else if digits.hasPrefix("0") && digits.count >= 11 {
            // UK number starting with 0
            let areaCode = String(digits.dropFirst(1).prefix(2))
            let remaining = String(digits.dropFirst(3))
            return formatNumberParts(countryCode: "44", areaCode: areaCode, number: remaining)
        } else if digits.count >= 10 {
            // Assume UK number without leading 0
            let areaCode = String(digits.prefix(2))
            let remaining = String(digits.dropFirst(2))
            return formatNumberParts(countryCode: "44", areaCode: areaCode, number: remaining)
        }
        
        return input // Return original if can't format
    }
    
    private func formatNumberParts(countryCode: String, areaCode: String, number: String) -> String {
        let formattedNumber = formatMainNumber(number)
        return "+\(countryCode) \(areaCode) \(formattedNumber)"
    }
    
    private func formatMainNumber(_ number: String) -> String {
        if number.count == 8 {
            let firstPart = String(number.prefix(4))
            let secondPart = String(number.suffix(4))
            return "\(firstPart) \(secondPart)"
        } else if number.count == 7 {
            let firstPart = String(number.prefix(3))
            let secondPart = String(number.suffix(4))
            return "\(firstPart) \(secondPart)"
        }
        
        return number
    }
    
    // MARK: - Real-time Validation
    
    func validateFieldInRealTime(_ field: ValidationField, value: String, setup: CallSetup? = nil) -> ValidationResult {
        switch field {
        case .name:
            return validateName(value)
        case .phoneNumber:
            return validatePhoneNumber(value)
        case .retryAttempts:
            if let attempts = Int(value) {
                return validateRetryAttempts(attempts)
            }
            return ValidationResult(isValid: false, errors: [.invalidRetryAttempts])
        case .retryDelay:
            if let delay = Int(value) {
                return validateRetryDelay(delay)
            }
            return ValidationResult(isValid: false, errors: [.invalidRetryDelay])
        }
    }
    
    enum ValidationField {
        case name
        case phoneNumber
        case retryAttempts
        case retryDelay
    }
}

// MARK: - Extensions

extension ValidationService {
    
    // MARK: - Batch Validation
    
    func validateMultipleSetups(_ setups: [CallSetup]) -> [UUID: ValidationResult] {
        var results: [UUID: ValidationResult] = [:]
        
        for setup in setups {
            if let setupID = setup.id {
                results[setupID] = validateCallSetup(setup)
            }
        }
        
        return results
    }
    
    // MARK: - Validation Summary
    
    func getValidationSummary(for setups: [CallSetup]) -> ValidationSummary {
        let results = validateMultipleSetups(setups)
        let validCount = results.values.filter { $0.isValid }.count
        let invalidCount = results.count - validCount
        let totalErrors = results.values.flatMap { $0.errors }.count
        
        return ValidationSummary(
            totalSetups: setups.count,
            validSetups: validCount,
            invalidSetups: invalidCount,
            totalErrors: totalErrors
        )
    }
}

struct ValidationSummary {
    let totalSetups: Int
    let validSetups: Int
    let invalidSetups: Int
    let totalErrors: Int
    
    var isAllValid: Bool {
        return invalidSetups == 0
    }
    
    var validationRate: Double {
        guard totalSetups > 0 else { return 0.0 }
        return Double(validSetups) / Double(totalSetups) * 100.0
    }
}
