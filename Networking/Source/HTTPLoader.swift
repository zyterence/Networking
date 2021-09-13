//
//  HTTPLoader.swift
//  Networking
//
//  Created by yangyang on 2021/9/9.
//

import Foundation

precedencegroup LoaderChainingPrecedence {
    higherThan: NilCoalescingPrecedence
    associativity: right
}

infix operator --> : LoaderChainingPrecedence

@discardableResult
public func --> (lhs: HTTPLoader?, rhs: HTTPLoader?) -> HTTPLoader? {
    lhs?.nextLoader = rhs
    return lhs ?? rhs
}

open class HTTPLoader {

    public var nextLoader: HTTPLoader? {
        willSet {
            guard nextLoader == nil else { fatalError("The nextLoader may only be set once") }
        }
    }

    public init() { }

    open func load(request: HTTPRequest, completion: @escaping (HTTPResult) -> Void) {

        if let next = nextLoader {
            next.load(request: request, completion: completion)
        } else {
            let error = HTTPError(code: .cannotConnect, request: request)
            completion(.failure(error))
        }

    }
    
    open func load(task: HTTPTask) {
        if let next = nextLoader {
            next.load(task: task)
        } else {
            // a convenience method to construct an HTTPError
            // and then call .complete with the error in an HTTPResult
//            task.complete(with: .failure(error))
        }
    }
    
    open func reset(completionHandler: @escaping () -> Void) {
        if let next = nextLoader {
            next.reset(completionHandler: completionHandler)
        } else {
            completionHandler()
        }
    }
    
    open func reset(with group: DispatchGroup) {
        nextLoader?.reset(with: group)
    }
}

public class ResetGuard: HTTPLoader {
    private var isResetting = false
    
    public override func load(request: HTTPRequest, completion: @escaping (HTTPResult) -> Void) {
        // TODO: make this thread-safe
        if isResetting == false {
            super.load(request: request, completion: completion)
        } else {
            let error = HTTPError(code: .resetInProgress, request: request)
            completion(.failure(error))
        }
    }
    
    public override func reset(with group: DispatchGroup) {
        // TODO: make this thread-safe
        if isResetting == true { return }
        guard let next = nextLoader else { return }
        
        group.enter()
        isResetting = true
        next.reset {
            self.isResetting = false
            group.leave()
        }
    }
}

extension HTTPLoader {

    public final func reset(on queue: DispatchQueue = .main, completionHandler: @escaping () -> Void) {
        let group = DispatchGroup()
        self.reset(with: group)

        group.notify(queue: queue, execute: completionHandler)
    }
}

class AnyLoader: HTTPLoading {
    var nextLoader: HTTPLoader?

    private let loader: HTTPLoading

    init(_ other: HTTPLoading) {
        self.loader = other
    }

    func load(request: HTTPRequest, completion: @escaping (HTTPResult) -> Void) {
        loader.load(request: request, completion: completion)
    }
}

public class ModifyRequest: HTTPLoader {

    private let modifier: (HTTPRequest) -> HTTPRequest

    public init(modifier: @escaping (HTTPRequest) -> HTTPRequest) {
        self.modifier = modifier
        super.init()
    }

    override public func load(request: HTTPRequest, completion: @escaping (HTTPResult) -> Void) {
        let modifiedRequest = modifier(request)
        super.load(request: modifiedRequest, completion: completion)
    }
}

public class URLSessionLoader: HTTPLoader {

    open override func load(task: HTTPTask) {
        // constructing the URLRequest from the HTTPRequest
//        let dataTask = self.session.dataTask(with: urlRequest) {}
//
//        // if the HTTPTask is cancelled, also cancel the dataTask
//        task.addCancellationHandler { dataTask.cancel() }
//        dataTask.resume()
    }
}

public class Autocancel: HTTPLoader {
    private let queue = DispatchQueue(label: "AutocancelLoader")
    private var currentTasks = [UUID: HTTPTask]()
    
    public override func load(task: HTTPTask) {
        queue.sync {
            let id = task.id
            currentTasks[id] = task
            task.addCancellationHandler {
                self.queue.sync {
                    self.currentTasks[id] = nil
                }
            }
        }
        
        super.load(task: task)
    }
    
    public override func reset(with group: DispatchGroup) {
        group.enter() // indicate that we have work to do
        queue.async {
            // get the list of current tasks
            let copy = self.currentTasks
            self.currentTasks = [:]
            DispatchQueue.global(qos: .userInitiated).async {
                for task in copy.values {
                    // cancel the task
                    group.enter()
                    task.addCancellationHandler { group.leave() }
                    task.cancel()
                }
                group.leave()
            }
        }
        
        nextLoader?.reset(with: group)
    }
    
}
