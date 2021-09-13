//
//  HTTPMethod.swift
//  Networking
//
//  Created by yangyang on 2021/9/13.
//

import Foundation

public struct HTTPMethod: Hashable {
    public static let get = HTTPMethod(rawValue: "GET")
    public static let post = HTTPMethod(rawValue: "POST")
    public static let put = HTTPMethod(rawValue: "PUT")
    public static let delete = HTTPMethod(rawValue: "DELETE")

    public let rawValue: String
}


public struct HTTPStatus: Hashable {
    public static let ok = HTTPStatus(rawValue: 200)

    public let rawValue: Int
}
