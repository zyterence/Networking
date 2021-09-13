//
//  HTTPRequest.swift
//  Networking
//
//  Created by yangyang on 2021/9/9.
//

import Foundation

public struct HTTPRequest {
    var id: UUID = UUID()
    private var urlComponents = URLComponents()
    public var method: HTTPMethod = .get // the struct we previously defined
    public var headers: [String: String] = [:]
    public var body: HTTPBody?

    public init() {
        urlComponents.scheme = "https"
    }
    
    private var options = [ObjectIdentifier: Any]()

    public subscript<O: HTTPRequestOption>(option type: O.Type) -> O.Value {
        get {
            // create the unique identifier for this type as our lookup key
            let id = ObjectIdentifier(type)

            // pull out any specified value from the options dictionary, if it's the right type
            // if it's missing or the wrong type, return the defaultOptionValue
            guard let value = options[id] as? O.Value else { return type.defaultOptionValue }

            // return the value from the options dictionary
            return value
        }
        set {
            let id = ObjectIdentifier(type)
            // save the specified value into the options dictionary
            options[id] = newValue
        }
    }
}


public extension HTTPRequest {

    var scheme: String { urlComponents.scheme ?? "https" }
    
    var host: String? {
        get { urlComponents.host }
        set { urlComponents.host = newValue }
    }
    
    var path: String {
        get { urlComponents.path }
        set { urlComponents.path = newValue }
    }

}

public protocol HTTPRequestOption {
    associatedtype Value

    /// The value to use if a request does not provide a customized value
    static var defaultOptionValue: Value { get }
}
