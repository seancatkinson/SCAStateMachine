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


/// State machine object that tracks a single state at a time. Allows moving between states via transitions and manually.
open class StateMachine <T> where T: Hashable
{
// MARK: TypeAliases
    public typealias changeCondition = (_ destinationState:T, _ startingState:T, _ userInfo:Any?) throws -> ()
    public typealias changeAction = (_ destinationState:T, _ startingState:T, _ userInfo:Any?)->()
    typealias changeActionTuple = (queue:DispatchQueue?, action:changeAction)
    
// MARK: - Private State
    fileprivate let machineQueue = DispatchQueue(label: "com.seancatkinson.SCAStateMachine.MachineQueue", attributes: [])
    fileprivate let targetQueue : DispatchQueue
    
    /// PRIVATE: Array of state change rules
    fileprivate var _stateChangeRules : [StateChange<T>] = []
    
    /// PRIVATE: Dictionary of state transitions
    fileprivate var _stateTransitions : [String:StateTransition<T>] = [:]
    
    /// PRIVATE: state change conditions
    fileprivate var _willChangeFromStateConditions : Dictionary<T, [changeCondition]> = [:]
    fileprivate var _willChangeToStateConditions : Dictionary<T, [changeCondition]> = [:]

    /// PRIVATE: state change actions
    fileprivate var _didChangeToStateActions : Dictionary<T, changeActionTuple> = [:]
    fileprivate var _didChangeFromStateActions : Dictionary<T, changeActionTuple> = [:]
    fileprivate var _didChangeStateAction: changeActionTuple?
    
// MARK: Current State
    /// PRIVATE: The backing store for the current state of the machine
    fileprivate var _currentState : T
    
    
    /// The current state of the State Machine
    open var currentState : T {
        var state : T?
        self.machineQueue.sync { state = self._currentState }
        return state!
    }
    
// MARK: - Initialisation
/**
    Initialises a state machine with an initial state
    
    - Parameter initialState: the initial state of the StateMachine
    - Parameter targetQueue: OPTIONAL - the default queue for change actions to be performed on. Defaults to the main queue
    
    - Returns: the state Machine
*/
    public init(initialState: T, targetQueue : DispatchQueue = DispatchQueue.main) {
        self._currentState = initialState
        self.targetQueue = targetQueue
    }
    
// MARK: - Check state changes are available before making them
/**
    Check if the state machine can change to a specific state. 
    Checks if rules have been set, with no rules, all changes are allowed.
    Checks conditions for from and to states.
    Rethrows errors thrown by condition statements
    
    - Parameter destinationState: the state you want to check
    - Parameter userInfo: any extra info you want to pass to your State change actions
*/
    open func canChangeTo(_ destinationState: T, userInfo:Any?=nil) throws {
        var error : Error?
        
        self.machineQueue.sync {
            do {
                guard self._currentState != destinationState else {
                    throw StateMachineError.alreadyInRequestedState
                }
                
                let stateChangeExists = self.stateChangeExistsForStartingState(self._currentState, destinationState: destinationState)
                guard stateChangeExists == true else {
                    throw StateMachineError.unsupportedStateChange
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
    open func canPerformTransition(named name:String, userInfo:Any?=nil) throws -> T {
        var destinationState : T?
        
        do {
            var error : Error?
            var maybeTransition : StateTransition<T>?
            
            self.machineQueue.sync {
                maybeTransition = self._stateTransitions[name]
                
                guard let transition = maybeTransition else {
                    error = StateMachineError.noTransitionMatchingName(name)
                    return
                }
                
                destinationState = transition.stateChange.destinationStates.first
            }
            
            guard error == nil else {
                throw error!
            }
        }
        catch let thrownError {
            throw thrownError
        }
        
        try self.canChangeTo(destinationState!, userInfo: userInfo)
        
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
    func stateChangeExistsForStartingState(_ startingState:T, destinationState:T) -> Bool {
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
    func allConditionsPass(_ conditions:[changeCondition]?, forStartingState startingState:T, destinationState:T, withUserInfo userInfo:Any?=nil) throws {
        if let conditions = conditions {
            for condition in conditions {
                try condition(destinationState, startingState, userInfo)
            }
        }
    }
    
// MARK: Perform State Changes
    
    // change the state and perform the stored actions
    func performStateChangeActionsFor(_ startingState: T, destinationState: T, userInfo:Any? = nil) {
        self.machineQueue.async {
            
            self._currentState = destinationState
            
            // did change actions
            if let didChangeToActionTuple = self._didChangeToStateActions[destinationState] {
                (didChangeToActionTuple.queue ?? self.targetQueue).async {
                    didChangeToActionTuple.action(destinationState, startingState, userInfo)
                }
            }
            if let didChangeFromActionTuple = self._didChangeFromStateActions[startingState] {
                (didChangeFromActionTuple.queue ?? self.targetQueue).async {
                    didChangeFromActionTuple.action(destinationState, startingState, userInfo)
                }
            }
            if let didChangeStateActionTuple = self._didChangeStateAction {
                (didChangeStateActionTuple.queue ?? self.targetQueue).async {
                    didChangeStateActionTuple.action(destinationState, startingState, userInfo)
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
    open func changeTo(_ destinationState: T, userInfo:Any?=nil) throws {
        // this will dispatch_sync for us
        try self.canChangeTo(destinationState, userInfo: userInfo)
        
        // this will dispatch_async for us
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
    open func performTransition(named name:String, userInfo:Any?=nil) throws {
        // this will dispatch_sync for us
        let destinationState = try self.canPerformTransition(named: name)
        
        // this will dispatch_async for us
        self.performStateChangeActionsFor(self._currentState, destinationState: destinationState, userInfo: userInfo)
    }
    
    
    
// MARK: - Add State Change Rules
    
    // Base Helper method to add state change rules
    func addStateChangeRulesFrom(_ startingStates: [T], to destinationStates: [T]) {
        self.machineQueue.async {
            let change = StateChange(withDestinationStates: destinationStates, fromStartingStates: startingStates)
            if !self._stateChangeRules.contains(change) {
                self._stateChangeRules.append(change)
            }
        }
    }
    
/**
    Add a state change rule to allow changing to a specific state from a list of other states.
    
    - Parameter destinationState: the state you want to allow movement to
    - Parameter from: a list of states that will allow moving to the destinationState
*/
    open func allowChangingTo(_ destinationState: T, from startingStates: [T]) {
        guard startingStates.count > 0 else { return }
        
        self.addStateChangeRulesFrom(startingStates, to: [destinationState])
    }
    
/**
    Add a state change rule to allow changing to a list of states from a specific state.
    
    - Parameter startingState: a state that will allow moving to the destinationStates
    - Parameter to: the list of states you want to allow movement to
*/
    open func allowChangingFrom(_ startingState: T, to destinationStates: [T]) {
        guard destinationStates.count > 0 else { return }
        
        self.addStateChangeRulesFrom([startingState], to: destinationStates)
    }
    
/**
    Add a named state change rule to allow changing to a specific state from a list of other states.
    Use the name in performTransition(named:<name>) to try the change

    - Parameter named: the name of the transition
    - Parameter to: the state you want to allow movement to
    - Parameter from: a list of states that will allow moving to the destinationState
*/
    open func addStateTransition(named name:String, from startingStates: [T], to destinationState:T) {
        guard startingStates.count > 0 else { return }
        
        self.machineQueue.async {
            let transition = StateTransition(named: name, to: destinationState, from: startingStates)
            self._stateTransitions[name] = transition
            self.addStateChangeRulesFrom(startingStates, to: [destinationState])
        }
    }
    
    
// MARK: - Add state change conditions (Gates)
    
/**
    Add a block to be performed before attempting to change from a set of 
    states. If the block throws, the state change will fail and the thrown error
    will bubble up to the caller.
    Multiple blocks can be added for any given state and will be performed in 
    the order they are added. If no conditions exist and the change is valid, 
    the change will succeed.
    
    - Parameter states: an array of states to add the condition for
    - Parameter closure: the block to perform
*/
    open func checkConditionBeforeChangingFrom(_ states: [T], condition:@escaping changeCondition) {
        guard states.count > 0 else { return }
        
        self.machineQueue.async {
            for state in states {
                var stateConditionsArray:[changeCondition]!  = self._willChangeFromStateConditions[state] ?? []
                stateConditionsArray.append(condition)
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
    
    - Parameter states: an array of states to add the condition for
    - Parameter closure: the block to perform
*/
    open func checkConditionBeforeChangingTo(_ states: [T], condition:@escaping changeCondition) {
        guard states.count > 0 else { return }
        
        self.machineQueue.async {
            for state in states {
                var stateConditionsArray:[changeCondition]!  = self._willChangeToStateConditions[state] ?? []
                stateConditionsArray.append(condition)
                self._willChangeToStateConditions[state] = stateConditionsArray
            }
        }
    }
    
// MARK: - State Change Actions
    
/**
    Set a block to be executed after the state machine changes to any other state.
    
    - Parameter closure: the block to be executed when the state machine did change to the provided state
*/
    open func performAfterChanging(onQueue queue:DispatchQueue? = nil, closure:@escaping changeAction) {
        self.machineQueue.async {
            self._didChangeStateAction = (queue, closure)
        }
    }
    
/**
    Set a block to be executed after the state machine changes to a set of specific states.
    
    - Parameter closure: the block to be executed when the state machine did change to the provided states
    - Parameter states: the states to add the action for
*/
    open func performAfterChangingTo(_ states: [T], onQueue queue:DispatchQueue? = nil, closure:@escaping changeAction) {
        guard states.count > 0 else { return }
        
        self.machineQueue.async {
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
    open func performAfterChangingFrom(_ states: [T], onQueue queue:DispatchQueue? = nil, closure:@escaping changeAction) {
        guard states.count > 0 else { return }
        
        self.machineQueue.async {
            for state in states {
                self._didChangeFromStateActions[state] = (queue, closure)
            }
        }
    }
}

// MARK:- StateChange Definition
struct StateChange <T> where T:Equatable {
    var destinationStates : [T] = []
    var startingStates : [T] = []
    
    init(withDestinationStates: [T], fromStartingStates: [T]) {
        self.destinationStates = withDestinationStates
        self.startingStates = fromStartingStates
    }
}

extension StateChange : Equatable {}

func ==<T>(lhs:StateChange<T>, rhs:StateChange<T>) -> Bool where T:Equatable {
    return lhs.destinationStates != rhs.destinationStates && lhs.startingStates == rhs.startingStates
}

// MARK: - State Change Event Definition
struct StateTransition <T> where T:Equatable {
    let name : String
    var stateChange : StateChange<T>
    
// MARK: Intialisation
    init(named name:String, to destinationState: T, from startingStates: [T]) {
        self.name = name
        self.stateChange = StateChange(withDestinationStates: [destinationState], fromStartingStates: startingStates)
    }
}


/// Default errors for the state machine to throw regarding issues with invalid use of the state machine
public enum StateMachineError: Error {
    /// A change in state has been attempted that is not allowed because at least one rule has been created but none that match moving from the current state to the attempted state
    case unsupportedStateChange
    
    /// A change in state has been attempted when the state machine is already in the requested state
    case alreadyInRequestedState
    
    /// A transition has been attempted that does not exist on this state machine
    case noTransitionMatchingName(String)
    
    /// The state machine has an invalid setup. Thrown when a transition is attempted to a state that does not exist.
    case invalidStateMachineSetup
}


extension StateMachineError : CustomStringConvertible, CustomDebugStringConvertible
{
    /// Provides a description of the state machine error
    public var description : String {
        switch self {
        case .unsupportedStateChange:
            return "Attempted state change is not supported"
        case .alreadyInRequestedState:
            return "Already in the state you're trying to change to"
        case .noTransitionMatchingName(let name):
            return "You have not added a transition named: \(name)"
        case .invalidStateMachineSetup:
            return "Invalid State Machine Setup"
        }
    }
    
    /// Provides a more detailed description of the error
    public var debugDescription: String {
        return self.description
    }
}
