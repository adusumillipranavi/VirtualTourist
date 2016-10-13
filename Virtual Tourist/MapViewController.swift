//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Pranavi Adusumilli  on 10/11/16.
//  Copyright © 2016 MeaMobile. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    var stack: CoreDataStack!
    var editLabel: UILabel!

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // set gesture recognizer
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressDetected(_:)))
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        
        // position map around last known region
        loadMostRecentMapRegion()
        
        // get core data stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack
        
        // set edit button
        navigationItem.rightBarButtonItem = editButtonItem
        
        // create edit label for slide-out
       
        editLabel = UILabel(frame: editLabelFrameForSize(view.frame.size))
        editLabel.backgroundColor = UIColor.white
        editLabel.textColor = UIColor.red
        editLabel.textAlignment = NSTextAlignment.center
        editLabel.text = "Tap Pins to Delete"
        editLabel.font = UIFont.boldSystemFont(ofSize: 16)
        self.view.addSubview(editLabel)
        
        // load annotations
        loadAnnotations()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { context -> Void in
            self.editLabel.frame = self.editLabelFrameForSize(size)
            self.mapView.frame = self.mapFrameForSize(size)
            }, completion: nil)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        let yOffset: CGFloat = 70 * (editing ? -1 : 1)
        
        if (animated) {
            UIView.animate(withDuration: 0.15, animations: {
                self.mapView.frame = self.mapView.frame.offsetBy(dx: 0, dy: yOffset)
                self.editLabel.frame = self.editLabel.frame.offsetBy(dx: 0, dy: yOffset)
            })
        } else {
            mapView.frame = mapView.frame.offsetBy(dx: 0, dy: yOffset)
            editLabel.frame = editLabel.frame.offsetBy(dx: 0, dy: yOffset)
        }
    }
    func editLabelFrameForSize(_ size: CGSize) -> CGRect {
        let editingShift: CGFloat = 70 * (isEditing ? -1 : 0)
        let labelRect = CGRect(x: 0, y: size.height + editingShift, width: size.width, height: 70)
        return labelRect
    }
    
    func mapFrameForSize(_ size: CGSize) -> CGRect {
        let editingShift: CGFloat = 70 * (isEditing ? -1 : 0)
        let labelRect = CGRect(x: 0, y: editingShift, width: size.width, height: size.height)
        return labelRect
    }
    
    func longPressDetected(_ longPress: UIGestureRecognizer!) {
        
        if longPress.state == .began && !isEditing {
            // get touch coordinate
            let touchPoint = longPress.location(in: self.mapView)
            let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            addPin(touchMapCoordinate)
        }
        
    }
    
    func addPin(_ location: CLLocationCoordinate2D) {
        let pin = Pin(latitude: location.latitude, longitude: location.longitude, context: stack.mainContext)
        let pinAnnotation = PinAnnotation(objectID: pin.objectID, title: nil, subtitle: nil, coordinate: location)
        mapView.addAnnotation(pinAnnotation)
    }
    
    func loadMostRecentMapRegion() {
        let defaults = UserDefaults.standard
        if let mapLat = defaults.object(forKey: AppConstants.Defaults.mapLatitude) as? CLLocationDegrees,
            let mapLon = defaults.object(forKey: AppConstants.Defaults.mapLongitude) as? CLLocationDegrees,
            let mapLatDelta = defaults.object(forKey: AppConstants.Defaults.mapLatitudeDelta) as? CLLocationDegrees,
            let mapLonDelta = defaults.object(forKey: AppConstants.Defaults.mapLongitudeDelta) as? CLLocationDegrees {
            mapView.region.center = CLLocationCoordinate2D(latitude: mapLat, longitude: mapLon)
            mapView.region.span = MKCoordinateSpanMake(mapLatDelta, mapLonDelta)
        }
    }
    
    func saveMostRecentMapRegion() {
        let defaults = UserDefaults.standard
        defaults.set(mapView.region.center.latitude, forKey: AppConstants.Defaults.mapLatitude)
        defaults.set(mapView.region.center.longitude, forKey: AppConstants.Defaults.mapLongitude)
        defaults.set(mapView.region.span.latitudeDelta, forKey: AppConstants.Defaults.mapLatitudeDelta)
        defaults.set(mapView.region.span.longitudeDelta, forKey: AppConstants.Defaults.mapLongitudeDelta)
    }
    
    // MARK: Add Annotations
    
    func loadAnnotations() {
        
        // create fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        do {
            print(stack)
            print(stack.mainContext)
            if let pins = try? stack.mainContext.fetch(fetchRequest) as! [Pin] {
                var pinAnnotations = [PinAnnotation]()
                // create annotations for pins
                for pin in pins {
                    let latitude = CLLocationDegrees(pin.latitude!)
                    let longitude = CLLocationDegrees(pin.longitude!)
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    pinAnnotations.append(PinAnnotation(objectID: pin.objectID, title: nil, subtitle: nil, coordinate: coordinate))
                }
                // add annotations to the map
                mapView.addAnnotations(pinAnnotations)
            }
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMostRecentMapRegion()
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        
        for annotationView in views {
            
            // don't pin drop if annotation is user location
            if annotationView.isKind(of: MKUserLocation.self) {
                continue
            }
            
            // check if current annotation is inside visible map rect, else go to next one
            let point = MKMapPointForCoordinate(annotationView.annotation!.coordinate)
            if !MKMapRectContainsPoint(self.mapView.visibleMapRect, point) {
                continue
            }
            
            let destinedFrame = annotationView.frame
            
            // move annotation out of view
            annotationView.frame = CGRect(x: annotationView.frame.origin.x, y: annotationView.frame.origin.y - self.view.frame.size.height, width: annotationView.frame.size.width, height: annotationView.frame.size.height)
            
            // animate drop
            UIView.animate(withDuration: 0.5, delay: 0.04 * Double(views.index(of: annotationView)!), options: .curveLinear, animations: {
                annotationView.frame = destinedFrame
                }, completion: nil)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // deselect the pin annotation
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        // get annotation and pin
        var pin: Pin!
        
        do {
            let pinAnnotation = view.annotation as! PinAnnotation
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
            let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [pinAnnotation.coordinate.latitude, pinAnnotation.coordinate.longitude])
            fetchRequest.predicate = predicate
            let pins = try stack.mainContext.fetch(fetchRequest) as? [Pin]
            pin = pins![0]
        } catch let error as NSError {
            print("failed to get pin by object id")
            print(error.localizedDescription)
            return
        }
        
        // if in edit mode, then delete pin
        guard !self.isEditing else {
            mapView.removeAnnotation(view.annotation!)
            stack.mainContext.delete(pin)
            stack.save()
            return
        }
        
        // otherwise, create/show photo album view controller
        let photoAlbumViewController = storyboard!.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        photoAlbumViewController.mapView = mapView
        photoAlbumViewController.pin = pin
        print(pin!.photos)
        if let photos = pin.photos?.allObjects as? [Photo] {
            let sortedPhotos = photos.sorted(by: { ($0 as AnyObject).path! < ($1 as AnyObject).path! })
            photoAlbumViewController.photos = sortedPhotos 
        }
        navigationController!.pushViewController(photoAlbumViewController, animated: true)
    }
}

