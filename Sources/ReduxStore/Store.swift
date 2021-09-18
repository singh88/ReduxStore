//
//  Store.swift
//  Tests
//
//  Created by Manish Singh on 8/18/21.
//

import Foundation
import RxSwift
import RxCocoa

class DefaultStore<R: Reducer, RS: ReduxState,
                   AC: ActionCreator, A: Action, M: Middleware>: Store where R.A == A,
                                                                                AC.A == A,
                                                                                R.S == RS,
                                                                                R.S == AC.S,
                                                                                M.A == A,
                                                                                M.S == RS {
    var reducer: R
    var actionCreator: AC
    var middleWare: M
    var disposeBag = DisposeBag()
    var state: BehaviorRelay<RS>
    var sideEffects: BehaviorRelay<R.SE?>

    private var lastAction: A?

    init(_ state: RS, _ actionC: AC, reducer: R, middleWare: M) {
        self.actionCreator = actionC
        self.reducer = reducer
        self.middleWare = middleWare
        self.state = BehaviorRelay(value: state)
        self.sideEffects = BehaviorRelay(value: nil)
    }

    public func dispatchActions(_ actions: Observable<A>) {
        actions.subscribe(on: MainScheduler.instance)
            .subscribe (onNext:{ [weak self] singleAction in
                self?.dispatchAction(singleAction)
            }).disposed(by: disposeBag)
    }

    public func dispatchAction(_ action: A) {
        actionCreator.createAction(action: action, currentState: state.value)
            .subscribe(on: MainScheduler.instance)
            .subscribe (onError: { error in
                self.onError(error, action: action)
            }, onCompleted: {
                self.onComplete(action)
            }).disposed(by: disposeBag)
    }

    private func onError(_ error: Error, action: A) {
        var currentState = state.value
        middleWare.logAction(action, currentState: currentState)
        let reducerValues = reducer.onError(error: error,
                                                 state: &currentState,
                                                 action: action)
        if let unwrappedSideEffects = reducerValues.1 {
            sideEffects.accept(unwrappedSideEffects)
        }

        state.accept(reducerValues.0)
    }

    private func onComplete(_ action: A) {
        var currentState = state.value
        middleWare.logAction(action, currentState: currentState)
        let reducerValues = self.reducer.createReducer(state: &currentState, action: action)

        if let unwrappedSideEffects = reducerValues.1 {
            sideEffects.accept(unwrappedSideEffects)
        }

        state.accept(reducerValues.0)
    }
}
