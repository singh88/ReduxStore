# ReduxSwift

This repo implements Redux architecture in Swift to enable RxSwift and Combine based applications to leverage unidirectional data flow. 

### Why
Redux talks about a single source of truth for state managment to avoid to many floating variable and boolean flags in various view model and view controllers. 

### Components
* State
* Action
* ActionHandler
* Reducer

#### State
A state where all computation for a state mutation takes place. State type encapsulate all the feature and app wide state values.

#### Action
Action type encapsulates all the events that can happen in the feature or app. For example, a screen can have a button and a label and button tap event is an action.

```

enum Action {
    case buttonTap
}

```

#### ActionHandler
ActionHandler type encapsulates the implemenation details for `Action` type. `ActionHandler` type takes care of making all the async calls for your feature.


#### Reducer
    

#### SideEffects




