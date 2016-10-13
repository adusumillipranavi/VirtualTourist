//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Pranavi Adusumilli  on 10/12/16.
//  Copyright © 2016 MeaMobile. All rights reserved.
//

import Foundation
import CoreData


class Pin: NSManagedObject {

    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: entity, insertInto: context)
            self.latitude = latitude as NSNumber?
            self.longitude = longitude as NSNumber?
        } else {
            fatalError("unable to find entity name!")
        }
    }
    
    // MARK: Remove Photos
    
    func removePhotos(_ context: NSManagedObjectContext) {
        if let photos = photos {
            for photo in photos {
                context.delete(photo as! NSManagedObject)
            }
        }
    }
}
