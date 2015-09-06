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
        self._currentState = startingState
    }
    
/**
    Check if the state machine can change to a specific state. 
    Checks if rules have been set, with no rules, all changes are allowed.
    Checks conditions for from and to states.
    Rethrows errors thrown by condition statements
    
    :param: state the state you want to check
    :param: userInfo any extra info you want to pass to your State change actions
*/
    public func canChangeToState(destinationState: T, userInfo:Any?=nil) throws {
        guard self.currentState != destinationState else {
            throw StateMachineError.AlreadyInRequestedState
        }
        
        let stateChangeExists = self.stateChangeExistsForStartingState(_currentState, destinationState: destinationState)
        guard stateChangeExists == true else {
            throw StateMachineError.UnsupportedStateChange
        }
        
        let fromConditions = self._willChangeFromStateConditions[_currentState]
        try self.allConditionsPass(fromConditions, forStartingState: _currentState, destinationState: destinationState, withUserInfo: userInfo)
            
        let toConditions = self._willChangeToStateConditions[destinationState]
        try self.allConditionsPass(toConditions, forStartingState: _currentState, destinationState: destinationState, withUserInfo: userInfo)
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
        guard self._stateChanges.count > 0 else {
            return true
        }
        
        return self._stateChanges.filter { (rule) -> Bool in
            return rule.destinationStates.contains(destinationState) &&
                rule.startingStates.contains(startingState)
        }.count > 0
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
    If no state change rules have been defined, all state changes are allowed. Throws a StateMachineError.UnsupportedStateChange error if a state change rules have been defined but not one for the requested change.
    If you attempt to change to a 3rd state inside a handler for a change to a 2nd state, and the change succeeds, no further closures will be performed for the original state change.
    
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
        try self.canChangeToState(destinationState, userInfo: userInfo)
        
        let startingState = self.currentState
        
        // will Change actions
        if let willChangeStateAction = self._willChangeStateAction {
            willChangeStateAction(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
            if self.currentState != startingState {
                return
            }
        }
        
        if let willChangeFromAction = self._willChangeFromStateActions[startingState] {
            willChangeFromAction(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
            if  self.currentState != startingState {
                return
            }
        }
        if let willChangeToAction = self._willChangeToStateActions[destinationState] {
            willChangeToAction(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
            if self.currentState != startingState {
                return
            }
        }
        
        self._currentState = destinationState
        
        // did change actions
        if let didChangeToAction = self._didChangeToStateActions[destinationState] {
            didChangeToAction(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
            if self.currentState != destinationState {
                return
            }
        }
        if let didChangeFromAction = self._didChangeFromStateActions[startingState] {
            didChangeFromAction(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
            if self.currentState != destinationState {
                return
            }
        }
        if let didChangeStateAction = self._didChangeStateAction {
            didChangeStateAction(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
        }
    }
    
    
    func addStateChangeRulesFrom(startingStates: [T], toDestinationStates: [T]) {
        let change = StateChange(withDestinationStates: toDestinationStates, fromStartingStates: startingStates)
        if !_stateChanges.contains(change) {
            _stateChanges.append(change)
        }
    }
    
/**
    Add a state change rule to allow changing to a specific state from a list of other states.
    
    :param: destinationState the state you want to allow movement to
    :param: fromStartingStates a list of states that will allow moving to the destinationState
*/
    public func addStateChangeRulesTo(destinationState: T, fromStartingStates: T...) {
        self.addStateChangeRulesFrom(fromStartingStates, toDestinationStates: [destinationState])
    }
    
/**
    Add a state change rule to allow changing to a list of states from a specific state.

    :param: destinationStates the list of states you want to allow movement to
    :param: fromStartingStates a state that will allow moving to the destinationStates
*/
    public func addStateChangeRulesTo(destinationStates:T..., fromStartingState: T) {
        self.addStateChangeRulesFrom([fromStartingState], toDestinationStates: destinationStates)
    }
    
/**
    Add a state change rule to allow changing to a specific state from a list of other states.
    
    :param: toDestinationState the state you want to allow movement to
    :param: startingStates a list of states that will allow moving to the destinationState
*/
    public func addStateChangeRulesFrom(startingStates: T..., toDestinationState: T) {
        self.addStateChangeRulesFrom(startingStates, toDestinationStates: [toDestinationState])
    }
    
/**
    Add a state change rule to allow changing to a list of states from a specific state.
    
    :param: destinationStates the list of states you want to allow movement to
    :param: fromStartingStates a state that will allow moving to the destinationStates
*/
    public func addStateChangeRulesFrom(startingState: T, toDestinationStates: T...) {
        self.addStateChangeRulesFrom([startingState], toDestinationStates: toDestinationStates)
    }
    
    
    
/**
    Add a block to be performed before attempting to change from a set of 
    states. If the block throws, the state change will fail and the thrown error
    will bubble up to the caller.
    Multiple blocks can be added for any given state and will be performed in 
    the order they are added. If no conditions exist and the change is valid, 
    the change will succeed.
    
    :param: closure the block to perform
    :param: states the states to add the condition for
*/
    public func addStateChangeCondition(closure:changeCondition, forStartingStates states: T...) {
        for state in states {
            var stateConditionsArray:[changeCondition]!  = self._willChangeFromStateConditions[state] ?? []
            stateConditionsArray.append(closure)
            self._willChangeFromStateConditions[state] = stateConditionsArray
        }
    }
    
/**
    Add a block to be performed before attempting to change to a set of
    states. If the block throws, the state change will fail and the thrown error
    will bubble up to the caller.
    Multiple blocks can be added for any given state and will be performed in
    the order they are added. If no conditions exist and the change is valid,
    the change will succeed.
    
    :param: closure the block to perform
    :param: states the states to add the condition for
*/
    public func addStateChangeCondition(closure:changeCondition, forDestinationStates states: T...) {
        for state in states {
            var stateConditionsArray:[changeCondition]!  = self._willChangeToStateConditions[state] ?? []
            stateConditionsArray.append(closure)
            self._willChangeToStateConditions[state] = stateConditionsArray
        }
    }
    
// MARK: State Change Actions
    
/**
    Set a block to be executed before the state machine changes to any other state. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: closure the block to be executed when the state machine will change to the provided state
*/
    public func perform(beforeChanging closure:changeAction) {
        self._willChangeStateAction = closure
    }
    
/**
    Set a block to be executed after the state machine changes to any other state. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: closure the block to be executed when the state machine did change to the provided state
*/
    public func perform(afterChanging closure:changeAction) {
        self._didChangeStateAction = closure
    }
    
/**
    Set a block to be executed before the state machine changes to a set of specific states. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: closure the block to be executed when the state machine will change to the provided states
    :param: states the states to add the action for
*/
    public func perform(closure:changeAction, beforeChangingToStates states: T...) {
        for state in states {
            self._willChangeToStateActions[state] = closure
        }
    }
    
/**
    Set a block to be executed before the state machine changes from a set of specific states. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: closure the block to be executed when the state machine will change from the provided states
    :param: states the states to add the action for
*/
    public func perform(closure:changeAction, beforeChangingFromStates states: T...) {
        for state in states {
            self._willChangeFromStateActions[state] = closure
        }
    }
    
/**
    Set a block to be executed after the state machine changes to a set of specific states. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: closure the block to be executed when the state machine did change to the provided states
    :param: states the states to add the action for
*/
    public func perform(closure:changeAction, afterChangingToStates states: T...) {
        for state in states {
            self._didChangeToStateActions[state] = closure
        }
    }
    
/**
    Set a block to be executed after the state machine changes from a set of specific states. Throws a
    StateMachineError.StateMachineActivated error if the state machine has been activated
    
    :param: closure the block to be executed when the state machine did change from the provided states
    :param: states the states to add the action for
*/
    public func perform(closure:changeAction, afterChangingFromStates states: T...) {
        for state in states {
            self._didChangeFromStateActions[state] = closure
        }
    }
}

// MARK:- StateChange Definition
struct StateChange <T where T:Equatable> {
    var destinationStates : [T] = []
    var startingStates : [T] = []
    
    init(withDestinationStates: [T], fromStartingStates: [T]) {
        self.destinationStates = withDestinationStates
        self.startingStates = fromStartingStates
    }
}

extension StateChange : Equatable {}

func ==<T where T:Equatable>(lhs:StateChange<T>, rhs:StateChange<T>) -> Bool {
    return lhs.destinationStates != rhs.destinationStates && lhs.startingStates == rhs.startingStates
}


// MARK:- Errors
@objc public enum StateMachineError: Int, CustomStringConvertible, ErrorType {
    case UnsupportedStateChange
    case AlreadyInRequestedState
    
    public var description : String {
        switch self {
        case .UnsupportedStateChange:
            return "Unsupported State Change"
        case .AlreadyInRequestedState:
            return "Already In Requested State"
        }
    }
}