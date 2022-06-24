//
//  ActionHandlerCombine.swift
//  ReduxStore
//
//  Created by Manish Singh on 10/24/21.
//
import Combine

/// A type that handles action and its underlying calls.
@available(iOS 13.0, *)
public protocol ActionHandlerCombine {
    associatedtype A
    associatedtype S
    @available(macOS 10.15, *)
    mutating func createAction(action: A, currentState: S) -> AnyPublisher<A, Error>
}
