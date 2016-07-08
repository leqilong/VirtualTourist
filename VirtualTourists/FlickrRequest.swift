//
//  FlickrRequest.swift
//  VirtualTourists
//
//  Created by Leqi Long on 7/2/16.
//  Copyright © 2016 Student. All rights reserved.
//

import Foundation

struct URLComponents{
    let scheme: String
    let host: String
    let path: String
}

class FlickrRequest{
    let session: NSURLSession!
    let url: URLComponents
    
    init(url: URLComponents){
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.session = NSURLSession(configuration: config)
        self.url = url
    }
    
    //MARK: Flickr request
    
    func taskForFlickr(methodParamaters: [String:AnyObject], completionHandler: (result: NSData?, error: NSError?) -> Void){
        let request = NSURLRequest(URL: flickrURLFromParameters(methodParamaters))
        
        let task = session.dataTaskWithRequest(request){(data, response, error) in
            func displayError(error: String) {
                print(error)
            }
            
            guard (error == nil) else{
                displayError("There was an error with your request: \(error)")
                return 
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            completionHandler(result: data, error: error)

        }
        
        task.resume()
    }
    
    // MARK: Helper for Creating a URL from Parameters
    
    func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = FlickrClient.Flickr.APIScheme
        components.host = FlickrClient.Flickr.APIHost
        components.path = FlickrClient.Flickr.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }

    
}
