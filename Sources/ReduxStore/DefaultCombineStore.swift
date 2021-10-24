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

    public init(_ state: RS, _ actionC: AC, reducer: R, middleWare: M) {
        self.actionCreator = actionC
        self.reducer = reducer
        self.middleWare = middleWare
        self._state = CurrentValueSubject(state)
        self._sideEffects = CurrentValueSubject(nil)
    }

    func dispatchActions(_ actions: AnyPublisher<A, Never>) {
        let cancellableActions = actions.sink { [weak self] action in
            self?.dispatchAction(action)
        }

        cacellableTasks = [cancellableActions]
    }

    func dispatchAction(_ action: A) {
        actionCreator
            .createAction(action: action, currentState: _state.value)
            .receive(on: storeQueue).sink { completion in
                switch completion {
                    case .failure(let error):
                        print(error)
                    case .finished:
                        print("Success")
                }
            } receiveValue: { updatedAction in
                print(updatedAction)
            }.store(in: &cacellableTasks)
    }

    private func onError(_ error: Error, action: A) {
        var currentState = _state.value
        middleWare.logAction(action, currentState: currentState)
        let reducerValues = reducer.onError(error: error,
                                                 state: &currentState,
                                                 action: action)
//        _sideEffects.accept(reducerValues.sideEffects)
//        _state.accept(reducerValues.0)
    }

    private func onComplete(_ action: A) {
        var currentState = _state.value // old values
        middleWare.logAction(action, currentState: currentState)

        let reducerValues = reducer.createReducer(state: &currentState, action: action)
//        _state.accept(reducerValues.newState)
//        _sideEffects.accept(reducerValues.sideEffects)
//        guard let nextAction = nextAction else {
//            return
//        }
//
//        // In case of successful events onNext will be called so we need
//        // to call next action from the reducer and for that we need to store nextAction in the store to use that in onComplete. Since onComplete is called for `.empty()` as well as `onNext`. Currently, I can not think of a better way to clear this up but there should be more elegant way for this.
//        self.nextAction = nil
//        dispatchAction(nextAction)
    }
//        actionCreator
//            .createAction(action: action, currentState: _state.value)
//            .observe(on: scheduler)
//            .subscribe (
//            onNext: { [weak self] action in
//                self?.nextAction = action
//            }, onError: { [weak self] error in
//                self?.onError(error, action: action)
//            }, onCompleted: { [weak self] in
//                self?.onComplete(action)
//            }).disposed(by: disposeBag)
    }

    /*
     var reducer: R
     var actionCreator: AC
     var middleWare: M
     var disposeBag = DisposeBag()
     private var _state: BehaviorRelay<RS>
     /// support RxSwift observer type.
     public var state: Observable<RS> {
         return _state.asObservable()
     }
     public var _sideEffects: BehaviorRelay<R.SE?>
     /// support RxSwift observer type.
     public var sideEffects: Observable<R.SE?> {
         return _sideEffects.asObservable().observe(on: MainScheduler.instance)
     }
     */
//}
