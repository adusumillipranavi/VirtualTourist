//
//  APISession.swift
//  Virtual Tourist
//
//  Created by Pranavi Adusumilli  on 10/11/16.
//  Copyright © 2016 MeaMobile. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

// MARK: - APIData

struct APIData {
    var scheme = ""
    var host = ""
    var path = ""
    var domain = ""
}

// MARK: - APISession

class APISession {
    
    // MARK: Properties
    
    fileprivate var session: URLSession!
    fileprivate var apiData = APIData()
    
    // MARK: Initializers
    
    init(apiData: APIData) {
        configureNewSession(apiData)
    }
    
    func configureNewSession(_ apiData: APIData) {
        let configuration = URLSessionConfiguration.default
        configuration.httpMaximumConnectionsPerHost = 5
        self.session = URLSession(configuration: configuration)
        self.apiData.scheme = apiData.scheme
        self.apiData.host = apiData.host
        self.apiData.path = apiData.path
        self.apiData.domain = apiData.domain
    }
    
    // MARK: Requests
    
    func makeRequestAtURL(_ url: URL, method: HTTPMethod, headers: [String:String]? = nil, body: [String:AnyObject]? = nil, responseHandler: @escaping (Data?, NSError?) -> Void) {
        
        // create request and set HTTP method
        
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = method.rawValue
        let session = URLSession.shared
        
        // add headers
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // add body
        if let body = body {
            request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions())
        }
        
        // create/return task
        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            
            // was there an error?
            if let error = error {
                responseHandler(nil, error as NSError?)
                return
            }
            
            // did we get a successful 2XX response?
            if let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode < 200 && statusCode > 299 {
                let userInfo = [
                    NSLocalizedDescriptionKey: Errors.unsuccessfulResponse
                ]
                let error = NSError(domain: Errors.domain, code: statusCode, userInfo: userInfo)
                responseHandler(nil, error)
                return
            }
            
            responseHandler(data, nil)
        })
        task.resume()
    }
    
    // MARK: URLs
    
    func urlForMethod(_ method: String?, withPathExtension: String? = nil, parameters: [String:AnyObject]? = nil) -> URL {
        
        var components = URLComponents()
        components.scheme = apiData.scheme
        components.host = apiData.host
        components.path = apiData.path + (method ?? "") + (withPathExtension ?? "")
        
        if let parameters = parameters {
            components.queryItems = [URLQueryItem]()
            for (key, value) in parameters {
                let queryItem = URLQueryItem(name: key, value: "\(value)")
                components.queryItems!.append(queryItem)
            }
        }
        
        return components.url!
    }
    
    // MARK: Cookies
    
    func cookieForName(_ name: String) -> HTTPCookie? {
        let sharedCookieStorage = HTTPCookieStorage.shared
        for cookie in sharedCookieStorage.cookies! {
            if cookie.name == name {
                return cookie
            }
        }
        return nil
    }
    
    // MARK: Errors
    
    func errorWithStatus(_ status: Int, description: String) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey: description]
        return NSError(domain: apiData.domain, code: status, userInfo: userInfo)
    }
    
    // MARK: Cancel Pending Tasks
    
    func cancelPendingTasks(_ apiData: APIData) {
        session.invalidateAndCancel()
        configureNewSession(apiData)
    }
}

