//
//  Pin+CoreDataClass.swift
//  VirtualTourist 1.0.3
//
//  Created by admin on 12/3/16.
//  Copyright © 2016 JPDaines. All rights reserved.
//

import Foundation
import CoreData
import MapKit

public class Pin: NSManagedObject, MKAnnotation {
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context)!
        self.init(entity: entity, insertInto: context)
        
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public var coordinate: CLLocationCoordinate2D {
        get {
            let coordinate = CLLocationCoordinate2DMake(latitude as CLLocationDegrees, longitude as CLLocationDegrees)
            return coordinate
        }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
}
