//
//  FlickrClient.swift
//  VirtualTourist 0.0
//
//  Created by admin on 11/11/16.
//  Copyright © 2016 JPDaines. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class FlickrClient: NSObject {
    
    static let sharedInstance = FlickrClient()
    let delegate = UIApplication.shared.delegate as! AppDelegate
    let session = URLSession.shared


    
    var photoContext: NSManagedObjectContext {
        return delegate.stack.context
    }
    var pin:Pin!
    var imageURL: URL?
    var flickrData: Data?
    var pinPhoto: Photo!
    var randomPageValue: String?
    
    var methodParameters: [String: Any]!

    
    
    func searchByLatLon(completion: @escaping (_ success: Bool) -> Void) {
        
        
        makeMethodParameters{ (success) -> Void in
            if success {
                
                 getRandomPageNumber(methodParameters as [String : AnyObject]) { (success) -> Void in
                    
                            }
                        }
                    }
                }

    
    
    func makeMethodParameters(completion: (_ success: Bool) -> Void){
        
         methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude: pin.latitude, longitude: pin.longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback, Constants.FlickrParameterKeys.perPage: Constants.FlickrParameterValues.photosPerPage
            
        ]
        completion(true)

    }
    
    
    

    
    
    func bboxString(latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    // MARK: Flickr API
    
    func displayError(_ error: String) {
        print(error)
    }
    
    fileprivate func getRandomPageNumber(_ methodParameters: [String:AnyObject], completion: @escaping (_ success: Bool) -> Void) {

        sharedClient.sharedInstance.taskForGet(url: flickrURLFromParameters(methodParameters)){ (data) -> Void in
            
            if data != nil{
                
                sharedClient.sharedInstance.parseJSON(data!){ (parsedResult, error) -> Void in
                    
                    
                /* GUARD: Did Flickr return an error (stat != ok)? */
                guard let stat = parsedResult? [Constants.FlickrResponseKeys.Status] as? String , stat == Constants.FlickrResponseValues.OKStatus else {
                    self.displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                    return
                }
                
                /* GUARD: Is "photos" key in our result? */
                guard let photosDictionary = parsedResult?[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    self.displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                    return
                }
                
                /* GUARD: Is "pages" key in the photosDictionary? */
                guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                    self.displayError("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                    return
                }
                let pageLimit = min(totalPages, 190)
                let randomPage = arc4random_uniform(UInt32(pageLimit)) + 1
                self.displayImageFromFlickrBySearch(methodParameters: methodParameters, Int(randomPage))
                
                completion(true)
                }
        }
    }
}
        
    
    fileprivate func displayImageFromFlickrBySearch(methodParameters: [String:AnyObject], _ pageNumber: Int){
        
        var newMethodParams = methodParameters
        newMethodParams["page"] = "\(pageNumber)" as AnyObject?
        print(newMethodParams)
        
        
        
        sharedClient.sharedInstance.taskForGet(url: flickrURLFromParameters(newMethodParams)){ (data) -> Void in
            
            if data != nil{
                
                sharedClient.sharedInstance.parseJSON(data!){ (parsedResult, error) -> Void in
        
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult? [Constants.FlickrResponseKeys.Status] as? String , stat == Constants.FlickrResponseValues.OKStatus else {
                self.displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult?[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                self.displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                self.displayError("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                self.displayError("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
                
                DispatchQueue.main.async {
                    
                    self.pin.totalPages = totalPages
                    print("the total pages for this pin are \(self.pin.totalPages)")
                    
                    for photoDictionary in photosArray {
                        let imageURLString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String
                        let photo = Photo(photoURL: imageURLString!, pin: self.pin, context: self.photoContext)
                        

                        FlickrClient.sharedInstance.downloadImageForPhoto(photo: photo) { (success, errorString) in
                            if success {
                                print("photos successfully downloaded!!!")
                                do{
                                    try self.delegate.stack.saveContext()
                                    //completion(true)
                                }catch{
                                    print("There was an error while saving context")
                                }
                            }
                        }
                        
                    }
                }
            }
        }
    }
}
    

    func downloadImageForPhoto(photo: Photo, completionHandler: @escaping (_ success: Bool, _ errorString: String?) -> Void) {
        
        let photoUrl = URL(string: photo.imageURL!)
        
        sharedClient.sharedInstance.taskForGet(url: photoUrl!){ (data) -> Void in
            
            if data == nil{
                photo.filePath = "unavailable"
                self.displayError("Unable to download Photo")
            } else {
                    DispatchQueue.main.async {
                        let fileName = (NSString(string: photo.imageURL!)).lastPathComponent
                        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                        let pathArray = [path, fileName]
                        let fileURL = NSURL.fileURL(withPathComponents: pathArray)!
                        
                        FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil)
                        
                        photo.filePath = fileURL.path
                        completionHandler(true, nil)
                }
            }
        }
    }

    // MARK: Helper for Creating a URL from Parameters
    
    func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()

        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
