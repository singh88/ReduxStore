//
//  ActionHandler.swift
//  
//
//  Created by Manish Singh on 10/2/21.
//

import RxSwift

/// A type that handles action and its underlying calls.
public protocol ActionHandler {
    /// Action
    associatedtype A

    /// State
    associatedtype S

    /// Handles actions and its outcomes
    /// - Parameters:
    ///   - action: current action in the queue
    ///   - currentState: current state of the application state
    /// - Returns: an observable state with the next action.
    mutating func createAction(action: A, currentState: S) -> Observable<A>
}
