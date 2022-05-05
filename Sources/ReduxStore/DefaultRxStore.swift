//
//  DefaultRxStore.swift
//
//
//  Created by Manish Singh on 8/18/21.
//

import Foundation
import RxSwift
import RxCocoa

// References: https://github.com/pointfreeco/swift-composable-architecture

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

    private var nextAction = [A?]()

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

    fileprivate func getCurrentState() -> RS {
        return _state.value
    }

    ///  All the dispatchedActions from ActionCreator are supposed to come from the main thread
    ///  and this is done to avoid queue hopping. We have tried to add storequeue but in case of sync and asycn function
    ///  calls behavior causes various issues on UI. For instance, if action creator returns an empty observable
    ///  then call returns to this function on the main queue and if store is using a separate dedicated queue
    ///  to do things in onNext and onComplete then it will cause thread queue hopping which will create patchy UX.
    ///  Better approach could have been to take the responsibility to move the responsibilty from the caller to store to do that decisioning
    ///  but it comes with a cost of hopping. So for now that responsibiblity is with the caller.
    /// - Parameter action: Generic Action type
    public func dispatchAction(_ action: A) {
        actionCreator
            .createAction(action: action, currentState: getCurrentState())
            .subscribe (
            onNext: { [weak self] action in
                self?.nextAction.append(action)
            }, onCompleted: { [weak self] in
                self?.onComplete(action)
            }).disposed(by: disposeBag)
    }

    func printAllNextEvents() {
        nextAction.forEach {
            logEvents("currently \($0) is in queue")
        }
    }

    func logEvents(_ message: String) {
        #if DEBUG
            print("calling \(message)")
        #endif
    }

    /// This function will be called on every complete call from action creator.
    /// The two main calls that this function is responsible for
    /// are calling the reducer and calling the next action if any.
    /// - Parameter action: Generic Action type
    private func onComplete(_ action: A) {
        printAllNextEvents()

        var currentState = getCurrentState() // old values
        middleWare.logAction(action, currentState: currentState)

        let reducerValues = reducer.createReducer(state: &currentState, action: action)
        _state.accept(currentState)
        _sideEffects.accept(reducerValues)

        while !nextAction.isEmpty {
            guard let nextAction = nextAction.popLast(),
                    let unwrappedNextAction = nextAction
            else {
                return
            }

            logEvents("popped action is \(unwrappedNextAction)")

            // In case of successful events onNext will be called so we need
            // to call next action from the reducer and for that we need to store nextAction in the store to use that in onComplete. Since onComplete is called for `.empty()` as well as `onNext`. Currently, I can not think of a better way to clear this up but there should be more elegant way for this.Missing required module 'RxCocoaRuntime'
            dispatchAction(unwrappedNextAction)
        }
    }
}


