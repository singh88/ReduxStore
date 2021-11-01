//
//  DefaultRxStore.swift
//
//
//  Created by Manish Singh on 8/18/21.
//

import Foundation
import RxSwift
import RxCocoa

public final class DefaultRxStore<R: Reducer, RS: ReduxState,
                   AC: ActionCreator, A: Action, M: Middleware> where R.A == A,
                                                                        AC.A == A,
                                                                        R.S == RS,
                                                                        R.S == AC.S,
                                                                        M.A == A,
                                                                        M.S == RS {
    var reducer: R
    var actionCreator: AC
    var middleWare: M
    var disposeBag = DisposeBag()
    private var _state: BehaviorRelay<RS>

    public var state: Observable<RS> {
        return _state.asObservable()
    }

    public var _sideEffects: BehaviorRelay<R.SE?>

    public var sideEffects: Observable<R.SE?> {
        return _sideEffects.asObservable().observe(on: MainScheduler.instance)
    }

    private var nextAction: A?

    private let scheduler = DispatchQueue(label: "SerialStoreQueue")

    private let sch = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global())

    public init(_ state: RS, _ actionC: AC, reducer: R, middleWare: M) {
        self.actionCreator = actionC
        self.reducer = reducer
        self.middleWare = middleWare
        self._state = BehaviorRelay(value: state)
        self._sideEffects = BehaviorRelay(value: nil)
    }

    public func dispatchActions(_ actions: Observable<A>) {
        actions
            .subscribe (onNext:{ [weak self] singleAction in
                self?.dispatchAction(singleAction)
            }).disposed(by: disposeBag)
    }

    fileprivate func updateCurrentAction(_ action: A) {
        scheduler.sync {
            nextAction = action
        }
    }

    public func dispatchAction(_ action: A) {
        actionCreator
            .createAction(action: action, currentState: _state.value)
            .observe(on: sch)
            .subscribe (
            onNext: { [weak self] action in
                self?.updateCurrentAction(action)
            }, onError: { [weak self] error in
                self?.onError(error, action: action)
            }, onCompleted: { [weak self] in
                self?.onComplete(action)
            }).disposed(by: disposeBag)
    }

    fileprivate func getCurrentStateValue() -> RS {
        scheduler.sync {
            return _state.value
        }
    }

    fileprivate func triggerMiddleWareCall(_ action: A, _ currentState: RS) {
        scheduler.sync {
            middleWare.logAction(action, currentState: currentState)
        }
    }

    private func onError(_ error: Error, action: A) {
        var currentState = getCurrentStateValue()
        triggerMiddleWareCall(action, currentState)
        
        let reducerValues = reducer.onError(error: error,
                                                 state: &currentState,
                                                 action: action)
        _sideEffects.accept(reducerValues.sideEffects)
        _state.accept(reducerValues.0)
    }

    private func onComplete(_ action: A) {
        var currentState = getCurrentStateValue() // old values
        triggerMiddleWareCall(action, currentState)

        let reducerValues = reducer.createReducer(state: &currentState, action: action)
        _state.accept(reducerValues.newState)
        _sideEffects.accept(reducerValues.sideEffects)

        guard let nextAction = nextAction else {
            return
        }

        // In case of successful events onNext will be called so we need
        // to call next action from the reducer and for that we need to store nextAction in the store to use that in onComplete. Since onComplete is called for `.empty()` as well as `onNext`. Currently, I can not think of a better way to clear this up but there should be more elegant way for this.
        self.nextAction = nil
        dispatchAction(nextAction)
    }
}


