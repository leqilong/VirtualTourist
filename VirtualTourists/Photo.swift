//
//  Photo.swift
//  VirtualTourists
//
//  Created by Leqi Long on 7/7/16.
//  Copyright © 2016 Student. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class Photo: NSManagedObject {

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(id: String, url: String, context: NSManagedObjectContext){
        if let ent = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.url = url
            self.id = id
        }else{
            fatalError("Unable to find entity name!")
        }
    }

    let imageCache = ImageCache.sharedInstance
    var photoURLToSaveOnFile: String? {
        return imageCache.getImageURLOnFile(id!)
    }
    
    var image: UIImage?{
        get{
            return imageCache.getImage(photoURLToSaveOnFile, urlInCache: url)
        }
        
        set{
            imageCache.saveImage(newValue, photoURLOnDisk: photoURLToSaveOnFile)
        }
    }
    
    override func prepareForDeletion() {
        imageCache.removeImage(photoURLToSaveOnFile, urlInCache: url)
    }

}
