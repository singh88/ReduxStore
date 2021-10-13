//
//  Action.swift
//
//  Created by Manish Singh on 8/18/21.
//

import Foundation
import RxSwift
import RxCocoa

public protocol Action { }

public protocol ReduxState { }

public protocol HasDisposeBag {
    var disposeBag: DisposeBag { get }
}

public extension HasDisposeBag {
    var disposeBag: DisposeBag {
        return DisposeBag()
    }
}
