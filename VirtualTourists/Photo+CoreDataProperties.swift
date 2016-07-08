//
//  Photo+CoreDataProperties.swift
//  VirtualTourists
//
//  Created by Leqi Long on 7/7/16.
//  Copyright © 2016 Student. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var id: String?
    @NSManaged var imageData: NSData?
    @NSManaged var path: String?
    @NSManaged var url: String?
    @NSManaged var location: Location?

}
