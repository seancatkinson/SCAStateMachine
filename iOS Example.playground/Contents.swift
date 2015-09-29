//: Playground - noun: a place where people can play

import SCAStateMachine

enum LoadingState {
    case Ready
    case Loading
    case Loaded
    case Error
}

enum MyCustomError : ErrorType {
    case CustomErrorOne
}

func mySuccessCheck() -> Bool {
    return true
}

let stateMachine = StateMachine(withStartingState: LoadingState.Ready)

stateMachine.addStateChangeRulesFrom(.Ready, .Loaded, .Error, toDestinationState: .Loading)
stateMachine.addStateChangeRulesFrom(.Loading, toDestinationStates: .Loaded, .Error)

stateMachine.checkConditionBeforeChangingTo(.Loaded) { (destinationState, startingState, userInfo) -> () in
    if mySuccessCheck() == false {
        throw MyCustomError.CustomErrorOne
    }
}

stateMachine.performBeforeChanging { (destinationState, startingState, userInfo) -> () in
    // do something before actioning any changes
}

stateMachine.performBeforeChangingFrom(.Ready) { (destinationState, startingState, userInfo) -> () in
    // do something before changeing from the .Ready state
}
stateMachine.performBeforeChangingTo(.Loading) { (destinationState, startingState, userInfo) -> () in
    // do something before changing to the .Loading state
}

stateMachine.performAfterChangingTo(.Error, .Loaded) { (destinationState, startingState, userInfo) -> () in
    // do something after changing to the .Error or .Loaded states
}

stateMachine.performAfterChangingFrom(.Error, .Loading) { (destinationState, startingState, userInfo) -> () in
    // do something after changing from the .loaded or .Error states
}

stateMachine.performAfterChanging { (destinationState, startingState, userInfo) -> () in
    // do something after changing from any state
}


// check you can change before changing
do {
    try stateMachine.canChangeToState(.Loaded)
}
catch MyCustomError.CustomErrorOne {
    // throw your custom errors inside your conditions and handle them here
}
catch {
    // catch general errors
}

// or just attempt a change
do {
    try stateMachine.changeToState(.Loading, userInfo: nil) // succeeds
    try stateMachine.changeToState(.Loaded, userInfo: nil) // will check 'mySuccessCheck'
}
catch MyCustomError.CustomErrorOne {
    // handle your custom error case
}
catch {
    // handle a general error
}
