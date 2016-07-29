# VirtualTourist
VirtualTourist is an application that allows the user to drop pins on a map view and look at photos taken on that location. 

Data persistence is achieved using Core Data.


The images are downloaded using Flickr API. See [here](https://www.flickr.com/services/api/) for its full documentation. 

##Core Data Model
The core data contains two entities: 
- Photo: its attributes include imageData, id, url. The downloaded images are stored as Binary Data in core data.
- Location: its attributes are lattitude, longitude.

Location and Photo has one to many relationship.

##View Controller Scenes
###MapViewController
MapViewController is the initial view when the app first launches. By using the [MapKit framework](https://developer.apple.com/library/ios/documentation/MapKit/Reference/MapKit_Framework_Reference/), I was able to display a map view. Whenever user taps on the map, a pin is dropped on the location user's finger touches. As soon as this animation happens, a GET HTTP request is sent to start downloading the photos associated with this location. On the navigation bar, there's an Edit bar item. Once that button is pressed, an instruction on how to delete the pins show up as a UILabel. And when the user touches a pin while that label is shown, the pin is removed from map view. When the user is not editing the pins, selecting a pin would segue to PhotoAlbumViewController, which displays a collection view of photos downloaded from the request made earlier.

###PhotoAlbumViewController 
PhotoAlbumViewController displays a map view zoomed in on the pin. Below the map view is a collection view of photos downloaded. I created a NSFetchRequest fetching existing photos in core data filtered by the selected location passed in from MapViewController. At the buttom of the view is a NewCollection button, which when pressed, a HTTP call is sent to download more photos. While the photos are downloading, activity indicator in the cell starts animating showing download progression. 


##Credits
Leqi Long

##Contacts
longleqi89@gmail.com