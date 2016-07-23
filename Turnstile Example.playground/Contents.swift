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

enum TurnstileEvent : String {
    case Push
    case Coin
}


let stateMachine = StateMachine(startingOn: TurnstileState.Locked)

stateMachine.performAfterChangingTo(.Locked) { _,_,_ in lock() }
stateMachine.performAfterChangingTo(.Unlocked) { _,_,_ in unlock() }

stateMachine.addStateTransition(named: "Coin", to: .Unlocked, from: .Locked)
stateMachine.addStateTransition(named: "Push", to: .Locked, from: .Unlocked)

do {
    let destinationState = try stateMachine.canPerformTransition(named:"Coin")
    // do something with the destination state
}
catch {
    // catch UnspportedStateChange/NoTransitionMatchingName/Custom Errors
}

do {
    try stateMachine.performTransition(named:"Coin")
}
catch {
    // catch UnspportedStateChange/NoTransitionMatchingName/Custom Errors
}
