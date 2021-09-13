//
//  HTTPLoading.swift
//  Networking
//
//  Created by yangyang on 2021/9/13.
//

import Foundation

public protocol HTTPLoading {
    var nextLoader: HTTPLoader? { get set }
    
    func load(request: HTTPRequest, completion: @escaping (HTTPResult) -> Void)
}

//extension URLSession: HTTPLoading {
//    public func load(request: HTTPRequest, completion: @escaping (HTTPResult) -> Void)
//        guard let url = request.url else {
//            // we couldn't construct a proper URL out of the request's URLComponents
//            completion(.failure(...))
//            return
//        }
//        
//        // construct the URLRequest
//        var urlRequest = URLRequest(url: url)
//        urlRequest.httpMethod = request.method.rawValue
//        
//        // copy over any custom HTTP headers
//        for (header, value) in request.headers {
//            urlRequest.addValue(value, forHTTPHeaderField: header)
//        }
//        
//        if request.body.isEmpty == false {
//            // if our body defines additional headers, add them
//            for (header, value) in request.body.additionalHeaders {
//                urlRequest.addValue(value, forHTTPHeaderField: header)
//            }
//            
//            // attempt to retrieve the body data
//            do {
//                urlRequest.httpBody = try request.body.encode()
//            } catch {
//                // something went wrong creating the body; stop and report back
//                completion(.failure(...))
//                return
//            }
//        }
//        
//        let dataTask = session.dataTask(with: urlRequest) { (data, response, error) in
//            // construct a Result<HTTPResponse, HTTPError> out of the triplet of data, url response, and url error
//            let result = HTTPResult(request: request, responseData: data, response: response, error: error)
//            completion(result)
//        }
//        
//        // off we go!
//        dataTask.resume()
//    }
//}
