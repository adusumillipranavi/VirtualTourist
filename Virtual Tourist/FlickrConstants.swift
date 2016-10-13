//
//  FlickrConstants.swift
//  Virtual Tourist
//
//  Created by Pranavi Adusumilli  on 10/12/16.
//  Copyright © 2016 MeaMobile. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    // MARK: Components
    
    struct Components {
        static let scheme = "https"
        static let host = "api.flickr.com"
        static let path = "/services/rest"
    }
    
    // MARK: BBox
    
    struct BBox {
        static let halfWidth = 1.0
        static let halfHeight = 1.0
        static let latRange = (-90.0, 90.0)
        static let lonRange = (-180.0, 180.0)
    }
    
    // MARK: Errors
    
    struct Errors {
        static let domain = "FlickrClient"
        static let noPhotos = "Photo search failed."
    }
    
    // MARK: ParameterKeys
    
    struct ParameterKeys {
        static let method = "method"
        static let apiKey = "api_key"
        static let galleryID = "gallery_id"
        static let extras = "extras"
        static let format = "format"
        static let noJSONCallback = "nojsoncallback"
        static let safeSearch = "safe_search"
        static let text = "text"
        static let boundingBox = "bbox"
        static let page = "page"
        static let perPage = "per_page"
        static let geoContext = "geo_context"
    }
    
    // MARK: ParameterValues
    
    // TODO: Make API key not basic string
    
    struct ParameterValues {
        static let searchMethod = "flickr.photos.search"
        static let apiKey = "eb5e7015e078a387f4041860087c52ab"
        static let responseFormat = "json"
        static let disableJSONCallback = "1" /* 1 means "yes" */
        static let mediumURL = "url_m"
        static let useSafeSearch = "1" /* 1 means "yes" */
        static let bBoxExample = "77.0,44.0,79.0,46.0"
        static let defaultPerPage = 250 /* in docs, default is 250 for geo searches */
        static let geoContextOutdoors = 2
    }
    
    // MARK: JSONResponseKeys
    
    struct JSONResponseKeys {
        static let status = "stat"
        static let photos = "photos"
        static let photo = "photo"
        static let title = "title"
        static let mediumURL = "url_m"
        static let mediumHeight = "height_m"
        static let mediumWidth = "width_m"
        static let pages = "pages"
        static let total = "total"
        static let message = "message"
    }
    
    // MARK: JSONResponseValues
    
    struct JSONResponseValues {
        static let okStatus = "ok"
    }
    
    // MARK: APIData
    
    static func getAPIData() -> APIData {
        return APIData(scheme: Components.scheme, host: Components.host, path: Components.path, domain: Errors.domain)
    }
}
