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
    public typealias changeCondition = (destinationState:T, startingState:T, userInfo:Any?) throws -> ()
    public typealias changeAction = (destinationState:T, startingState:T, userInfo:Any?)->()
    
// MARK:- state vars
    private var _currentState : T
/**
    Returns the current state of the State Machine
*/
    public var currentState : T {
        return _currentState
    }
    
/**
    Array of state change rules
*/
    private var _stateChanges : [StateChange<T>] = []
    
/**
    Private Boolean for whether the state machine has been activated
*/
    private var _activated : Bool = false
/**
    Boolean for whether the StateMachine has been activated
*/
    public var activated : Bool {
        return _activated
    }
    
/**
    Activate the state machine by allowing state changes and preventing any further state change rules
    from being added
*/
    public func activate() {
        _activated = true
    }
    
// MARK:- state actions
    private var _willChangeFromStateConditions : Dictionary<T, [changeCondition]> = [:]
    private var _willChangeToStateConditions : Dictionary<T, [changeCondition]> = [:]
    private var _willChangeToStateActions : Dictionary<T, changeAction> = [:]
    private var _willChangeFromStateActions : Dictionary<T, changeAction> = [:]
    private var _didChangeToStateActions : Dictionary<T, changeAction> = [:]
    private var _didChangeFromStateActions : Dictionary<T, changeAction> = [:]
    private var _willChangeStateAction: changeAction?
    private var _didChangeStateAction: changeAction?
    
// MARK:- Public Methods
/**
    Initialises a state machine with an initial state
    
    :param: withInitialState the initial state of the StateMachine
    
    :returns: the state Machine
*/
    public init(withStartingState startingState: T) {
        _currentState = startingState
    }
    
/**
    Check if the state machine can change to a specific state. 
    Checks if rules have been set, with no rules, all changes are allowed.
    Checks conditions for from and to states
    
    :param: state the state you want to check
    :param: userInfo any extra info you want to pass to your State change actions
    
    :returns: a bool success value
*/
    public func canChangeToState(destinationState: T, userInfo:Any?=nil) throws {
        let stateChangeExists = stateChangeExistsForStartingState(_currentState, destinationState: destinationState)
        guard stateChangeExists == true else {
            throw StateMachineError.UnsupportedStateChange
        }
        
        let fromConditions = _willChangeFromStateConditions[_currentState]
        try allConditionsPass(fromConditions, forStartingState: _currentState, destinationState: destinationState, withUserInfo: userInfo)
            
        let toConditions = _willChangeToStateConditions[destinationState]
        try allConditionsPass(toConditions, forStartingState: _currentState, destinationState: destinationState, withUserInfo: userInfo)
    }
    
/**
    Checks whether a state change rule has been defined for a given starting
    state and destination state. 
    Returns true if no state changes have been defined.
    
    :param: startingState the state the statemachine will be in before a change
    :param: destinationState the state the statemachine will be in after a change
    
    :returns: a bool success value
*/
    func stateChangeExistsForStartingState(startingState:T, destinationState:T) -> Bool {
        guard _stateChanges.count > 0 else {
            return true
        }
        
        for change in _stateChanges {
            if change.destinationState == destinationState {
                if change.startingStates.contains(startingState) {
                    return true
                }
            }
        }
        return false
    }
    
