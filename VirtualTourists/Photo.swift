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

//    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
//        super.init(entity: entity, insertIntoManagedObjectContext: context)
//    }
    
    convenience init(url: String, context: NSManagedObjectContext){
        if let ent = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.url = url
        }else{
            fatalError("Unable to find entity name!")
        }
    }
}
