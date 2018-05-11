import UIKit
import MapKit
import Alamofire
import AlamofireImage


class mapVC: UIViewController, UIGestureRecognizerDelegate{
    
    @IBOutlet weak var mapview: MKMapView!
    
    @IBOutlet weak var viewsss: UIView!
    
    @IBOutlet weak var pullUpViewHeight: NSLayoutConstraint!
    
    var locationManger = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    
    var screenSize = UIScreen.main.bounds
    
    var spinner: UIActivityIndicatorView?
    var progressLable: UILabel?
    
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView?
    
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapview.delegate = self
        locationManger.delegate = self
        
        configureLocationServices()
        addDoubleTap()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        viewsss.addSubview(collectionView!)
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapview.addGestureRecognizer(doubleTap)
    }
    
    
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        viewsss.addGestureRecognizer(swipe)
        
    }
    
    func animateViewUp() {
        pullUpViewHeight.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    @objc func animateViewDown() {
        cancelAllSessions()
        pullUpViewHeight.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
        
    }
    
    func addSpiner() {
        spinner = UIActivityIndicatorView()
        spinner?.center	= CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLbl() {
        progressLable = UILabel()
        progressLable?.frame = CGRect(x: (screenSize.width / 2) - 120, y: 175, width: 240, height: 40)
        progressLable?.font = UIFont(name: "Avenir Next", size: 18)
        progressLable?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLable?.textAlignment = .center
        collectionView?.addSubview(progressLable!)
        
    }
    
    func removeProgressLbl() {
        if progressLable != nil {
            progressLable?.removeFromSuperview()
        }
    }
    
    @IBAction func centerMapBtn(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
}


extension mapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = UIColor.orange
        pinAnnotation.animatesDrop = true
        
        return pinAnnotation
    }
    func centerMapOnUserLocation() {
        guard let coordinate = locationManger.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapview.setRegion(coordinateRegion, animated: true)
        
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        removePin()
        removeSpinner()
        removeProgressLbl()
        cancelAllSessions()
        
        imageUrlArray = []
        imageArray = []
        collectionView?.reloadData()
        
        
        animateViewUp()
        addSwipe()
        addSpiner()
        addProgressLbl()
        
       
        let touchPoint = sender.location(in: mapview)
        let touchCoordinte = mapview.convert(touchPoint, toCoordinateFrom: mapview)
        
        let annotation = DroppablePin(coordinate: touchCoordinte, identifier: "droppablePin")
        mapview.addAnnotation(annotation)
        
        print(flickrUrl(forApiKey: apiKay, withAnnotation: annotation, andNumberOfPhotos: 40))
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinte, regionRadius * 2, regionRadius * 2)
        mapview.setRegion(coordinateRegion, animated: true)
        
        retrieveUrls(forAnnotation: annotation) { (finished) in
            if finished {
                self.retrieveImage(handler: { (finished) in
                    if finished {
                        self.removeSpinner()
                        self.removeProgressLbl()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
        
    }
    
    func removePin() {
        for annotation in mapview.annotations {
            mapview.removeAnnotation(annotation)
            
        }
    }
    
    func retrieveUrls(forAnnotation annotation: DroppablePin, handler: @escaping (_ status: Bool) -> ()){
        Alamofire.request(flickrUrl(forApiKey: apiKay, withAnnotation: annotation, andNumberOfPhotos: 40)).responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String,AnyObject> else { return }
            let photoDict = json["photos"] as! Dictionary<String, AnyObject>
            let photosDictArray = photoDict["photo"] as! [Dictionary<String, AnyObject>]
            for photo in photosDictArray {
                let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_q_d.jpg"
                self.imageUrlArray.append(postUrl)
            }
            handler(true)
        }
    }
    
    
    func retrieveImage(handler: @escaping (_ status: Bool) -> ()) {
        for url in imageUrlArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                guard let image = response.result.value else { return }
                self.imageArray.append(image)
                self.progressLable?.text = "\(self.imageArray.count)/40 Image Downloaded"
                
                if self.imageArray.count == self.imageUrlArray.count {
                    handler(true)
                }
                
            })
        }
        
    }
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDateTask, uploadData, downloadData) in
            sessionDateTask.forEach({ $0.cancel() })
            downloadData.forEach({ $0.cancel() })
            
            
        }
    }
}

extension mapVC: CLLocationManagerDelegate {
    func configureLocationServices() {
        
        if authorizationStatus == .notDetermined{
            locationManger.requestAlwaysAuthorization()
        }else {
            return
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}


extension mapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        cell.addSubview(imageView)
        return cell
    }
    
    
}

