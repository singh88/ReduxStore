//
//  Middleware.swift
//  
//
//  Created by Manish Singh on 10/2/21.
//

/// Used for logging
public protocol Middleware {
    associatedtype A
    associatedtype S
    func logAction(_ action: A, currentState: S)
}
