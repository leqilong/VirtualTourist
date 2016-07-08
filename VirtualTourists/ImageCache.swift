//
//  ImageCache.swift
//  VirtualTourists
//
//  Created by Leqi Long on 7/7/16.
//  Copyright © 2016 Student. All rights reserved.
//

import Foundation
import UIKit

class ImageCache {
    
    let fm = NSFileManager.defaultManager()
    
    func getImageURLOnFile(photoID: String)->String?{
        if let path = fm.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first{
            let url = path.URLByAppendingPathComponent("\(photoID).jpg")
            return url.path
        }
        return nil
    }
    
    func saveImage(photoToSave: UIImage?, photoURLOnDisk: String?){
        if let photo = photoToSave,
            let url = photoURLOnDisk{
            let photoData = UIImageJPEGRepresentation(photo, 1.0)
            photoData?.writeToFile(url, atomically: true)
        }else{
            return
        }
    }
    
    func getImage(photoURLOnDisk: String?, urlInCache: String?) -> UIImage?{
        if let photoURLOnDisk = photoURLOnDisk{
            if let urlInCache = urlInCache{
                if let url = NSURL(string: urlInCache){
                    if let cachedData = NSURLCache.sharedURLCache().cachedResponseForRequest(NSURLRequest(URL: url)){
                        if let cachedImage = UIImage(data: cachedData.data){
                            return cachedImage
                        }
                    }
                }
            }
            
            if let photoData = NSData(contentsOfFile: photoURLOnDisk){
                if let photo = UIImage(data: photoData){
                    return photo
                }
            }
        }
        
        return nil
    }
    
    func removeImage(photoURL: String?, urlInCache: String?){
        if let photoURL = photoURL{
            if let urlInCache = urlInCache{
                if let url = NSURL(string: urlInCache){
                    NSURLCache.sharedURLCache().removeCachedResponseForRequest(NSURLRequest(URL: url))
                }
            }
            
            do{
                try fm.removeItemAtPath(photoURL)
            }catch{}
        }
    }
    private init(){}
    //MARK: Singleton
    static let sharedInstance = ImageCache()
}