//
//  PhotoAlbumViewController.swift
//  VirtualTourists
//
//  Created by Leqi Long on 7/2/16.
//  Copyright © 2016 Student. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate{

    //MARK: Outlets
    @IBOutlet weak var photosCollection: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noPhotosFoundLabel: UILabel!
    
    //MARK: Properties
    var context: NSManagedObjectContext {
        return CoreDataStack.sharedInstance.context
    }
    
    let flickrClient = FlickrClient.sharedClient()
    var location: Location!
    
    //store indexPaths waiting to be deleted
    var selectedPhotosIndexes = [NSIndexPath]()
    //store indexPaths of newly downloaded photos when click on "New Collections" button
    var insertedIndexPaths = [NSIndexPath]()
    //store index Paths of photos deleted by from collectionView
    var deletedIndexPaths = [NSIndexPath]()
    var updatedIndexPaths = [NSIndexPath]()
    
    var isWaitingToFetch: Bool = false
    
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fr = NSFetchRequest(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fr.predicate = NSPredicate(format: "location == %@", self.location)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        
        placePinOnMap()
        
        fetchedResultsController.delegate = self        
        do {
            try fetchedResultsController.performFetch()
        } catch let e as NSError{
            print("Error while trying to perform fetch \n\(e)\n\(fetchedResultsController)")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    @IBAction func newCollectionOrDeleteImage(sender: AnyObject) {
        if newCollectionButton.titleLabel?.text == "Remove Selected Photos"{
            var selectedPhotosToDelete = [Photo]()
            for indexPath in selectedPhotosIndexes{
                if let photo = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo{
                    selectedPhotosToDelete.append(photo)
                }
            }
            
            for photo in selectedPhotosToDelete{
                context.deleteObject(photo)
            }
            selectedPhotosIndexes = [NSIndexPath]()
            newCollectionButton.setTitle("New Collection", forState: .Normal)
            do{
                try self.context.save()
            }catch{}
            
        }else if newCollectionButton.titleLabel?.text == "New Collection"{
            if let fetchedResults = fetchedResultsController.fetchedObjects{
                for result in fetchedResults{
                    let photo = result as! Photo
                    context.deleteObject(photo)
                }
                
                do{
                    try self.context.save()
                }catch{}
            }
            
            isWaitingToFetch = true
            
            getPictures(location)
        }
        
    }
    
    func getPictures(location: Location){
        flickrClient.getPhotosByLocation(Double(location.lat!), lon: Double(location.lon!)){(photosArray, error) in
            self.context.performBlock(){
                if let photosArray = photosArray{
                    if photosArray.count == 0 {
                        self.isWaitingToFetch = false
                        self.displayError("No Photos Found.")
                        return
                    } else {
                        for photo in photosArray{
                            /* GUARD: Does our photo have a key for 'url_m'? */
                            guard let imageUrlString = photo[FlickrClient.FlickrResponseKeys.MediumURL] as? String else {
                                self.displayError("Cannot find key '\(FlickrClient.FlickrResponseKeys.MediumURL)' in \(photo)")
                                return
                            }
                            let image = Photo(url: imageUrlString, context: self.context)
                            image.location = self.location
                        }
                    }
                    do{
                        try self.context.save()
                    }catch{}
                    
                }else{
                    print(error?.localizedDescription)
                }
            }
        }

    }
    
    
    func placePinOnMap(){
        var annotations = [MKPointAnnotation]()
        var annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        mapView.addAnnotation(annotation)
        annotations.append(annotation)
        mapView.showAnnotations(annotations, animated: true)
        
    }
    

    // MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let section = fetchedResultsController.sections?[section]{
            if section.numberOfObjects  == 0 && isWaitingToFetch == false{
                noPhotosFoundLabel.hidden = false
            }
            
            print("We have \(section.numberOfObjects) in 1 section")
            return section.numberOfObjects
        }else{
            return 1
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        let img = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        cell.backgroundColor =  UIColor(red: 0, green: 0.6549, blue: 0.9373, alpha: 0.7)
        cell.photoImageView.image = nil
        cell.photoImageView.backgroundColor = UIColor.clearColor()
        cell.layer.cornerRadius = 5
        cell.photoImageView.clipsToBounds = true 
        cell.activityIndicator.hidden = false
        
        if let imageData = img.imageData{
            cell.photoImageView.image = UIImage(data: imageData)
            cell.activityIndicator.stopAnimating()
        }else{
            cell.activityIndicator.startAnimating()
            dispatch_async(dispatch_get_main_queue()) {
            if let imageURL = NSURL(string: img.url!){
                if let imageData = NSData(contentsOfURL: imageURL),
                    let photo = UIImage(data: imageData){
                    dispatch_async(dispatch_get_main_queue()){
                        cell.photoImageView.image = photo
                        let photoData = UIImageJPEGRepresentation(photo, 1.0)
                        img.imageData = photoData
                        cell.activityIndicator.stopAnimating()
                    }
                }else{
                    print("Image does not exisit \(imageURL)")
                }
            }
            }

        }
        
        cell.layer.opacity = 1.0

        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        cell.layer.opacity = 0.2
        prepareToDeletePhotos(indexPath)
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        cell.layer.opacity = 1.0
        for index in selectedPhotosIndexes{
            if index == indexPath{
                let indexToDelete = selectedPhotosIndexes.indexOf(index)
                selectedPhotosIndexes.removeAtIndex(indexToDelete!)
                break
            }
        }
        
        if selectedPhotosIndexes.count == 0 {
            newCollectionButton.setTitle("New Collection", forState: .Normal)
        }
    }
    
    
    func configure(){
        photosCollection.delegate = self
        photosCollection.dataSource = self
        photosCollection.allowsMultipleSelection = true
        
        noPhotosFoundLabel.hidden = true
    }
    
    func prepareToDeletePhotos(indexPath: NSIndexPath){
        selectedPhotosIndexes.append(indexPath)
        if selectedPhotosIndexes.count != 0{
            newCollectionButton.setTitle("Remove Selected Photos", forState: .Normal)
        }
        
    }
    
    //MARK: Error
    
    func displayError(error: String) {
        print(error)
    }

}

