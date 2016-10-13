//
//  PinAnnotation.swift
//  Virtual Tourist
//
//  Created by Pranavi Adusumilli  on 10/11/16.
//  Copyright © 2016 MeaMobile. All rights reserved.
//

import MapKit
import CoreData

// MARK: - PinAnnotation: NSObject, MKAnnotationView

class PinAnnotation: NSObject, MKAnnotation {
    
    // MARK: Properties
    
    let title: String?
    let subtitle: String?
    var coordinate: CLLocationCoordinate2D
    
    // MARK: Initializers
    
    init(objectID: NSManagedObjectID, title: String?, subtitle: String?, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        super.init()
    }
}
