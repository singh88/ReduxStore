//
//  ActionCreator.swift
//  
//
//  Created by Manish Singh on 10/2/21.
//

public protocol ActionCreator {
    associatedtype A
    associatedtype S
    mutating func createAction(action: A, currentState: S) -> Observable<A>
}
