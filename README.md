# SCAStateMachine

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Docs 100%](https://img.shields.io/badge/docs-100%25-brightgreen.svg)]()

A lightweight state machine built in Swift for iOS & Mac OSX. For swift 3 see the swift3 branch.

## Features
- [x] Simple, readable API
- [x] Flexible - States can be of any type conforming to the Hashable protocol
- [x] Supports an arbitrary number of states and state changes
- [x] Block-based API
- [x] Several action points to customise when various blocks are executed
- [x] Pass arbitrary data to your state changes
- [x] Add 'gates' for more advanced customisation of allowed state changes
- [x] Basic Usage support to get going with minmal setup
- [x] Advanced Usage support to control which states can be changed to which states
- [x] Uses Swift 2.0 error mechanism for communicating issues
- [x] Lightweight - SCAStateMachine has no dependencies beyond Foundation
- [x] All methods documented and unit tested
- [x] Supports iOS, macOS, tvOS and watchOS

## Example Usage

### Classic Turnstile example

```swift
import SCAStateMachine

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
    let destinationState = try stateMachine.canPerformTransition(named:"Coin") // returns .Unlocked
    // do something with the destination state
}
catch {
    // catch UnspportedStateChange/NoTransitionMatchingName/Custom Errors
}

do {
    try stateMachine.performTransition(named:"Coin") // machine moves to .Unlocked state
}
catch {
    // catch UnspportedStateChange/NoTransitionMatchingName/Custom Errors
}
```

### Manual Usage - 

```swift
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

let stateMachine = StateMachine(startingOn: LoadingState.Ready)

// ready, loaded and error states can all move to .Loading
stateMachine.allowChangingTo(.Loading, from: .Ready, .Loaded, .Error)

// .Loading states can move to both .Loaded and .Error states
stateMachine.allowChangingFrom(.Loading, to: .Loaded, .Error)

// GATES: - Run a custom closure before a change is attempted to check if it should be allowed to go ahead
// Throw custom errors from these closures and they will be picked up later :)
stateMachine.checkConditionBeforeChangingTo(.Loaded) { (destinationState, startingState, userInfo) -> () in
    if mySuccessCheck() == false {
        throw MyCustomError.CustomErrorOne
    }
}

// do something after changing to the .Error or .Loaded states
stateMachine.performAfterChangingTo(.Error, .Loaded) { (destinationState, startingState, userInfo) -> () in
    print("We just moved to either .Error or .Loaded")
}

// do something after changing from the .loaded or .Error states
stateMachine.performAfterChangingFrom(.Error, .Loading) { (destinationState, startingState, userInfo) -> () in
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
    try stateMachine.changeToState(.Loading, userInfo: nil) // succeeds
    try stateMachine.changeToState(.Loaded, userInfo: nil) // will check 'mySuccessCheck'
}
catch MyCustomError.CustomErrorOne {
    // handle your custom error case
}
catch {
    // handle a general error
}
```

### Requirements
- iOS 8.1+ / Mac OS X 10.9+
- Xcode 7

### Installation

> **Embedded frameworks require a minimum deployment target of iOS 8 or OS X Mavericks.**
>
> To use SCAStateMachine with a project targeting iOS 7 or to include it manually, you must include the 'StateMachine.swift' file located inside the `Source` directory directly in your project

### CocoaPods

To integrate SCAStateMachine into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'SCAStateMachine', :git => 'https://github.com/seancatkinson/SCAStateMachine.git'
```

Once Cocoapods supports Swift 2.0 I'll submit as an actual pod.

## License

SCAStateMachine is released under the MIT license. See LICENSE for details.
