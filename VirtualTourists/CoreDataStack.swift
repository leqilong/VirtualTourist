import CoreData
import Foundation

class CoreDataStack {
    
    // MARK:  - Properties
    lazy var model: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var coordinator: NSPersistentStoreCoordinator = {
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model)
        let url = self.documentsDirectory.URLByAppendingPathComponent("model.sqlite")
        do{
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
            
        }catch{
            print("unable to add store at \(url)")
        }
        return coordinator
    }()
    
    var documentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var context: NSManagedObjectContext = {
        let coordinator = self.coordinator
        var context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }()
    
    private init(){}
    
    //MARK: - Singleton
    
    static let sharedInstance = CoreDataStack()
    
}

// MARK:  - Save
extension CoreDataStack {
    
    func save() {
        context.performBlockAndWait(){
            
            if self.context.hasChanges{
                do{
                    try self.context.save()
                }catch{
                    fatalError("Error while saving main context: \(error)")
                }
            }
        }
        
        
        
    }
}






