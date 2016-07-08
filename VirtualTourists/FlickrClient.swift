//
//  FlickrClient.swift
//  VirtualTourists
//
//  Created by Leqi Long on 7/2/16.
//  Copyright © 2016 Student. All rights reserved.
//

import Foundation

class FlickrClient: NSObject{
    let flickrRequest: FlickrRequest
    
    // MARK: Initializers
    override init(){
        let url = URLComponents(scheme: Flickr.APIScheme, host: Flickr.APIHost, path: Flickr.APIPath)
        flickrRequest = FlickrRequest(url: url)
    }
    
    func getPhotosByLocation(lat: Double?, lon: Double?, completionHandler: (photosArray: [[String:AnyObject]]?, error: NSError?)->Void){
        var methodParameters = [String:AnyObject]()
        
        if let lat = lat,
            let lon = lon{
            methodParameters = [
                FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
                FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey,
                FlickrParameterKeys.BoundingBox: bboxString(lat, lon: lon),
                FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch,
                FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL,
                FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
                FlickrParameterKeys.NoJSONCallback:FlickrParameterValues.DisableJSONCallback,
                FlickrParameterKeys.PerPage: FlickrParameterValues.ResultsPerPage
            ]
        }
        
        
        flickrRequest.taskForFlickr(methodParameters){(result, error) in
            if let result = result{
                let parsedResult = try! NSJSONSerialization.JSONObjectWithData(result, options: .AllowFragments) as! [String:AnyObject]
                
                guard let stat = parsedResult[FlickrClient.FlickrResponseKeys.Status] as? String where stat == FlickrClient.FlickrResponseValues.OKStatus else{
                    self.displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                    return
                }
                
                /* GUARD: Is "photos" key in our result? */
                guard let photosDictionary = parsedResult[FlickrClient.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    self.displayError("Cannot find keys '\(FlickrClient.FlickrResponseKeys.Photos)' in \(parsedResult)")
                    return
                }
                
                /* GUARD: Is "pages" key in the photosDictionary? */
                guard let totalPages = photosDictionary[FlickrClient.FlickrResponseKeys.Pages] as? Int else {
                    self.displayError("Cannot find key '\(FlickrClient.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                    return
                }
                
                //generate a random page number
                let pageLimit = min(totalPages, 40)
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                var newParamaters = methodParameters
                newParamaters[FlickrParameterKeys.Page] = randomPage
                
                self.flickrRequest.taskForFlickr(newParamaters){ (result, error) in
                    if let result = result{
                        let parsedResult = try! NSJSONSerialization.JSONObjectWithData(result, options: .AllowFragments) as! [String:AnyObject]
                        
                        guard let stat = parsedResult[FlickrClient.FlickrResponseKeys.Status] as? String where stat == FlickrClient.FlickrResponseValues.OKStatus else{
                            self.displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                            return
                        }
                        
                        /* GUARD: Is "photos" key in our result? */
                        guard let photosDictionary = parsedResult[FlickrClient.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                            self.displayError("Cannot find keys '\(FlickrClient.FlickrResponseKeys.Photos)' in \(parsedResult)")
                            return
                        }
                        
                        /* GUARD: Is the "photo" key in photosDictionary? */
                        guard let photosArray = photosDictionary[FlickrClient.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                            self.displayError("Cannot find key '\(FlickrClient.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                            return
                        }
                        
                        completionHandler(photosArray: photosArray, error: nil)

                    }
                }
                
                
                
            }else{
                completionHandler(photosArray: nil, error: error)
            }
        }
    }
    
    
    private func bboxString(lat: Double?, lon: Double?) -> String {
        // ensure bbox is bounded by minimum and maximums
        if let latitude = lat, let longitude = lon {
            let minimumLon = max(longitude - Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }
    
    // MARK: Singleton Instance
    
    private static var sharedInstance = FlickrClient()
    
    class func sharedClient() -> FlickrClient {
        return sharedInstance
    }
    
    //MARK: Error
    
    func displayError(error: String){
        print(error)
    }
    
}