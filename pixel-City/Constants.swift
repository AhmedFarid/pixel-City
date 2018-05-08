import Foundation


let apiKay = "da5ec0369ff3397544e3d5adf929661b"

func flickrUrl(forApiKey Key: String, withAnnotation annotation: DroppablePin, andNumberOfPhotos number: Int)-> String {
    
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKay)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
    
}
