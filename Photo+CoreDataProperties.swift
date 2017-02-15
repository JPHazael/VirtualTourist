//
//  Photo+CoreDataProperties.swift
//  VirtualTourist 1.0.3
//
//  Created by admin on 12/3/16.
//  Copyright © 2016 JPDaines. All rights reserved.
//

import Foundation
import CoreData
 

extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }
    
    //@NSManaged var imageData: Data?
    @NSManaged public var imageURL: String?
    @NSManaged public var filePath: String?
    @NSManaged public var pin: Pin?

}
