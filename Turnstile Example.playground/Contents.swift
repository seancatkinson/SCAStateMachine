//: Playground - noun: a place where people can play

func lock() {
    print("Locking")
}
func unlock() {
    print("Unlocking")
}

enum TurnstileState {
    case Locked
    case Unlocked
}

let stateMachine = StateMachine(initialState: TurnstileState.Locked)

stateMachine.performAfterChangingTo([.Locked]) { _,_,_ in lock() }
stateMachine.performAfterChangingTo([.Unlocked]) { _,_,_ in unlock() }

stateMachine.addStateTransition(named: "Coin", from: [.Locked], to: .Unlocked)
stateMachine.addStateTransition(named: "Push", from: [.Unlocked], to: .Locked)

do {
    let destinationState = try stateMachine.canPerformTransition(named:"Coin")
    // do something with the destination state
}
catch {
    // catch UnspportedStateChange/NoTransitionMatchingName/Custom Errors
}

do {
    try stateMachine.performTransition(named:"Coin")
    print(stateMachine.currentState)
    try stateMachine.performTransition(named: "Push")
    print(stateMachine.currentState)
}
catch {
    // catch UnspportedStateChange/NoTransitionMatchingName/Custom Errors
}
