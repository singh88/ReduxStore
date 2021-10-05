//
//  DefaultStore.swift
//
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

    private var nextAction: A?

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
            .subscribe (
            onNext: { [weak self] action in
                self?.nextAction = action
            }, onError: { [weak self] error in
                self?.onError(error, action: action)
            }, onCompleted: { [weak self] in
                guard let self = self else { return }

                guard let uparapped = self.nextAction
                else { return self.onComplete(action) }
                self.onComplete(uparapped)
            }).disposed(by: disposeBag)
    }

    private func onError(_ error: Error, action: A) {
        var currentState = state.value
        middleWare.logAction(action, currentState: currentState)
        let reducerValues = reducer.onError(error: error,
                                                 state: &currentState,
                                                 action: action)
        sideEffects.accept(reducerValues.sideEffects)
        state.accept(reducerValues.0)
    }

    private func onComplete(_ action: A) {
        var currentState = state.value // old values
        middleWare.logAction(action, currentState: currentState)

        let reducerValues = reducer.createReducer(state: &currentState, action: action)
        state.accept(reducerValues.newState)
        sideEffects.accept(reducerValues.sideEffects)

        // In case of successful events onNext will be called so we need
        // to call next action from the reducer and for that we need to store nextAction in the store to use that in onComplete. Since onComplete is called for `.empty()` as well as `onNext`. Currently, I can not think of a better way to clear this up but there should be more elegant way for this.
        nextAction = nil
    }
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


