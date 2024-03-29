//
//  Reducer.swift
//  
//
//  Created by Manish Singh on 10/2/21.
//

public protocol Reducer {
    associatedtype A
    associatedtype S
    associatedtype SE
    typealias ReducerOutput = SE?
    mutating func createReducer(state: inout S, action: A) -> ReducerOutput
}
