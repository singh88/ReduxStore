//
//  DefaultCombineStore.swift
//  ReduxStore
//
//  Created by Manish Singh on 10/23/21.
//
import Foundation
import Combine

@available(iOS 13.0, *)

public final class DefaultCombineStore<R: Reducer, RS: ReduxState,
                                       AC: ActionCreatorCombine, A: Action, M: Middleware> where R.A == A,
                                                                                                 AC.A == A,
                                                                                                 R.S == RS,
                                                                                                 R.S == AC.S,
                                                                                                 M.A == A,
                                                                                                 M.S == RS {
    var reducer: R
    var actionCreator: AC
    var middleWare: M

    private let storeQueue =  DispatchQueue(label: "StoreQueueCombine")

    private var cacellableTasks: Set<AnyCancellable> = []
    private(set) var _state: CurrentValueSubject<RS, Never>
    private(set) var _sideEffects: CurrentValueSubject<R.SE?, Never>

    public var sideEffects: AnyPublisher<R.SE?, Never> {
        return _sideEffects.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    public var state: AnyPublisher<RS, Never> {
        return _state.eraseToAnyPublisher()
    }

    private var _nextAction: A?

    /// Store initializer and that is supposed to happen just once during the lifecycle of this store
    /// - Parameters:
    ///   - state: State type
    ///   - actionC: ActionCreator concrete implemetation
    ///   - reducer: Reducer concrete implementation
    ///   - middleWare: Middlerware concrete implementation
    public init(_ state: RS, _ actionC: AC, reducer: R, middleWare: M) {
        self.actionCreator = actionC
        self.reducer = reducer
        self.middleWare = middleWare
        self._state = CurrentValueSubject(state)
        self._sideEffects = CurrentValueSubject(nil)
    }

    /// Accpets many actions together in a single stream.
    /// - Parameter actions:
    public func dispatchActions(_ actions: AnyPublisher<A, Never>) {
        actions
            .sink { [weak self] action in
                self?.dispatchAction(action)
            }.store(in: &cacellableTasks)
    }

    public func dispatchAction(_ action: A) {
        actionCreator
            .createAction(action: action, currentState: _state.value)
            .receive(on: storeQueue)
            .sink { [unowned self] completion in
                self.middleWare.logAction(action, currentState: self._state.value)
                switch completion {
                    case .failure(let error):
                        self.onError(error, action: action)
                    case .finished:
                        self.onComplete(action)
                }
            } receiveValue: { latestAction in
                self._nextAction = latestAction
            }.store(in: &cacellableTasks)
    }

    private func onError(_ error: Error, action: A) {
        var currentState = _state.value
        let reducerValues = reducer.onError(error: error,
                                            state: &currentState,
                                            action: action)
        _state.send(reducerValues.newState)
        _sideEffects.send(reducerValues.sideEffects)
    }

    private func onComplete(_ action: A) {
        var currentState = _state.value
        let reducerValues = reducer.createReducer(state: &currentState, action: action)
        _state.send(reducerValues.newState)
        _sideEffects.send(reducerValues.sideEffects)

        guard let nextAction = _nextAction else {
            return
        }
        /*
         In case of successful events onNext will be called so we need
         to call next action from the reducer and for that we need to store nextAction in the store to use that in onComplete. Since onComplete is called for `.empty()` as well as `onNext`. Currently, I can not think of a better way to clear this up but there should be more elegant way for this.
         */
        self._nextAction = nil
        dispatchAction(nextAction)
    }
}

