//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Pranavi Adusumilli  on 10/12/16.
//  Copyright © 2016 MeaMobile. All rights reserved.
//

import Foundation
import CoreData
import UIKit

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

class Photo: NSManagedObject {

    var image: UIImage? {
        get {
            if let imageData = imageData {
                return UIImage(data: imageData as Data)
            } else {
                return nil
            }
        }
    }
    
    // MARK: Initializers
    
    convenience init(title: String, image: UIImage, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: entity, insertInto: context)
            self.title = title
            self.path = "not defined"
            self.height = 80
            self.width = 80
            self.imageData = UIImagePNGRepresentation(image)
        } else {
            fatalError("unable to find entity name!")
        }
    }
    
    convenience init(dictionary: [String:AnyObject], context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: entity, insertInto: context)
            self.title = dictionary[FlickrClient.JSONResponseKeys.title] as? String
            self.path = dictionary[FlickrClient.JSONResponseKeys.mediumURL] as? String
            self.height = Int((dictionary[FlickrClient.JSONResponseKeys.mediumHeight] as? String)!) as NSNumber?
            self.width = Int((dictionary[FlickrClient.JSONResponseKeys.mediumWidth] as? String)!) as NSNumber?

        } else {
            fatalError("unable to find entity name!")
        }
    }
    
    // MARK: Convenience "Initializers"
    
    static func photosFromArrayOfDictionaries(_ dictionaries: [[String:AnyObject]], context: NSManagedObjectContext) -> [Photo] {
        var photos = [Photo]()
        for photoDictionary in dictionaries {
            photos.append(Photo(dictionary: photoDictionary, context: context))
        }
        let sortedPhotos = photos.sorted(by: { $0.path! < $1.path! })
        return sortedPhotos
    }

}
