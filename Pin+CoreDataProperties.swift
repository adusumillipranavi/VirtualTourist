//
//  Pin+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Pranavi Adusumilli  on 10/12/16.
//  Copyright © 2016 MeaMobile. All rights reserved.
//

import Foundation
import CoreData


extension Pin {

    @NSManaged  var latitude: NSNumber?
    @NSManaged  var longitude: NSNumber?
    @NSManaged  var photos: NSSet?

}
