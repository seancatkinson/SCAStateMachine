# SCAStateMachine

A lightweight state machine built in Swift for iOS & Mac OSX

## Features
- [x] Flexible - States can be of any type conforming to the Hashable protocol
- [x] Supports an arbitrary number of states and state changes
- [x] Block-based API
- [x] Several action points to customise when various blocks are executed
- [x] Pass arbitrary data to your state changes
- [x] Basic Usage support to get going with minmal setup
- [x] Advanced Usage support to control which states can be changed to which states
- [x] Uses Swift 2.0 error mechanism for communicating issues
- [x] Lightweight - SCAStateMachine has no dependencies beyond Foundation
- [x] All methods documented and unit tested

## Requirements
- iOS 7.0+ / Mac OS X 10.9+
- Xcode 7

## Installation

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

## Usage

### Basic Usage

```swift
import SCAStateMachine

enum AnimatingState {
case NotAnimating
case Animating
}

let stateMachine = StateMachine(withStartingState: AnimatingState.NotAnimating)

try! stateMachine.changeToState(.Animating, userInfo: nil)

if stateMachine.currentState == .Animating {
    // do something if we are currently animating
}
```

### Advanced Usage

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

let stateMachine = StateMachine(withStartingState: LoadingState.Ready)

stateMachine.addStateChangeRulesFrom(.Ready, .Loaded, .Error, toDestinationState: .Loading)
stateMachine.addStateChangeRulesFrom(.Loading, toDestinationStates: .Loaded, .Error)

stateMachine.checkConditionBeforeChangingTo(.Loaded) { (destinationState, startingState, userInfo) -> () in
    if mySuccessCheck() == false {
        throw MyCustomError.CustomErrorOne
    }
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
```

## License

SCAStateMachine is released under the MIT license. See LICENSE for details.
