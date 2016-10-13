//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Pranavi Adusumilli  on 10/11/16.
//  Copyright © 2016 MeaMobile. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {

    
    var pin: Pin!
    var photos = [Photo]()
    var stack: CoreDataStack!
    var flickr = FlickrClient.sharedClient()
    var selectedIndexes = [IndexPath]()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoAlbumCollectionView: UICollectionView!
    
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var bottomBarButtonItem: UIBarButtonItem!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if photos.count == 0 {
            bottomBarButtonItem.isEnabled = false
            getNewCollectionOfPhotos()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // hide no images label
        noImagesLabel.isHidden = true
        
        // will handle collection view
      //  photoAlbumCollectionView.dataSource = self
       // photoAlbumCollectionView.delegate = self
        
        // get core data stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack
        
        // configure map and add dummy pin
        if let mapView = mapView {
            
            let mapCenter = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude!), longitude: CLLocationDegrees(pin.longitude!))
            let mapSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let mapRegion = MKCoordinateRegionMake(mapCenter, mapSpan)
            mapView.setRegion(mapRegion, animated: true)
            mapView.isUserInteractionEnabled = false
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapCenter
            mapView.addAnnotation(annotation)
        }

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // calculate layout for collection view
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        // update collection view layout
        let width = floor(photoAlbumCollectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        photoAlbumCollectionView.collectionViewLayout = layout

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        flickr.apiSession.cancelPendingTasks(FlickrClient.getAPIData())
    }
    
    @IBAction func bottomBarButtonPressed(_ sender: AnyObject) {
        if selectedIndexes.isEmpty {
            // remove photos from pin managed object
            pin.removePhotos(stack.mainContext)
            // remove photos from
            photos.removeAll(keepingCapacity: true)
            photoAlbumCollectionView.reloadData()
            // get new photos
            getNewCollectionOfPhotos()
        } else {
            deletePhotos()
        }
        
        updateBottomButton()
    }
    func getNewCollectionOfPhotos() {
        flickr.photosAtPin(pin, context: stack.mainContext) { (photos, error) in
            // check for failure
            guard error == nil else {
                print(error)
                return
            }
            // populate photos for pin
            if let photos = photos {
                for photo in photos {
                    photo.pin = self.pin
                }
                DispatchQueue.main.async(execute: {
                    self.photos = photos
                    self.stack.save()
                })
                DispatchQueue.main.async(execute: {
                    if self.photos.count == 0 {
                        self.noImagesLabel.text = "No Images Found"
                        self.noImagesLabel.isHidden = false
                    } else {
                        self.noImagesLabel.isHidden = true
                    }
                    self.photoAlbumCollectionView.reloadData()
                    self.bottomBarButtonItem.isEnabled = true
                })
            }
        }
    }
    
    // MARK: Delete Photos
    
    func deletePhotos() {
        var photosMarkedForDeletion = [Photo]()
        
        photoAlbumCollectionView.performBatchUpdates({
            
            let sortedIndexes = self.selectedIndexes.sorted {($0 as NSIndexPath).row > ($1 as NSIndexPath).row}
            
            for indexPath in sortedIndexes {
                let photoObject = self.photos[(indexPath as NSIndexPath).row]
                self.photos.remove(at: (indexPath as NSIndexPath).row)
                self.photoAlbumCollectionView.deleteItems(at: [indexPath])
                photosMarkedForDeletion.append(photoObject)
            }
            
            }
            , completion: { (completed) in
                
                if self.photos.count == 0 {
                    DispatchQueue.main.async(execute: {
                        self.noImagesLabel.text = "Album is Empty"
                        self.noImagesLabel.isHidden = false
                        self.stack.save()
                    })
                }
        })
        
        for photo in photosMarkedForDeletion {
            stack.mainContext.delete(photo)
        }
        
        selectedIndexes = [IndexPath]()
    }
    
    // MARK: Update Bottom Button
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomBarButtonItem.title = "Remove Selected Pictures"
            bottomBarButtonItem.tintColor = UIColor.red
        } else {
            bottomBarButtonItem.title = "New Collection"
            bottomBarButtonItem.tintColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
        }
    }
}

// MARK: - PhotoAlbumViewController: UICollectionViewDataSource

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    private func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        
        if let index = selectedIndexes.index(of: indexPath) {
            selectedIndexes.remove(at: index)
            cell.photoImageView.alpha = 1.0
        } else {
            selectedIndexes.append(indexPath)
            cell.photoImageView.alpha = 0.2
        }
        
        updateBottomButton()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        let photoObject = photos[(indexPath as NSIndexPath).row]
        
        if let photoImage = photoObject.image {
            cell.photoImageView.image = photoImage
        } else {
            cell.photoImageView.image = UIImage(named: "Placeholder")
            cell.activityIndicatorView.startAnimating()
            cell.activityIndicatorView.isHidden = false
            
            flickr.imageDataForPhoto(photoObject, completionHandler: { (imageData, error) in
                // check for failure
                guard error == nil else {
                    return
                }
                // otherwise, update image
                DispatchQueue.main.async(execute: {
                    cell.activityIndicatorView.stopAnimating()
                    cell.activityIndicatorView.isHidden = true
                    cell.photoImageView.image = UIImage(data: imageData!)
                })
            })
        }
        
        if (selectedIndexes.contains(indexPath)){
            cell.photoImageView.alpha = 0.2
        } else {
            cell.photoImageView.alpha = 1.0
        }
        
        return cell
    }
}

// MARK: - PhotoAlbumViewController: UICollectionViewDelegate

extension PhotoAlbumViewController: UICollectionViewDelegate {}

    


