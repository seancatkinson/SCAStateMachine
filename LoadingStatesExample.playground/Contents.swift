//: Playground - noun: a place where people can play

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

let stateMachine = StateMachine(initialState: LoadingState.Ready)

// ready, loaded and error states can all move to .Loading
stateMachine.allowChangingTo(.Loading, from: [.Ready, .Loaded, .Error])

// .Loading states can move to both .Loaded and .Error states
stateMachine.allowChangingFrom(.Loading, to: [.Loaded, .Error])

// GATES: - Run a custom closure before a change is attempted to check if it should be allowed to go ahead
// Throw custom errors from these closures and they will be picked up later :)
stateMachine.checkConditionBeforeChangingTo([.Loaded]) { (destinationState, startingState, userInfo) -> () in
    if mySuccessCheck() == false {
        throw MyCustomError.CustomErrorOne
    }
}

// do something after changing to the .Error or .Loaded states
stateMachine.performAfterChangingTo([.Error, .Loaded]) { (destinationState, startingState, userInfo) -> () in
    print("We just moved to either .Error or .Loaded")
}

// do something after changing from the .loaded or .Error states
stateMachine.performAfterChangingFrom([.Error, .Loading]) { (destinationState, startingState, userInfo) -> () in
    print("We just moved from .Error or .Loading")
}

// do something after changing from any state
stateMachine.performAfterChanging { (destinationState, startingState, userInfo) -> () in
    print("I get performed after any and every change")
}


// check you can change before changing
do {
    try stateMachine.canChangeTo(.Loaded)
}
catch MyCustomError.CustomErrorOne {
    // throw your custom errors inside your conditions and handle them here
}
catch {
    // catch general errors
}

// or just attempt a change
do {
    try stateMachine.changeTo(.Loading, userInfo: nil) // succeeds
    try stateMachine.changeTo(.Loaded, userInfo: nil) // will check 'mySuccessCheck'
}
catch MyCustomError.CustomErrorOne {
    // handle your custom error case
}
catch {
    // handle a general error
}
