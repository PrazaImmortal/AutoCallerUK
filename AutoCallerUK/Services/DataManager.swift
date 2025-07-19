//
//  DataManager.swift
//  HealthcareCallApp
//
//  Core Data stack and persistence manager
//

import Foundation
import CoreData
import UIKit

class DataManager {
    
    static let shared = DataManager()
    
    private init() {}
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AutoCallerUK")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Core Data Operations
    
    func save() {
        let context = viewContext
        
        context.performAndWait {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nsError = error as NSError
                    print("Core Data save error: \(nsError), \(nsError.userInfo)")
                }
            }
        }
    }
    
    func saveBackground(_ context: NSManagedObjectContext) {
        context.performAndWait {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nsError = error as NSError
                    print("Background save error: \(nsError), \(nsError.userInfo)")
                }
            }
        }
    }
    
    // MARK: - CallSetup Operations
    
    func createCallSetup() -> CallSetup {
        guard let entity = NSEntityDescription.entity(forEntityName: "CallSetup", in: viewContext) else {
            fatalError("❌ CallSetup entity not found in Core Data model.")
        }
        let setup = CallSetup(entity: entity, insertInto: viewContext)

        return setup
    }
    
    func fetchAllCallSetups() -> [CallSetup] {
        let request: NSFetchRequest<CallSetup> = NSFetchRequest(entityName: "CallSetup")
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CallSetup.name, ascending: true)]
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching call setups: \(error)")
            return []
        }
    }
    
    func fetchCallSetup(by id: UUID) -> CallSetup? {
        let request: NSFetchRequest<CallSetup> = NSFetchRequest(entityName: "CallSetup")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Error fetching call setup: \(error)")
            return nil
        }
    }
    
    func deleteCallSetup(_ setup: CallSetup) {
        viewContext.delete(setup)
        save()
    }
    
    func searchCallSetups(query: String) -> [CallSetup] {
        let request: NSFetchRequest<CallSetup> = NSFetchRequest(entityName: "CallSetup")
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR phoneNumber CONTAINS %@", query, query)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CallSetup.name, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error searching call setups: \(error)")
            return []
        }
    }
    
    func getScheduledCallSetups() -> [CallSetup] {
        let request: NSFetchRequest<CallSetup> = NSFetchRequest(entityName: "CallSetup")
        let now = Date()
        request.predicate = NSPredicate(format: "isActive == YES AND (snoozeUntil == nil OR snoozeUntil < %@)", now as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CallSetup.hour, ascending: true),
                                   NSSortDescriptor(keyPath: \CallSetup.minute, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching scheduled setups: \(error)")
            return []
        }
    }
    
    // MARK: - CallLogEntry Operations
    
    func createCallLogEntry() -> CallLogEntry {
        let entry = CallLogEntry(context: viewContext)
        return entry
    }
    
    func fetchAllCallLogs() -> [CallLogEntry] {
        let request: NSFetchRequest<CallLogEntry> = NSFetchRequest(entityName: "CallLogEntry")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CallLogEntry.timestamp, ascending: false)]
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching call logs: \(error)")
            return []
        }
    }
    
    func fetchCallLogs(by status: CallStatus) -> [CallLogEntry] {
        let request: NSFetchRequest<CallLogEntry> = NSFetchRequest(entityName: "CallLogEntry")
        request.predicate = NSPredicate(format: "status == %@", status.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CallLogEntry.timestamp, ascending: false)]
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching call logs by status: \(error)")
            return []
        }
    }
    
    func fetchCallLogs(for date: Date) -> [CallLogEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<CallLogEntry> = NSFetchRequest(entityName: "CallLogEntry")
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CallLogEntry.timestamp, ascending: false)]
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching call logs by date: \(error)")
            return []
        }
    }
    
    func fetchCallLogs(for setupID: UUID) -> [CallLogEntry] {
        let request: NSFetchRequest<CallLogEntry> = NSFetchRequest(entityName: "CallLogEntry")
        request.predicate = NSPredicate(format: "setupID == %@", setupID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CallLogEntry.timestamp, ascending: false)]
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching call logs by setup ID: \(error)")
            return []
        }
    }
    
    func deleteCallLogEntry(_ entry: CallLogEntry) {
        viewContext.delete(entry)
        save()
    }
    
    func clearAllCallLogs() {
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CallLogEntry")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try viewContext.execute(deleteRequest)
            save()
        } catch {
            print("Error clearing call logs: \(error)")
        }
    }
    
    // MARK: - Validation
    
    func validateCallSetup(_ setup: CallSetup) -> [String] {
        var errors: [String] = []
        
        // Name validation
        if ((setup.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) != nil) {
            errors.append("Name is required")
        }
        
        // Phone number validation (UK format)
        let phoneRegex = "^\\+44\\s?\\d{2,4}\\s?\\d{4}\\s?\\d{4}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        if !phonePredicate.evaluate(with: setup.phoneNumber) {
            errors.append("Please enter a valid UK phone number")
        }
        
        // Time validation
        if setup.hour < 0 || setup.hour > 23 {
            errors.append("Invalid hour")
        }
        if setup.minute < 0 || setup.minute > 59 {
            errors.append("Invalid minute")
        }
        
        // Weekdays validation
        if setup.weekdaysArray.isEmpty {
            errors.append("Please select at least one day")
        }
        
        // Retry validation
        if setup.retryAttempts < 1 || setup.retryAttempts > 10 {
            errors.append("Retry attempts must be between 1 and 10")
        }
        if setup.retryDelay < 1 || setup.retryDelay > 60 {
            errors.append("Retry delay must be between 1 and 60 minutes")
        }
        
        return errors
    }
    
    func checkForTimeConflicts(_ setup: CallSetup) -> [CallSetup] {
        let request: NSFetchRequest<CallSetup> = NSFetchRequest(entityName: "CallSetup")
        request.predicate = NSPredicate(format: "isActive == YES AND hour == %d AND minute == %d AND id != %@",
                                        setup.hour, setup.minute, setup.id! as CVarArg)
        
        do {
            let conflictingSetups = try viewContext.fetch(request)
            return conflictingSetups.filter { conflictSetup in
                let conflictDays = Set(conflictSetup.weekdaysArray)
                let setupDays = Set(setup.weekdaysArray)
                return !conflictDays.isDisjoint(with: setupDays)
            }
        } catch {
            print("Error checking for conflicts: \(error)")
            return []
        }
    }
    
    // MARK: - Demo Data
    
    func createDemoData() {
        // Only create demo data if no setups exist
        if fetchAllCallSetups().isEmpty {
            let demo1 = createCallSetup()
            demo1.name = "Dr. Smith"
            demo1.phoneNumber = "+44 20 7946 0958"
            demo1.hour = 9
            demo1.minute = 0
            demo1.weekdaysArray = [1, 3, 5] // Mon, Wed, Fri
            demo1.retryAttempts = 3
            demo1.retryDelay = 5
            
            let demo2 = createCallSetup()
            demo2.name = "City Medical Centre"
            demo2.phoneNumber = "+44 20 7946 0123"
            demo2.hour = 14
            demo2.minute = 30
            demo2.weekdaysArray = [2, 4] // Tue, Thu
            demo2.retryAttempts = 2
            demo2.retryDelay = 10
            
            save()
        }
    }
    
    // MARK: - Export
    
    func exportCallLogsToCSV() -> String {
        let logs = fetchAllCallLogs()
        var csvContent = "Provider,Phone Number,Date,Time,Status,Duration,Attempts\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        for log in logs {
            let line = "\(log.providerName),\(log.phoneNumber),\(dateFormatter.string(from: log.timestamp)),\(timeFormatter.string(from: log.timestamp)),\(log.callStatus.displayName),\(log.duration),\(log.attempts)\n"
            csvContent += line
        }
        
        return csvContent
    }
}
