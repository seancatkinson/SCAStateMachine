//: Playground - noun: a place where people can play

import SCAStateMachine






//func lock() {
//    print("Locking")
//}
//func unlock() {
//    print("Unlocking")
//}
//
//enum TurnstileState {
//    case Locked
//    case Unlocked
//}
//
//enum TurnstileEvent : String {
//    case Push
//    case Coin
//}
//
//
//let stateMachine = StateMachine(withStartingState: TurnstileState.Locked)
//
//stateMachine.performBeforeChangingTo(.Locked) { _,_,_ in lock() }
//stateMachine.performBeforeChangingTo(.Unlocked) { _,_,_ in unlock() }

/*

// register the transitions
stateMachine.registerTransitionsFrom(.Locked, to: .Unlocked, named:TurnstilEvent.Coin)
stateMachine.registerTransitionsFrom(.Unlocked, to: .Locked, named:TurnstilEvent.Push)

// check if a transition is possible
stateMachine.canPerformTransition("Push") // false
stateMachine.canPerformTransition("Coin") // true

// or just attempt to do it
do {
    try stateMachine.performTransition("Coin")
} 
catch {
    // we will catch this unsupported transition
}

// check the current state of the machine
stateMachine.currentState == .Unlocked // true


*/
