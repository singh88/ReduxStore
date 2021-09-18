//
//  Action.swift
//
//  Created by Manish Singh on 8/18/21.
//

import Foundation
import RxSwift
import RxCocoa

protocol Action { }

protocol ReduxState { }

/// Used for logging
protocol Middleware {
    associatedtype A
    associatedtype S
    func logAction(_ action: A, currentState: S)
}

protocol SideEffects { }

protocol ActionCreator {
    associatedtype A
    associatedtype S
    mutating func createAction(action: A, currentState: S) -> Observable<A>
}

protocol Reducer {
    associatedtype A
    associatedtype S
    associatedtype SE
    mutating func createReducer(state: inout S, action: A) -> (S, SE?)
    mutating func onError(error: Error, state: inout S, action: A) -> (S, SE?)
}

protocol Store: AnyObject {
    associatedtype R
    associatedtype RS
    associatedtype AC
    associatedtype A
    associatedtype M

    var reducer: R { set get }
    var state: BehaviorRelay<RS> { set get }
    var actionCreator: AC { set get }

    func dispatchActions(_ action: Observable<A>)
    func dispatchAction(_ action: A)
}
