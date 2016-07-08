//
//  Location.swift
//  VirtualTourists
//
//  Created by Leqi Long on 7/7/16.
//  Copyright © 2016 Student. All rights reserved.
//

import Foundation
import CoreData
import MapKit


class Location: NSManagedObject {

    convenience init(lat: Double, lon: Double, context: NSManagedObjectContext){
        if let ent = NSEntityDescription.entityForName("Location", inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.lat = lat
            self.lon = lon
        }else{
            fatalError("Unable to find entity name!")
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(Double(self.lat!), Double(self.lon!))
    }

}
