//
//  HTTPBody.swift
//  Networking
//
//  Created by yangyang on 2021/9/13.
//

import Foundation

public protocol HTTPBody {
    var isEmpty: Bool { get }
    var additionalHeaders: [String: String] { get }
    func encode() throws -> Data
}

extension HTTPBody {
    public var isEmpty: Bool { return false }
    public var additionalHeaders: [String: String] { return [:] }
}

public struct DataBody: HTTPBody {
    private let data: Data
    
    public var isEmpty: Bool { data.isEmpty }
    public var additionalHeaders: [String: String]
    
    public init(_ data: Data, additionalHeaders: [String: String] = [:]) {
        self.data = data
        self.additionalHeaders = additionalHeaders
    }
    
    public func encode() throws -> Data { data }
}

public struct JSONBody: HTTPBody {
    public let isEmpty: Bool = false
    public var additionalHeaders = [
        "Content-Type": "application/json; charset=utf-8"
    ]
    
    private let encodeMethod: () throws -> Data
    
    public init<T: Encodable>(_ value: T, encoder: JSONEncoder = JSONEncoder()) {
        self.encodeMethod = { try encoder.encode(value) }
    }
    
    public func encode() throws -> Data { return try encodeMethod() }
}

public struct FormBody: HTTPBody {
    public var isEmpty: Bool { values.isEmpty }
    public let additionalHeaders = [
        "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
    ]
    
    private let values: [URLQueryItem]
    
    public init(_ values: [URLQueryItem]) {
        self.values = values
    }
    
    public init(_ values: [String: String]) {
        let queryItems = values.map { URLQueryItem(name: $0.key, value: $0.value) }
        self.init(queryItems)
    }
    
    public func encode() throws -> Data {
        let pieces = values.map(self.urlEncode)
        let bodyString = pieces.joined(separator: "&")
        return Data(bodyString.utf8)
    }

    private func urlEncode(_ queryItem: URLQueryItem) -> String {
        let name = urlEncode(queryItem.name)
        let value = urlEncode(queryItem.value ?? "")
        return "\(name)=\(value)"
    }

    private func urlEncode(_ string: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
    }
}
