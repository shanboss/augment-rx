import CoreData

class DatabaseManager {
    static let shared = DatabaseManager()

    private let persistentContainer: NSPersistentContainer

    private init() {
        persistentContainer = NSPersistentContainer(name: "ScannedMedication") // Ensure this matches your `.xcdatamodeld` file
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
    }

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Fetch Items
    func fetchItems() -> [Item] {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)] // Sort by timestamp

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch items: \(error)")
            return []
        }
    }

    // MARK: - Add Item
    func addItem(name: String, qrCode: String, modelCid: String) {
        let newItem = Item(context: context)
        newItem.id = Int64(UUID().hashValue) // Use UUID hash for a unique ID
        newItem.name = name
        newItem.qrCode = qrCode
        newItem.modelCid = modelCid
        newItem.timestamp = Date()

        saveContext()
        print("Item added successfully: \(name)")
    }

    // MARK: - Save Context
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}
