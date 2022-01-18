//
//  DefaultCombineStore.swift
//  ReduxStore
//
//  Created by Manish Singh on 10/23/21.
//
import Foundation
import Combine

@available(macOS 10.15, *)
@available(iOS 13.0, *)

public final class DefaultCombineStore<R: Reducer, RS: ReduxState,
                                       AC: ActionCreatorCombine, A: Action, M: Middleware> where R.A == A, AC.A == A,  R.S == RS, R.S == AC.S, M.A == A, M.S == RS {
    var reducer: R
    var actionCreator: AC
    var middleWare: M

    private var cacellableTasks: Set<AnyCancellable> = []
    private(set) var _state: CurrentValueSubject<RS, Never>
    private(set) var _sideEffects: CurrentValueSubject<R.SE?, Never>

    public var sideEffects: AnyPublisher<R.SE?, Never> {
        return _sideEffects.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    public var state: AnyPublisher<RS, Never> {
        return _state.eraseToAnyPublisher()
    }

    private var _nextAction = [A?]()

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
            .createAction(action: action, currentState: _state.value)
            .sink { [unowned self] completion in
                self.middleWare.logAction(action, currentState: self._state.value)
                self.onComplete(action)
            } receiveValue: { latestAction in
                self._nextAction.append(latestAction)
            }.store(in: &cacellableTasks)
    }

    private func onComplete(_ action: A) {
        var currentState = _state.value
        let reducerValues = reducer.createReducer(state: &currentState, action: action)
        _state.send(currentState)
        _sideEffects.send(reducerValues)

        while !_nextAction.isEmpty {
            guard let nextAction = _nextAction.popLast(),
                    let unwrappedNextAction = nextAction
            else {
                return
            }

            print("popped action is \(unwrappedNextAction)")

            // In case of successful events onNext will be called so we need
            // to call next action from the reducer and for that we need to store nextAction in the store to use that in onComplete. Since onComplete is called for `.empty()` as well as `onNext`. Currently, I can not think of a better way to clear this up but there should be more elegant way for this.
//            self.nextAction = nil
            dispatchAction(unwrappedNextAction)
        }
    }

    func printAllNextEvents() {
        _nextAction.forEach {
            logEvents("currently \($0) is in queue")
        }
    }

    func logEvents(_ message: String) {
        #if DEBUG
            print("calling \(message)")
        #endif
    }

    fileprivate func getCurrentState() -> RS {
        return _state.value
    }
}

