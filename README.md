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
The Reducer plays a pivotal role in updating the state and triggering any side effects following a state mutation. It is accessible via the store and exclusively manages the state's evolution. The store, in turn, handles the task of informing listeners about state changes and side effect alterations. Side effects, in the context of feature or app development, encompass anything capable of influencing a shift in the overall user experience.


#### SideEffects
Side effects, as the name implies, are outcomes or effects resulting from various actions. These effects can be triggered by different factors such as user interactions, asynchronous calls, or other events. Unlike a simple action, which typically represents an intent or change in the application state, a side effect refers to the broader consequences or results that occur due to an action, often extending beyond the immediate state change.

