//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Pranavi Adusumilli  on 10/12/16.
//  Copyright © 2016 MeaMobile. All rights reserved.
//

import Foundation
import CoreData

class FlickrClient {
    
    // MARK: Properties
    
    let apiSession: APISession
    
    // MARK: Initializer
    
    fileprivate init() {
        apiSession = APISession(apiData: FlickrClient.getAPIData())
    }
    
    // MARK: Singleton Instance
    
    fileprivate static var sharedInstance = FlickrClient()
    
    class func sharedClient() -> FlickrClient {
        return sharedInstance
    }
    
    // MARK: Generate Bounding Box String
    
    fileprivate func bboxString(_ latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - BBox.halfWidth, BBox.lonRange.0)
        let minimumLat = max(latitude - BBox.halfHeight, BBox.latRange.0)
        let maximumLon = min(longitude + BBox.halfWidth, BBox.lonRange.1)
        let maximumLat = min(latitude + BBox.halfHeight, BBox.latRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    // MARK: Make Request
    
    fileprivate func makeRequestForFlickr(url: URL, method: HTTPMethod, body: [String:AnyObject]? = nil, responseHandler: @escaping (_ jsonAsDictionary: [String:AnyObject]?, _ error: NSError?) -> Void) {
        
        apiSession.makeRequestAtURL(url, method: method, headers: nil, body: nil) { (data, error) in
            if let data = data {
                // turn json response into dictionary
                let jsonAsDictionary = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                // check for api error
                if let stat = jsonAsDictionary[JSONResponseKeys.status] as? String, let message = jsonAsDictionary[JSONResponseKeys.message] as? String , stat != JSONResponseValues.okStatus {
                    responseHandler(nil, self.apiSession.errorWithStatus(0, description: message))
                } else {
                    responseHandler(jsonAsDictionary, nil)
                }
            } else {
                responseHandler(nil, error)
            }
        }
    }
    
    // MARK: GET Total Pages for Search
    
    func pagesForSearch(_ searchURL: URL, completionHandler: @escaping (_ pages: Int, _ error: NSError?) -> Void) {
        makeRequestForFlickr(url: searchURL, method: .GET) { (jsonAsDictionary, error) in
            // check for failure
            guard error == nil else {
                completionHandler(0, error)
                return
            }
            // otherwise get total page number
            if let jsonAsDictionary = jsonAsDictionary,
                let photosDictionary = jsonAsDictionary[JSONResponseKeys.photos] as? [String:AnyObject], let totalPages = photosDictionary[JSONResponseKeys.pages] as? Int {
                completionHandler(totalPages, nil)
                return
            }
        }
    }
    
    // MARK: GET Photos At Location
    
    func photosAtPin(_ pin: Pin, context: NSManagedObjectContext, completionHandler: @escaping (_ photos: [Photo]?, _ error: NSError?) -> Void) {
        
        // parameters for search
        var parameters: [String:AnyObject] = [
            ParameterKeys.method: ParameterValues.searchMethod as AnyObject,
            ParameterKeys.apiKey: ParameterValues.apiKey as AnyObject,
            ParameterKeys.boundingBox: bboxString(Double(pin.latitude!), longitude: Double(pin.longitude!)) as AnyObject,
            ParameterKeys.format: ParameterValues.responseFormat as AnyObject,
            ParameterKeys.noJSONCallback: ParameterValues.disableJSONCallback as AnyObject,
            ParameterKeys.extras: ParameterValues.mediumURL as AnyObject,
            ParameterKeys.perPage: ParameterValues.defaultPerPage as AnyObject,
            ParameterKeys.safeSearch: ParameterValues.useSafeSearch as AnyObject
        ]
        
        // construct search URL
        let photoSearchURL = apiSession.urlForMethod(nil, parameters: parameters)
        
        // use search URL to determine total number of pages available
        pagesForSearch(photoSearchURL) { (pages, error) in
            
            // check for failure
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            
            // add random page number to search
            parameters[ParameterKeys.page] = Int(arc4random_uniform(UInt32(pages)) + 1) as AnyObject?
            let photoSearchURLWithPage = self.apiSession.urlForMethod(nil, parameters: parameters)
            
            // perform "random search" for photos
            self.makeRequestForFlickr(url: photoSearchURLWithPage, method: .GET) { (jsonAsDictionary, error) in
                
                // check for failure
                guard error == nil else {
                    completionHandler(nil, error)
                    return
                }
                
                // get photos!
                if let jsonAsDictionary = jsonAsDictionary,
                    let photosDictionary = jsonAsDictionary[JSONResponseKeys.photos] as? [String:AnyObject], let photoArrayOfDictionaries = photosDictionary[JSONResponseKeys.photo] as? [[String:AnyObject]] {
                    let albumSize = AppConstants.Defaults.albumSize
                    if photoArrayOfDictionaries.count >= albumSize {
                        let startIndex = Int(arc4random_uniform(UInt32(photoArrayOfDictionaries.count - albumSize)))
                        let sliceOfArrayOfDictionaries = Array(photoArrayOfDictionaries[startIndex..<startIndex + albumSize])
                        completionHandler(Photo.photosFromArrayOfDictionaries(sliceOfArrayOfDictionaries, context: context), nil)
                    } else {
                        completionHandler(Photo.photosFromArrayOfDictionaries(photoArrayOfDictionaries, context: context), nil)
                    }
                    return
                }
                
                // photos not founds
                completionHandler(nil, self.apiSession.errorWithStatus(0, description: Errors.noPhotos))
            }
        }
    }
    
    // MARK: GET Single Photo
    
    func imageDataForPhoto(_ photo: Photo, completionHandler: @escaping (_ imageData: Data?, _ error: NSError?) -> Void) {
        
        let url = URL(string: photo.path!)!
        
        apiSession.makeRequestAtURL(url, method: .GET) { (data, error) in
            // check for failure
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            
            completionHandler(data, nil)
        }
    }
}