extension PhotoAlbumViewController{
    
    //MARK: NSFetchedResultsControllerDelegate Methods
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        updatedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        insertedIndexPaths = [NSIndexPath]()
        noPhotosFoundLabel.hidden = true
        isWaitingToFetch = true
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type{
            
        case .Insert:
            print("Insert object : \(newIndexPath)")
            insertedIndexPaths.append(newIndexPath!)
            break
            
        case .Delete:
            print("Delete object: \(newIndexPath)")
            deletedIndexPaths.append(indexPath!)
            break
            
        case .Move:
            print("Move is not applicable to this application")
            break
            
        case .Update:
            print("Update object: \(newIndexPath)")
            updatedIndexPaths.append(indexPath!)
            break
            
        }
    }
    
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        photosCollection.performBatchUpdates({() -> Void in
            for index in self.insertedIndexPaths{
                self.photosCollection.insertItemsAtIndexPaths([index])
            }
            
            for index in self.updatedIndexPaths{
                self.photosCollection.reloadItemsAtIndexPaths([index])
            }
            
            for index in self.deletedIndexPaths{
                self.photosCollection.deleteItemsAtIndexPaths([index])
            }
            
        }, completion: nil)
    }
    
}

//MARK: CollectionView Flow Layout
extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let frameSize = collectionView.frame.size
        let space: CGFloat = 1.0
        let dimension: CGFloat = frameSize.width >= frameSize.height ? (frameSize.width - (3 * space)) / 4.0 : (frameSize.width - (2 * space)) / 3.0
        
        collectionViewFlowLayout.minimumInteritemSpacing = space
        collectionViewFlowLayout.minimumLineSpacing = space
        collectionViewFlowLayout.itemSize = CGSizeMake(dimension, dimension)
        
        return collectionViewFlowLayout.itemSize
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        collectionViewFlowLayout.invalidateLayout()
    }
}
