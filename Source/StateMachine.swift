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

public class StateMachine <T where T: Hashable>
{
    public typealias changeCondition = (destinationState:T, startingState:T, userInfo:Any?) throws -> ()
    public typealias changeAction = (destinationState:T, startingState:T, userInfo:Any?)->()
    typealias changeActionTuple = (queue:dispatch_queue_t?, action:changeAction)
    
// MARK: - Dispatch Queues
    private let machineQueue = dispatch_queue_create("com.seancatkinson.SCAStateMachine.MachineQueue", DISPATCH_QUEUE_CONCURRENT)
    private let targetQueue : dispatch_queue_t
    
// MARK:- state vars
    private var _currentState : T
/**
    - Returns: the current state of the State Machine
*/
    public var currentState : T {
        var state : T?
        dispatch_sync(self.machineQueue) { state = self._currentState }
        return state!
    }
    
/**
    Array of state change rules
*/
    private var _stateChangeRules : [StateChange<T>] = []
    
/**
    Dictionary of state transitions
*/
    private var _stateTransitions : [String:StateTransition<T>] = [:]
    
// MARK:- state change conditions
    private var _willChangeFromStateConditions : Dictionary<T, [changeCondition]> = [:]
    private var _willChangeToStateConditions : Dictionary<T, [changeCondition]> = [:]

// MARK:- state change actions
    private var _didChangeToStateActions : Dictionary<T, changeActionTuple> = [:]
    private var _didChangeFromStateActions : Dictionary<T, changeActionTuple> = [:]
    private var _didChangeStateAction: changeActionTuple?
    
// MARK:- Initialisation
/**
    Initialises a state machine with an initial state
    
    - Parameter withInitialState: the initial state of the StateMachine
    
    - Returns: the state Machine
*/
    public init(withStartingState startingState: T, targetQueue : dispatch_queue_t = dispatch_get_main_queue()) {
        self._currentState = startingState
        self.targetQueue = targetQueue
    }
    
// MARK: - State Change Execution Checks
/**
    Check if the state machine can change to a specific state. 
    Checks if rules have been set, with no rules, all changes are allowed.
    Checks conditions for from and to states.
    Rethrows errors thrown by condition statements
    
    - Parameter state: the state you want to check
    - Parameter userInfo: any extra info you want to pass to your State change actions
*/
    public func canChangeToState(destinationState: T, userInfo:Any?=nil) throws {
        var error : ErrorType?
        
        dispatch_sync(self.machineQueue) {
            do {
                guard self._currentState != destinationState else {
                    throw StateMachineError.AlreadyInRequestedState
                }
                
                let stateChangeExists = self.stateChangeExistsForStartingState(self._currentState, destinationState: destinationState)
                guard stateChangeExists == true else {
                    throw StateMachineError.UnsupportedStateChange
                }
                
                let fromConditions = self._willChangeFromStateConditions[self._currentState]
                try self.allConditionsPass(fromConditions, forStartingState: self._currentState, destinationState: destinationState, withUserInfo: userInfo)
                
                let toConditions = self._willChangeToStateConditions[destinationState]
                try self.allConditionsPass(toConditions, forStartingState: self._currentState, destinationState: destinationState, withUserInfo: userInfo)
            }
            catch let thrownError {
                error = thrownError
            }
        }
        
        if let error = error {
            throw error
        }
    }
    
/**
    Check if the state machine can perform a transition registered to the 
    provided name.
    Checks if rules have been set, with no rules, all changes are allowed.
    Checks conditions for from and to states.
    Rethrows errors thrown by condition statements
    
    - Parameter state: the state you want to check
    - Parameter userInfo: any extra info you want to pass to your State change actions
    
    
    
    - Returns: the state that the transition will move to
*/
    public func canPerformTransition(named name:String, userInfo:Any?=nil) throws -> T {
        var destinationState : T?
        
        do {
            var error : ErrorType?
            var maybeTransition : StateTransition<T>?
            
            dispatch_sync(self.machineQueue) {
                maybeTransition = self._stateTransitions[name]
                
                guard let transition = maybeTransition else {
                    error = StateMachineError.NoTransitionMatchingName(name)
                    return
                }
                
                destinationState = transition.stateChange.destinationStates.first
                
                guard destinationState != nil else {
                    error = StateMachineError.InvalidStateMachineSetup
                    return
                }
            }
            
            guard error == nil else {
                throw error!
            }
        }
        catch let thrownError {
            throw thrownError
        }
        
        try self.canChangeToState(destinationState!, userInfo: userInfo)
        
        return destinationState!
    }
    
/**
    Checks whether a state change rule has been defined for a given starting
    state and destination state. 
    Returns true if no state changes have been defined.
    
    - Parameter startingState: the state the statemachine will be in before a change
    - Parameter destinationState: the state the statemachine will be in after a change
    
    - Returns: a bool success value
*/
    func stateChangeExistsForStartingState(startingState:T, destinationState:T) -> Bool {
        guard self._stateChangeRules.count > 0 else {
            return true
        }
        
        return self._stateChangeRules.filter { (rule) -> Bool in
            return rule.destinationStates.contains(destinationState) &&
                rule.startingStates.contains(startingState)
        }.count > 0
    }
    
/**
    Executes each closure in an array of closures that add conditions for 
    whether a a particular state change should be actioned.
    
    - Parameter conditions: the array of condition closures to execute
    - Parameter forStartingState: the state the statemachine will be in before a change
    - Parameter destinationState:
    - Parameter withUserInfo:
*/
    func allConditionsPass(conditions:[changeCondition]?, forStartingState startingState:T, destinationState:T, withUserInfo userInfo:Any?=nil) throws {
        if let conditions = conditions {
            for condition in conditions {
                try condition(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
            }
        }
    }
    
// MARK: State Change Execution
    
    // change the state and perform the stored actions
    func performStateChangeActionsFor(startingState: T, destinationState: T, userInfo:Any? = nil) {
        dispatch_barrier_async(self.machineQueue) {
            
            self._currentState = destinationState
            
            // did change actions
            if let didChangeToActionTuple = self._didChangeToStateActions[destinationState] {
                dispatch_async(didChangeToActionTuple.queue ?? self.targetQueue) {
                    didChangeToActionTuple.action(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
                }
            }
            if let didChangeFromActionTuple = self._didChangeFromStateActions[startingState] {
                dispatch_async(didChangeFromActionTuple.queue ?? self.targetQueue) {
                    didChangeFromActionTuple.action(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
                }
            }
            if let didChangeStateActionTuple = self._didChangeStateAction {
                dispatch_async(didChangeStateActionTuple.queue ?? self.targetQueue) {
                    didChangeStateActionTuple.action(destinationState: destinationState, startingState: startingState, userInfo: userInfo)
                }
            }
        }
    }
    
/**
    Asynchronously change the state machine to a new state, passing through some
    extra information if desired.
    Error Checking is performed synchronously before the change is attempted
    If no state change rules have been defined, all state changes are allowed.
    
    If you attempt to change to a 3rd state inside a handler for a change to a 
    2nd state, all handlers of the original transition will still be performed 
    first.
    
    Will perform the state change actions in the following order -
    - didChangeToState
    - didChangeFromState
    - didChangeState
    
    - Parameter state: the state you want to change to
    - Parameter userInfo: any extra info you want to pass to your State change actions
    
    - Throws: 
        - `StateMachineError.UnsupportedStateChange` if state change rules
    have been defined but not one for the requested change.
        - `<Your Error Here>` if you throw from any of the conditions you
    have defined matching this state change
*/
    public func changeToState(destinationState: T, userInfo:Any?=nil) throws {
        // this will dispatch_sync for us
        try self.canChangeToState(destinationState, userInfo: userInfo)
        
        // this will dispatch_barrier_async for us
        self.performStateChangeActionsFor(self._currentState, destinationState: destinationState, userInfo: userInfo)
    }
    
/**
    Perform a registered transition to asynchronously change the state machine 
    to a new state, passing through some extra information if desired.
    Error Checking is performed synchronously before the change is attempted
    If no state change rules have been defined, all state changes are allowed. 
    Throws a StateMachineError.UnsupportedStateChange error if a state change rules have been defined but not one for the requested change.
    If you attempt to change to a 3rd state inside a handler for a change to a 2nd state, all handlers of the original transition will still be performed first
    
    Will perform the state change actions in the following order -
    - didChangeToState
    - didChangeFromState
    - didChangeState
    
    - Parameter state: the state you want to change to
    - Parameter userInfo: any extra info you want to pass to your State change actions
*/
    public func performTransition(named name:String, userInfo:Any?=nil) throws {
        // this will dispatch_sync for us
        let destinationState = try self.canPerformTransition(named: name)
        
        // this will dispatch_barrier_async for us
        self.performStateChangeActionsFor(self._currentState, destinationState: destinationState, userInfo: userInfo)
    }
    
    
    
// MARK: - Add State Change Rules
    
    // Base Helper method to add state change rules
    func addStateChangeRulesFrom(startingStates: [T], toDestinationStates: [T]) {
        dispatch_barrier_async(self.machineQueue) {
            let change = StateChange(withDestinationStates: toDestinationStates, fromStartingStates: startingStates)
            if !self._stateChangeRules.contains(change) {
                self._stateChangeRules.append(change)
            }
        }
    }
    
/**
    Add a state change rule to allow changing to a specific state from a list of other states.
    
    - Parameter destinationState: the state you want to allow movement to
    - Parameter fromStartingStates: a list of states that will allow moving to the destinationState
*/
    public func addStateChangeRulesTo(destinationState: T, fromStartingStates: T...) {
        self.addStateChangeRulesFrom(fromStartingStates, toDestinationStates: [destinationState])
    }
    
/**
    Add a state change rule to allow changing to a list of states from a specific state.

    - Parameter destinationStates: the list of states you want to allow movement to
    - Parameter fromStartingStates: a state that will allow moving to the destinationStates
*/
    public func addStateChangeRulesTo(destinationStates:T..., fromStartingState: T) {
        self.addStateChangeRulesFrom([fromStartingState], toDestinationStates: destinationStates)
    }
    
/**
    Add a state change rule to allow changing to a specific state from a list of other states.
    
    - Parameter toDestinationState: the state you want to allow movement to
    - Parameter startingStates: a list of states that will allow moving to the destinationState
*/
    public func addStateChangeRulesFrom(startingStates: T..., toDestinationState: T) {
        self.addStateChangeRulesFrom(startingStates, toDestinationStates: [toDestinationState])
    }
    
/**
    Add a state change rule to allow changing to a list of states from a specific state.
    
    - Parameter destinationStates: the list of states you want to allow movement to
    - Parameter fromStartingStates: a state that will allow moving to the destinationStates
*/
    public func addStateChangeRulesFrom(startingState: T, toDestinationStates: T...) {
        self.addStateChangeRulesFrom([startingState], toDestinationStates: toDestinationStates)
    }
    
// MARK: Add Named State Transition & State Change Rules
    
/**
    Add a named state change rule to allow changing to a specific state from a list of other states.
    Use the name in performTransition(named:<name>) to try the change

    - Parameter named: the name of the transition
    - Parameter toDestinationState: the state you want to allow movement to
    - Parameter startingStates: a list of states that will allow moving to the destinationState
*/
    public func addStateTransition(named name:String, toDestinationState:T, fromStartingStates: T...) {
        dispatch_barrier_async(self.machineQueue) {
            let transition = StateTransition(named: name, withDestinationState: toDestinationState, fromStartingStates: fromStartingStates)
            self._stateTransitions[name] = transition
            self.addStateChangeRulesFrom(fromStartingStates, toDestinationStates: [toDestinationState])
        }
    }
    
    
// MARK: - State Change Conditions
    
/**
    Add a block to be performed before attempting to change from a set of 
    states. If the block throws, the state change will fail and the thrown error
    will bubble up to the caller.
    Multiple blocks can be added for any given state and will be performed in 
    the order they are added. If no conditions exist and the change is valid, 
    the change will succeed.
    
    - Parameter states: the states to add the condition for
    - Parameter closure: the block to perform
*/
    public func checkConditionBeforeChangingFrom(states: T..., _ closure:changeCondition) {
        dispatch_barrier_async(self.machineQueue) {
            for state in states {
                var stateConditionsArray:[changeCondition]!  = self._willChangeFromStateConditions[state] ?? []
                stateConditionsArray.append(closure)
                self._willChangeFromStateConditions[state] = stateConditionsArray
            }
        }
    }
    
/**
    Add a closure to be performed before attempting to change to a set of
    states. If the block throws, the state change will fail and the thrown error
    will bubble up to the caller.
    Multiple blocks can be added for any given state and will be performed in
    the order they are added. If no conditions exist and the change is valid,
    the change will succeed.
    
    - Parameter states: the states to add the condition for
    - Parameter closure: the block to perform
*/
    public func checkConditionBeforeChangingTo(states: T..., _ closure:changeCondition) {
        dispatch_barrier_async(self.machineQueue) {
            for state in states {
                var stateConditionsArray:[changeCondition]!  = self._willChangeToStateConditions[state] ?? []
                stateConditionsArray.append(closure)
                self._willChangeToStateConditions[state] = stateConditionsArray
            }
        }
    }
    
// MARK: - State Change Actions
    
/**
    Set a block to be executed after the state machine changes to any other state.
    
    - Parameter closure: the block to be executed when the state machine did change to the provided state
*/
    public func performAfterChanging(onQueue queue:dispatch_queue_t? = nil, closure:changeAction) {
        dispatch_barrier_async(self.machineQueue) {
            self._didChangeStateAction = (queue, closure)
        }
    }
    
/**
    Set a block to be executed after the state machine changes to a set of specific states.
    
    - Parameter closure: the block to be executed when the state machine did change to the provided states
    - Parameter states: the states to add the action for
*/
    public func performAfterChangingTo(states: T..., onQueue queue:dispatch_queue_t? = nil, closure:changeAction) {
        dispatch_barrier_async(self.machineQueue) {
            for state in states {
                self._didChangeToStateActions[state] = (queue, closure)
            }
        }
    }

/**
     Set a block to be executed after the state machine changes from a set of specific states.
     
     - Parameter states: the states to add the action for
     - Parameter closure: the block to be executed when the state machine did change from the provided states
*/
    public func performAfterChangingFrom(states: T..., onQueue queue:dispatch_queue_t? = nil, closure:changeAction) {
        dispatch_barrier_async(self.machineQueue) {
            for state in states {
                self._didChangeFromStateActions[state] = (queue, closure)
            }
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

// MARK: - State Change Event Definition
struct StateTransition <T where T:Equatable> {
    let name : String
    var stateChange : StateChange<T>
    
// MARK: Intialisation
    init(named name:String, withDestinationState: T, fromStartingStates: [T]) {
        self.name = name
        self.stateChange = StateChange(withDestinationStates: [withDestinationState], fromStartingStates: fromStartingStates)
    }
}


// MARK:- Errors
public enum StateMachineError: CustomStringConvertible, ErrorType {
    case UnsupportedStateChange
    case AlreadyInRequestedState
    case NoTransitionMatchingName(String)
    case InvalidStateMachineSetup
    
    public var description : String {
        switch self {
        case .UnsupportedStateChange:
            return "Attempted state change is not supported"
        case .AlreadyInRequestedState:
            return "Already in the state you're trying to change to"
        case .NoTransitionMatchingName(let name):
            return "You have not added a transition named: \(name)"
        case InvalidStateMachineSetup:
            return "Invalid State Machine Setup"
        }
    }
}