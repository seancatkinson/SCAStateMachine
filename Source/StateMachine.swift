//  StateMachine.swift
//  SCAStateMachine
//
//  Copyright (c) 2015 SeanCAtkinson (http://seancatkinson.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

public class StateMachine <T where T: Equatable, T: Hashable>
{
    typealias beforeChangeAction = (newState:T, userInfo:Any?)->()
    typealias afterChangeAction = (oldState:T, userInfo:Any?)->()
    typealias beforeChangeActionCollection = Dictionary<T, beforeChangeAction>
    typealias afterChangeActionCollection = Dictionary<T, afterChangeAction>
    
// MARK:- state vars
    private var _currentState : T
    public var currentState : T {
        return _currentState
    }
    
    private var _stateChanges : [StateChange<T>] = []
    
    private var _activated : Bool = false
    public var activated : Bool {
        return _activated
    }
    
// MARK:- state actions
    private var _willMoveToStateActions : Dictionary<T, beforeChangeAction> = [:]
    private var _willMoveFromStateActions : Dictionary<T, beforeChangeAction> = [:]
    private var _didMoveToStateActions : Dictionary<T, afterChangeAction> = [:]
    private var _didMoveFromStateActions : Dictionary<T, afterChangeAction> = [:]
    
// MARK:- Public Methods
/**
    Initialises a state machine with an initial state
    
    :param: withInitialState the initial state of the StateMachine
    
    :returns: the state Machine
*/
    public init(withInitialState initialState: T) {
        _currentState = initialState
    }
    
/**
    Check if the state machine can change to a specific state
    
    :param: state the state you want to check
    
    :returns: a bool success value
*/
    public func canChangeToState(newState: T) -> Bool {
        for change in _stateChanges {
            if change.destinationState == newState {
                if change.startingStates.contains(_currentState) {
                    return true
                }
            }
        }
        return false
    }
    
/**
    Change the state machine to a new state, passing through some extra information if desired.
    Throws a StateMachineError.StateMachineNotActivated error if the state machine has not yet been activated.
    Throws a StateMachineError.UnsupportedStateChange error if a StateChange rule has not been defined for
    the state change you attempted.
    
    Will perform the state change actions in the following order -
    - willMoveToState
    - willMoveFromState
    - didMoveToState
    - didMoveFromState
    
    :param: state the state you want to change to
    :param: userInfo any extra info you want to pass to your State change actions
*/
    public func changeToState(newState: T, userInfo:Any?) throws {
        guard _activated == true else {
            throw StateMachineError.StateMachineNotActivated
        }
        guard canChangeToState(newState) else {
            throw StateMachineError.UnsupportedStateChange
        }
        
        let oldState = _currentState
        if let willMoveToAction = _willMoveToStateActions[newState] {
            willMoveToAction(newState: newState, userInfo: userInfo)
        }
        if let willMoveFromAction = _willMoveFromStateActions[oldState] {
            willMoveFromAction(newState: newState, userInfo: userInfo)
        }
        _currentState = newState
        if let didMoveToAction = _didMoveToStateActions[newState] {
            didMoveToAction(oldState: oldState, userInfo: userInfo)
        }
        if let didMoveFromAction = _didMoveFromStateActions[oldState] {
            didMoveFromAction(oldState: oldState, userInfo: userInfo)
        }
    }
    
/**
    Activate the state machine by allowing state changes and preventing any further state change rules 
    from being added
*/
    public func activate() {
        _activated = true
    }
    
/**
    Add a state change rule to allow changing to a specific state from a list of other states. Throws
    a StateMachineError.StateMachineActivated error if the state machine as already been activated
    
    :param: destinationState the state you want to allow movement to
    :param: fromStartingStates a list of states that will allow moving to the destinationState
*/
    public func addStateChangeTo(destinationState: T, fromStartingStates: T...) throws {
        guard _activated == false else {
            throw StateMachineError.StateMachineActivated
        }
        let change = StateChange(withDestinationState: destinationState, fromStartingStates: fromStartingStates)
        if !_stateChanges.contains(change) {
            _stateChanges.append(change)
        }
    }
    
// MARK: State Change Actions
    
/**
    Set a block to be executed before the state machine changes to a specific state. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: newState the state to add the action for
    :param: perform the block to be executed when the state machine will change to the provided state
*/
    public func beforeChangingToState(newState: T, perform:beforeChangeAction) throws {
        guard _activated == false else {
            throw StateMachineError.StateMachineActivated
        }
        
        _willMoveToStateActions[newState] = perform
    }
    
/**
    Set a block to be executed before the state machine changes from a specific state. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: oldState the state to add the action for
    :param: perform the block to be executed when the state machine will change from the provided state
*/
    public func beforeChangingFromState(oldState: T,  perform:beforeChangeAction) throws {
        guard _activated == false else {
            throw StateMachineError.StateMachineActivated
        }
        
        _willMoveFromStateActions[oldState] = perform
    }
    
/**
    Set a block to be executed after the state machine changes to a specific state. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: newState the state to add the action for
    :param: perform the block to be executed when the state machine did change to the provided state
*/
    public func afterChangingToState(newState: T, perform:afterChangeAction) throws {
        guard _activated == false else {
            throw StateMachineError.StateMachineActivated
        }
        
        _didMoveToStateActions[newState] = perform
    }
    
/**
    Set a block to be executed after the state machine changes from a specific state. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: oldState the state to add the action for
    :param: perform the block to be executed when the state machine did change from the provided state
*/
    public func afterChangingFromState(oldState: T, perform:afterChangeAction) throws {
        guard _activated == false else {
            throw StateMachineError.StateMachineActivated
        }
        
        _didMoveFromStateActions[oldState] = perform
    }
}

// MARK:- StateChange Definition
struct StateChange <T where T:Equatable> {
    var destinationState : T
    var startingStates : [T] = []
    
    init(withDestinationState: T, fromStartingStates: [T]) {
        destinationState = withDestinationState
        startingStates = fromStartingStates
    }
    
    init(withDestinationState: T, fromStartingStates: T...) {
        self.init(withDestinationState: withDestinationState, fromStartingStates: fromStartingStates)
    }
}

extension StateChange : Equatable {}

func ==<T where T:Equatable>(lhs:StateChange<T>, rhs:StateChange<T>) -> Bool {
    return lhs.destinationState != rhs.destinationState && lhs.startingStates == rhs.startingStates
}


// MARK:- Errors
@objc enum StateMachineError: Int, ErrorType {
    case UnsupportedStateChange
    case StateMachineActivated
    case StateMachineNotActivated
}