//
//  HTTPTask.swift
//  Networking
//
//  Created by yangyang on 2021/9/13.
//

import Foundation

public class HTTPTask {
    public var id: UUID { request.id }
    public var request: HTTPRequest
    private let completion: (HTTPResult) -> Void

    public init(request: HTTPRequest, completion: @escaping (HTTPResult) -> Void) {
        self.request = request
        self.completion = completion
    }

    public func complete(with result: HTTPResult) {
        completion(result)
    }
    
    private var cancellationHandlers = Array<() -> Void>()

    public func addCancellationHandler(_ handler: @escaping () -> Void) {
        // TODO: make this thread-safe
        // TODO: what if this was already cancelled?
        // TODO: what if this is already finished but was not cancelled before finishing?
        cancellationHandlers.append(handler)
    }

    public func cancel() {
        // TODO: toggle some state to indicate that "isCancelled == true"
        // TODO: make this thread-safe
        let handlers = cancellationHandlers
        cancellationHandlers = []

        // invoke each handler in reverse order
        handlers.reversed().forEach { $0() }
    }
}

