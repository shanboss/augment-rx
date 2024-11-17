//
//  CoreData.swift
//  Augmented Rx
//
//  Created by Manu Shanbhog  on 11/17/24.
//

import Foundation
import CoreData
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    // Initialize the Core Data stack
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel") // Replace "DataModel" with your Core Data model name

        if inMemory {
            // Use an in-memory store for preview/testing purposes
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    // A static preview instance for use in SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true) // In-memory store for preview
        let context = controller.container.viewContext

        // Add sample data for preview
        for i in 0..<5 {
            let newItem = Item(context: context)
            newItem.id = Int64(i)
            newItem.name = "Sample Item \(i)"
            newItem.qrCode = "SampleQRCode\(i)"
            newItem.modelCid = "SampleModelCid\(i)"
            newItem.timestamp = Date()
        }

        do {
            try context.save()
        } catch {
            fatalError("Failed to save preview context: \(error)")
        }

        return controller
    }()
}
class CoreDataManager {
    static let shared = CoreDataManager()

    let persistentContainer: NSPersistentContainer

    private init() {
        persistentContainer = NSPersistentContainer(name: "ScannedMedication") // Ensure this matches the .xcdatamodeld file name
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
    }

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                fatalError("Unresolved error \(error)")
            }
        }
    }
}
