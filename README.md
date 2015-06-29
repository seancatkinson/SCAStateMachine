# SCAStateMachine

A lightweight state machine built in Swift for iOS & Mac OSX

## Features
- [x] Flexible - States can be of any type conforming to the Equatable & Hashable protocols
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

let stateMachine = StateMachine(withInitialState: AnimatingState.NotAnimating)
stateMachine.activate()

do {
  try! stateMachine.changeToState(.Animating, userInfo: nil)
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

let stateMachine = StateMachine(withInitialState: LoadingState.Ready)
do {
  try! stateMachine.addStateChangeTo(.Loading, fromStartingStates: .Ready, .Loaded, .Error)
  try! stateMachine.addStateChangeTo(.Loaded, fromStartingStates: .Loading)
  try! stateMachine.addStateChangeTo(.Error, fromStartingStates: .Loading)
  
  try! stateMachine.perform(beforeChanging: { (newState, oldState, userInfo) -> () in
      // do something before actioning any changes 
  })
  try! stateMachine.perform({ (newState, oldState, userInfo) -> () in
      // do something before changeing from the .Ready state
  }, beforeChangingFromStates: .Ready)
            
  try! stateMachine.perform({ (newState, oldState, userInfo) -> () in
      // do something before changing to the .Loading state
  }, beforeChangingToStates: .Loading)
            
  try! stateMachine.perform({ (newState, oldState, userInfo) -> () in
      // do something after changing to the .Error or .Loaded states
  }, afterChangingToStates: .Error, .Loaded)

  try! stateMachine.perform({ (newState, oldState, userInfo) -> () in
      // do something after changing from the .loaded or .Error states
  }, afterChangingFromStates: .Error, .Loading,)
            
  try! stateMachine.perform(afterChanging: { (newState, oldState, userInfo) -> () in
      // do something after changing from any state
  })
}
stateMachine.activate()

stateMachine.canChangeToState(.Loaded) // false
stateMachine.canChangeToState(.Loading) // true

do {
  try! stateMachine.changeToState(.Loading, userInfo: nil)
}
```

## License

SCAStateMachine is released under the MIT license. See LICENSE for details.
