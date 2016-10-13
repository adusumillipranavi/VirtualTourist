//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Pranavi Adusumilli  on 10/12/16.
//  Copyright © 2016 MeaMobile. All rights reserved.
//

import Foundation
import CoreData
 

extension Photo {


    @NSManaged var height: NSNumber?
    @NSManaged var imageData: Data?
    @NSManaged var path: String?
    @NSManaged var title: String?
    @NSManaged var width: NSNumber?
    @NSManaged var pin: Pin?

}
