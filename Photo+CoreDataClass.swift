//
//  Photo+CoreDataClass.swift
//  VirtualTourist 1.0.3
//
//  Created by admin on 12/3/16.
//  Copyright © 2016 JPDaines. All rights reserved.
//

import Foundation
import CoreData
import UIKit


public class Photo: NSManagedObject {
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
    
    convenience init(photoURL: String, pin: Pin, context: NSManagedObjectContext) {
        
        //Core Data
        let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context)!
        self.init(entity: entity, insertInto: context)
        
        self.imageURL = photoURL
        self.pin = pin
    }
    
    var image: UIImage? {
        if filePath != nil {
            let fileURL = getFileURL()
            return UIImage(contentsOfFile: fileURL.path!)
        }
        return nil
    }
    
    
    
    
    func getFileURL() -> NSURL {
        let fileName = (filePath! as NSString).lastPathComponent
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let pathArray:[String] = [dirPath, fileName]
        let fileURL = NSURL.fileURL(withPathComponents: pathArray)
        return fileURL! as NSURL
    }
    
    
    override public func prepareForDeletion() {
        if (filePath == nil) {
            return
        }
        let fileURL = getFileURL()
        if FileManager.default.fileExists(atPath: fileURL.path!) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path!)
            } catch{
                print("There was an error deleting the image from core data")
            }
        }
    }
}
