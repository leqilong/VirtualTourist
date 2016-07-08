//
//  MapViewController.swift
//  VirtualTourists
//
//  Created by Leqi Long on 7/1/16.
//  Copyright © 2016 Student. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate{

    @IBOutlet weak var mapView: MKMapView!{
        didSet{
            mapView.mapType = .Standard
            mapView.delegate = self
        }
    }
    @IBOutlet weak var tapsToDeleteLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var context: NSManagedObjectContext {
        return CoreDataStack.sharedInstance.context
    }
    
    let flickrClient = FlickrClient.sharedClient()
    var locations = [Location]()
    var tempLat: Double?
    var tempLon: Double?
    var isEditingPins: Bool = false
    var mapRegionInfo = [String:Double]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        loadPins()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //Set the title back to "Virtual Tourist" from "Ok" when navigate back to the this view controller from the photo album view controller
        navigationItem.title = "Virtual Tourist"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func addPin(gestureRecognizer: UILongPressGestureRecognizer) {
        if isEditingPins == false {
            let coordinate = mapView.convertPoint(gestureRecognizer.locationInView(mapView), toCoordinateFromView: mapView)
            switch gestureRecognizer.state{
            case .Began:
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                mapView.addAnnotation(annotation)
            case .Ended:
                let pin = Location(lat: Double(coordinate.latitude), lon: Double(coordinate.longitude), context: context)
                
                context.performBlock(){
                    self.flickrClient.getPhotosByLocation(Double(pin.lat!), lon: Double(pin.lon!)) { (photosArray, error) in
                        if let photosArray = photosArray{
                            if photosArray.count == 0 {
                                self.displayError("No Photos Found. Search Again.")
                                return
                            } else {
                                for photo in photosArray{
                                    /*GUARD: Does our photo have a key for 'id'? */
                                    guard let id = photo[FlickrClient.FlickrResponseKeys.Id] as? String else {
                                        self.displayError("Cannot find key '\(FlickrClient.FlickrResponseKeys.Id)' in \(photo)")
                                        return
                                    }
                                    /* GUARD: Does our photo have a key for 'url_m'? */
                                    guard let imageUrlString = photo[FlickrClient.FlickrResponseKeys.MediumURL] as? String else {
                                        self.displayError("Cannot find key '\(FlickrClient.FlickrResponseKeys.MediumURL)' in \(photo)")
                                        return
                                    }
                                    let image = Photo(id: id, url: imageUrlString, context: self.context)
                                    image.location = pin
                                }
                            }
                        }else{
                            print(error?.localizedDescription)
                        }
                    }
                    
                    self.locations.append(pin)
                    do{
                        try self.context.save()
                    }catch{}


                }

            default: break
            }
        }
    }
    
    @IBAction func editButtonPressed(sender: AnyObject) {
        if tapsToDeleteLabel.hidden == false {
            tapsToDeleteLabel.hidden = true
            editButton.title = "Edit"
            isEditingPins = false
            mapView.frame.origin.y = 0
        }else{
            tapsToDeleteLabel.hidden = false
            isEditingPins = true
            editButton.title = "Done"
            mapView.frame.origin.y = tapsToDeleteLabel.frame.height * (-1)
        }
        
    }
    
    func configureUI(){
        //Set the title
        self.navigationItem.title = "Virtual Tourist"
        
        //Hide the delete label
        tapsToDeleteLabel.hidden = true
        
        //Set gesture recognizer to drop pins
        let longPressueGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addPin(_:)))
        mapView.addGestureRecognizer(longPressueGestureRecognizer)
        
        //Restore the map region (zoom level) to how user last left it
        if let userSetMapRegion = NSUserDefaults.standardUserDefaults().objectForKey("regionSetByUser") as? [String:Double]{
            let center = CLLocationCoordinate2DMake(userSetMapRegion["regionCenterLat"]!, userSetMapRegion["regionCenterLon"]!)
            let span = MKCoordinateSpanMake(userSetMapRegion["regionLatDelta"]!, userSetMapRegion["regionLonDelta"]!)
            mapView.region = MKCoordinateRegion(center: center, span: span)
            mapRegionInfo = userSetMapRegion
            
        }else{
            NSUserDefaults.standardUserDefaults().setObject(mapRegionInfo, forKey: "regionSetByUser")
            print("This is the first launch ever!")
        }

    }
    
    func loadPins(){
        
        let fr = NSFetchRequest(entityName: "Location")
        do{
            locations = try context.executeFetchRequest(fr) as! [Location]
        }catch let e as NSError{
            print("Error in fetchrequest: \(e)")
            locations = [Location]()
        }
        
        for location in locations{
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2DMake(Double(location.lat!), Double(location.lon!))
            mapView.addAnnotation(annotation)
        }
        
    }

    
    //MARK: MKMapViewDelegate methods
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapRegionInfo["regionCenterLat"] = mapView.region.center.latitude
        mapRegionInfo["regionCenterLon"] = mapView.region.center.longitude
        mapRegionInfo["regionLatDelta"] = mapView.region.span.latitudeDelta
        mapRegionInfo["regionLonDelta"] = mapView.region.span.longitudeDelta
        
        NSUserDefaults.standardUserDefaults().setValue(mapRegionInfo, forKey: "regionSetByUser")
    }
    
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        let coordinate = view.annotation?.coordinate
        tempLat = Double((coordinate?.latitude)!)
        tempLon = Double((coordinate?.longitude)!)
        
        if isEditingPins == false {
            dispatch_async(dispatch_get_main_queue()){
                self.mapView.deselectAnnotation(view.annotation, animated: true)
                self.performSegueWithIdentifier("showPhotos", sender: self)
            }
        }else{
            for location in locations{
                if location.lat == (coordinate?.latitude) && location.lon == (coordinate?.longitude){
                    context.deleteObject(location)
                    do{
                        try context.save()
                    }catch{}
                    if let annotation = view.annotation{
                        mapView.removeAnnotation(annotation)
                    }
                }
            }
        }
    }
    
    //MARK: prepare for segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPhotos"{
            if let photoAlbumVC = segue.destinationViewController as? PhotoAlbumViewController{
                navigationItem.title = "Ok"
                for location in locations{
                    if location.lat == tempLat && location.lon == tempLon{
                        photoAlbumVC.location = location
                        break
                    }
                }
                

            }
        }
    }
    
    //MARK: Error
    
    func displayError(error: String) {
        print(error)
    }

}
