//
//  Throttle.swift
//  Networking
//
//  Created by yangyang on 2021/9/13.
//

import Foundation

public class Throttle: HTTPLoader {
    public var maximumNumberOfRequests = UInt.max

    private var executingRequests = [UUID: HTTPTask]()
    private var pendingRequests = [HTTPTask]()

    public override func load(task: HTTPTask) {
        if UInt(executingRequests.count) < maximumNumberOfRequests {
            startTask(task)
        } else {
            pendingRequests.append(task)
        }
    }

    private func startTask(_ task: HTTPTask) {
        let id = task.id
        executingRequests[id] = task
        task.addCancellationHandler {
            self.executingRequests[id] = nil
            self.startNextTasksIfAble()
        }
        super.load(task: task)
    }

    private func startNextTasksIfAble() {
        while UInt(executingRequests.count) < maximumNumberOfRequests && pendingRequests.count > 0 {
            // we have capacity for another request, and more requests to start
            let next = pendingRequests.removeFirst()
            startTask(next)
        }
    }
}

public enum ThrottleOption: HTTPRequestOption {
    public static var defaultOptionValue: ThrottleOption { .always }
    
    case always
    case never
}

extension HTTPRequest {
    public var throttle: ThrottleOption {
        get { self[option: ThrottleOption.self] }
        set { self[option: ThrottleOption.self] = newValue }
    }
}
