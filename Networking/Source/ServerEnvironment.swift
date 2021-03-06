//
//  ServerEnvironment.swift
//  Networking
//
//  Created by yangyang on 2021/9/9.
//

import Foundation

struct ServerEnvironment {
    public static let defaultOptionValue: ServerEnvironment? = nil
    
    public var host: String
    public var pathPrefix: String
    public var headers: [String: String]
    public var query: [URLQueryItem]

    public init(host: String, pathPrefix: String = "/", headers: [String: String] = [:], query: [URLQueryItem] = []) {
        // make sure the pathPrefix starts with a /
        let prefix = pathPrefix.hasPrefix("/") ? "" : "/"
        
        self.host = host
        self.pathPrefix = prefix + pathPrefix
        self.headers = headers
        self.query = query
    }
}

extension ServerEnvironment {

    public static let development = ServerEnvironment(host: "development.example.com", pathPrefix: "/api-dev")
    public static let qa = ServerEnvironment(host: "qa-1.example.com", pathPrefix: "/api")
    public static let staging = ServerEnvironment(host: "api-staging.example.com", pathPrefix: "/api")
    public static let production = ServerEnvironment(host: "api.example.com", pathPrefix: "/api")

}