/**
    Executes each closure in an array of closures that add conditions for 
    whether a a particular state change should be actioned.
    
    :param: conditions the array of condition closures to execute
    :param: forStartingState the state the statemachine will be in before a change
    :param: destinationState
    :param: withUserInfo
*/
    func allConditionsPass(conditions:[changeCondition]?, forStartingState startingState:T, destinationState:T, withUserInfo userInfo:Any?=nil) throws {
        if let conditions = conditions {
            for condition in conditions {
                try condition(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
            }
        }
    }
    
/**
    Change the state machine to a new state, passing through some extra information if desired.
    Throws a StateMachineError.StateMachineNotActivated error if the state machine has not yet been activated.
    Throws a StateMachineError.UnsupportedStateChange error if a StateChange rule has not been defined for
    the state change you attempted.
    
    Will perform the state change actions in the following order -
    - willChangeState
    - willChangeFromState
    - willChangeToState
    - didChangeToState
    - didChangeFromState
    - didChangeState
    
    :param: state the state you want to change to
    :param: userInfo any extra info you want to pass to your State change actions
*/
    public func changeToState(destinationState: T, userInfo:Any?=nil) throws {
        guard _activated == true else {
            throw StateMachineError.StateMachineNotActivated
        }
        
        try canChangeToState(destinationState, userInfo: userInfo)
        
        let startingState = _currentState
        
        // will Change actions
        if let willChangeStateAction = _willChangeStateAction {
            willChangeStateAction(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
        }
        if let willChangeFromAction = _willChangeFromStateActions[startingState] {
            willChangeFromAction(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
        }
        if let willChangeToAction = _willChangeToStateActions[destinationState] {
            willChangeToAction(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
        }
        
        _currentState = destinationState
        
        // did change actions
        if let didChangeToAction = _didChangeToStateActions[destinationState] {
            didChangeToAction(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
        }
        if let didChangeFromAction = _didChangeFromStateActions[startingState] {
            didChangeFromAction(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
        }
        if let didChangeStateAction = _didChangeStateAction {
            didChangeStateAction(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
        }
    }
    
/**
    Add a state change rule to allow changing to a specific state from a list of other states. Throws
    a StateMachineError.StateMachineActivated error if the state machine has already been activated. If no 
    rules are set then all state changes are allowed.
    
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
    
    
/**
    Add a block to be performed before attempting to change from a set of 
    states. If the block returns false, the state change will fail.
    Multiple blocks can be added for any given state and will be performed in 
    the order they are added. If no conditions exist and the change is valid, 
    the change will succeed.
    
    :param: closure the block to perform
    :param: states the states to add the condition for
*/
    public func addStateChangeCondition(closure:changeCondition, forStartingStates states: T...) throws {
        guard _activated == false else {
            throw StateMachineError.StateMachineActivated
        }
        
        for state in states {
            var stateConditionsArray:[changeCondition]!  = _willChangeFromStateConditions[state] ?? []
            stateConditionsArray.append(closure)
            _willChangeFromStateConditions[state] = stateConditionsArray
        }
    }
    
/**
    Add a block to be performed before attempting to change to a set of
    states. If the block returns false, the state change will fail.
    Multiple blocks can be added for any given state and will be performed in
    the order they are added. If no conditions exist and the change is valid,
    the change will succeed.
    
    :param: closure the block to perform
    :param: states the states to add the condition for
*/
    public func addStateChangeCondition(closure:changeCondition, forDestinationStates states: T...) throws {
        guard _activated == false else {
            throw StateMachineError.StateMachineActivated
        }
        
        for state in states {
            var stateConditionsArray:[changeCondition]!  = _willChangeToStateConditions[state] ?? []
            stateConditionsArray.append(closure)
            _willChangeToStateConditions[state] = stateConditionsArray
        }
    }
    
// MARK: State Change Actions
    
/**
    Set a block to be executed before the state machine changes to any other state. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: closure the block to be executed when the state machine will change to the provided state
*/
    public func perform(beforeChanging closure:changeAction) throws {
        guard _activated == false else {
            throw StateMachineError.StateMachineActivated
        }
        
        _willChangeStateAction = closure
    }
    
/**
    Set a block to be executed after the state machine changes to any other state. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: closure the block to be executed when the state machine did change to the provided state
*/
    public func perform(afterChanging closure:changeAction) throws {
        guard _activated == false else {
            throw StateMachineError.StateMachineActivated
        }
        
        _didChangeStateAction = closure
    }
    
/**
    Set a block to be executed before the state machine changes to a set of specific states. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: closure the block to be executed when the state machine will change to the provided states
    :param: states the states to add the action for
*/
    public func perform(closure:changeAction, beforeChangingToStates states: T...) throws {
        guard _activated == false else {
            throw StateMachineError.StateMachineActivated
        }
        
        for state in states {
            _willChangeToStateActions[state] = closure
        }
    }
    
/**
    Set a block to be executed before the state machine changes from a set of specific states. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: closure the block to be executed when the state machine will change from the provided states
    :param: states the states to add the action for
*/
    public func perform(closure:changeAction, beforeChangingFromStates states: T...) throws {
        guard _activated == false else {
            throw StateMachineError.StateMachineActivated
        }
        
        for state in states {
            _willChangeFromStateActions[state] = closure
        }
    }
    
/**
    Set a block to be executed after the state machine changes to a set of specific states. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: closure the block to be executed when the state machine did change to the provided states
    :param: states the states to add the action for
*/
    public func perform(closure:changeAction, afterChangingToStates states: T...) throws {
        guard _activated == false else {
            throw StateMachineError.StateMachineActivated
        }
        
        for state in states {
            _didChangeToStateActions[state] = closure
        }
    }
    
/**
    Set a block to be executed after the state machine changes from a set of specific states. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: closure the block to be executed when the state machine did change from the provided states
    :param: states the states to add the action for
*/
    public func perform(closure:changeAction, afterChangingFromStates states: T...) throws {
        guard _activated == false else {
            throw StateMachineError.StateMachineActivated
        }
        
        for state in states {
            _didChangeFromStateActions[state] = closure
        }
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
@objc public enum StateMachineError: Int, ErrorType {
    case UnsupportedStateChange
    case StateMachineActivated
    case StateMachineNotActivated
}