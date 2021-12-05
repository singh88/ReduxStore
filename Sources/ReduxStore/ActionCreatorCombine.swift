//
//  ActionCreatorCombine.swift
//  ReduxStore
//
//  Created by Manish Singh on 10/24/21.
//
import Combine

/// Action Creator Protocol for Combine
@available(iOS 13.0, *)
public protocol ActionCreatorCombine {
    associatedtype A
    associatedtype S
    mutating func createAction(action: A, currentState: S) -> AnyPublisher<A, Error>
}
