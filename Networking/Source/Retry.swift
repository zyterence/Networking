//
//  Retry.swift
//  Networking
//
//  Created by yangyang on 2021/9/13.
//

import Foundation

public protocol HTTPRetryStrategy {
    func retryDelay(for result: HTTPResult) -> TimeInterval?
}

public struct Backoff: HTTPRetryStrategy {
    public func retryDelay(for result: HTTPResult) -> TimeInterval? {
        return nil
    }
    
    public func immediately(maximumNumberOfAttempts: Int) -> Backoff {
        return self
    }
    public func constant(delay: TimeInterval, maximumNumberOfAttempts: Int) -> Backoff {
        return self
    }
    public func exponential(delay: TimeInterval, maximumNumberOfAttempts: Int) -> Backoff {
        return self
    }
}

struct TwitterRetryStrategy: HTTPRetryStrategy {
    func retryDelay(for result: HTTPResult) -> TimeInterval? {
        // TODO: are there other scenarios to consider?
        guard let response = result.response else { return nil }

        switch response.status.rawValue {

            case 429:
                // look for the header that tells us when our limit resets
                guard let retryHeader = response.headers["x-rate-limit-reset"] else { return nil }
                guard let resetTime = TimeInterval(retryHeader as! Substring) else { return nil }
                let resetDate = Date(timeIntervalSince1970: resetTime)
                let timeToWait = resetDate.timeIntervalSinceNow
                guard timeToWait >= 0 else { return nil }
                return timeToWait

            case 503:
                // look for the header that tells us how long to wait
                guard let retryHeader = response.headers["retry-after"] else { return nil }
                return TimeInterval(retryHeader as! Substring)

            default:
                return nil
        }
    }
}

public enum RetryOption: HTTPRequestOption {
    // by default, HTTPRequests do not have a retry strategy, and therefore do not get retried
    public static var defaultOptionValue: HTTPRetryStrategy? { nil }
}

extension HTTPRequest {
    public var retryStrategy: HTTPRetryStrategy? {
        get { self[option: RetryOption.self] }
        set { self[option: RetryOption.self] = newValue }
    }
}

// TODO: make all of this thread-safe
public class Retry: HTTPLoader {
    // the original tasks as received by the load(task:) method
    private var originalTasks = Dictionary<UUID, HTTPTask>()

    // the times at which specific tasks should be re-attempted
    private var pendingTasks = Dictionary<UUID, Date>()

    // the currently-executing duplicates
    private var executingAttempts = Dictionary<UUID, HTTPTask>()

    // the timer for notifying when it's time to try another attempt
    private var timer: Timer?
    
    public override func load(task: HTTPTask) {
        let taskID = task.id
        // we need to know when the original task is cancelled
        task.addCancellationHandler { [weak self] in
            self?.cleanupFromCancel(taskID: taskID)
        }
        
        attempt(task)
    }
    
    /// Immediately attempt to load a duplicate of the task
    private func attempt(_ task: HTTPTask) {
        // overview: duplicate this task and
        // 1. Create a new HTTPTask that invokes handleResult(_:for:) when done
        // 2. Save this information into the originalTasks and executingAttempts dictionaries

        let taskID = task.id
        let thisAttempt = HTTPTask(request: task.request, completion: { [weak self] result in
            self?.handleResult(result, for: taskID)
        })
        
        originalTasks[taskID] = task
        executingAttempts[taskID] = thisAttempt
        
        super.load(task: thisAttempt)
    }
    
    private func cleanupFromCancel(taskID: UUID) {
        // when a task is cancelled:
        // - the original task is removed
        // - any executing attempt must be cancelled
        // - any pending task must be removed AND explicitly failed
        //   - this is a task that was stopped at this level, therefore
        //     this loader is responsible for completing it

        // TODO: implement this
    }
    
    private func handleResult(_ result: HTTPResult, for taskID: UUID) {
        // schedule the original task for retrying, if necessary
        // otherwise, manually complete the original task with the result

        executingAttempts.removeValue(forKey: taskID)
        guard let originalTask = originalTasks.removeValue(forKey: taskID) else { return }
            
        if let delay = retryDelay(for: originalTask, basedOn: result) {
            pendingTasks[taskID] = Date(timeIntervalSinceNow: delay)
            rescheduleTimer()
        } else {
            originalTask.complete(with: result)
        }
    }
    
    private func retryDelay(for task: HTTPTask, basedOn result: HTTPResult) -> TimeInterval? {
        // we do not retry tasks that were cancelled or stopped because we're resetting
        // TODO: return nil if the result indicates the task was cancelled
        // TODO: return nil if the result indicates the task failed because of `.resetInProgress`
        
        let strategy = task.request.retryStrategy
        guard let delay = strategy?.retryDelay(for: result) else { return nil }
        return max(delay, 0) // don't return a negative delay
    }
    
    private func rescheduleTimer() {
        // TODO: look through `pendingTasks` find the task that will be retried soonest
        // TODO: schedule the timer to fire at that time and call `fireTimer()`
    }
    
    private func fireTimer() {
        // TODO: get the tasks that should've started executing by now and attempt them
        // TODO: reschedule the timer
    }
    
    public override func reset(with group: DispatchGroup) {
        // This loader is done resetting when all its tasks are done executing

        for task in originalTasks.values {
            group.enter()
            task.addCancellationHandler { group.leave() }
        }
        
        super.reset(with: group)
    }
}
