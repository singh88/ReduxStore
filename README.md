# ReduxSwift

[Medium Blog](https://manishsingh-85983.medium.com/redux-swift-part-1-183262257d0d)

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
Action encapsulates all the events that can happen in the feature or app. For example, a screen can have a button and a label and button tap event is an action.

```

enum Action {
    case buttonTap
}

```

#### ActionHandler
ActionHandler encapsulates the implemenation details for `Action` type. `ActionHandler` type takes care of making all the async calls for your feature.


#### Reducer
Reducer is responsible for updating the state and generating any side effects after the state mutation. Reducer is accessible through store and it is only responsbile for driving it. Store then takes care of notifying the listerners of state and side effect mutation. SideEffects in case of a feature or app development could be anything that can drive a change in the experience.


#### SideEffects
SideEffects are similar to action but as the name suggessts its an effect or outcome of some action that happens for various reason ( user action, async calls etc. ).

