//
//  CoreDataStack.swift
//  Virtual Tourist
//
//  Created by Pranavi Adusumilli  on 10/11/16.
//  Copyright © 2016 MeaMobile. All rights reserved.
//

import CoreData

// MARK: - CoreDataStack

struct CoreDataStack {
    
    // MARK: Properties
    
    fileprivate let model: NSManagedObjectModel
    fileprivate let coordinator: NSPersistentStoreCoordinator
    fileprivate let modelURL: URL
    fileprivate let dbURL: URL
    fileprivate let persistingContext: NSManagedObjectContext
    fileprivate let backgroundContext: NSManagedObjectContext
    let mainContext: NSManagedObjectContext
    
    // MARK: Initializers
    
    init?(modelName: String) {
        
        // get model url
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            print("Unable to find \(modelName)in the main bundle")
            return nil
        }
        self.modelURL = modelURL
        
        // create model from the URL
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("unable to create a model from \(modelURL)")
            return nil
        }
        self.model = model
        
        // create the store coordinator
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        // create a persisting context (creates/uses a private background queue)
        // saves flow from here to persistent store
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.persistentStoreCoordinator = coordinator
        
        // create a child context (uses main queue)
        // child of persistingContext, saves flow from mainContext to persistingContext
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext.parent = persistingContext
        
        // create a background context (creates/uses a private background queue)
        // child of mainContext, saves flow from backgroundContext to mainContext
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = mainContext
        
        // get URL for SQLite store
        guard let docUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("unable to reach the documents folder")
            return nil
        }
        self.dbURL = docUrl.appendingPathComponent("model.sqlite")
        
        // add a SQLite store located in the documents folder
        do {
            try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
        } catch let error as NSError {
            print("unable to add store at \(dbURL)")
            print(error.localizedDescription)
        }
    }
    
    // MARK: Utils
    
    func addStoreCoordinator(_ storeType: String, configuration: String?, storeURL: URL, options : [AnyHashable: Any]?) throws {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: nil)
    }
}


// MARK: - CoreDataStack (Removing Data)

extension CoreDataStack  {
    
    func dropAllData() throws {
        // empty all data tables in the store (doesn't delete the files)
        try coordinator.destroyPersistentStore(at: dbURL, ofType:NSSQLiteStoreType , options: nil)
        try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
    }
}

// MARK: - CoreDataStack (Background Processing)

extension CoreDataStack {
    
    typealias BackgroundBatchFunction = (_ backgroundContext: NSManagedObjectContext) -> ()
    
    func performBackgroundBatchOperation(_ batchFunction: @escaping BackgroundBatchFunction) {
        
        backgroundContext.perform() {
            // perform batch function using the background context
            batchFunction(self.backgroundContext)
            // save the backgroundContext which sends updates to the mainContext
            // at the next auto save, these updates will be pushed from the mainContext to the persistingContext and then to the store
            do {
                try self.backgroundContext.save()
            } catch let error as NSError {
                fatalError("Error while saving backgroundContext: \(error)")
            }
        }
    }
}

// MARK: - CoreDataStack (Saving)

extension CoreDataStack {
    
    // MARK: Standard Save
    
    func save() {
        // we save the mainContext which just pushes the updates to the
        // persistingContext (and never hits the disk!); therefore it completes very
        // fast which is why we can safely and synchronously use performBlockAndWait;
        // once the mainContext has saved (synchronously) we can then call save
        // on the persistingContext which will perform the writes to disk in
        // the background!
        mainContext.performAndWait() {
            if self.mainContext.hasChanges {
                do {
                    try self.mainContext.save()
                } catch let error as NSError {
                    fatalError("Error while saving main context: \(error)")
                }
                // save in the background! only the persistingContext touches the disk
                // and it does so in a non-blocking background queue :)!
                self.persistingContext.perform() {
                    do {
                        try self.persistingContext.save()
                    } catch let error as NSError {
                        fatalError("Error while saving persisting context: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: Auto Save Loop
    
    func startAutoSaveLoop(_ intervalInSeconds: Int) {
        
        if intervalInSeconds > 0 {
            // save...
            save()
            // and then save again (in a specified number of seconds)!
            let delayInNanoSeconds = UInt64(intervalInSeconds) * NSEC_PER_SEC
            let time = DispatchTime.now() + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                self.startAutoSaveLoop(intervalInSeconds)
            })
        }
    }
}
