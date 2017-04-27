//
//  SharedClient.swift
//  VirtualTourist 1.0.3
//
//  Created by admin on 12/8/16.
//  Copyright © 2016 JPDaines. All rights reserved.
//

import Foundation


class sharedClient: NSObject{
    
    
    static let sharedInstance = sharedClient()
    
    func taskForGet(url: URL, completionHandler: @escaping (_ data: Data?) -> Void) {
        
        let session = URLSession.shared
        let request = URLRequest(url: url)
                let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                    
                    // if an error occurs, print it and re-enable the UI
                    func displayError(_ error: String) {
                        print(error)
                    }
                    
                    /* GUARD: Was there an error? */
                    guard (error == nil) else {
                        displayError("There was an error with your request: \(String(describing: error))")
                        return
                    }
                    
                    /* GUARD: Did we get a successful 2XX response? */
                    guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else {
                        displayError("Your request returned a status code other than 2xx!")
                        return
                    }
                    let data = data
                    completionHandler(data)
                    
        })
        task.resume()
    }
    
    func parseJSON(_ data: Data, completionHandlerForConvertData: (_ parsedResult: AnyObject?, _ error: String?) -> Void) {
        var parsedResult: Any
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completionHandlerForConvertData(parsedResult as AnyObject?, nil)
        } catch {
            print(error)
            completionHandlerForConvertData(nil, "There was an issue parsing the JSON")
        }
    }
}
