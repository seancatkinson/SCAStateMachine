//
//  StateMachineTestHelpers.swift
//  SCAStateMachine
//
//  Created by Sean C Atkinson on 28/06/2015.
//
//

import XCTest
import Foundation
@testable import SCAStateMachine

// MARK:- Helper Methods
enum TestStates : String, CustomStringConvertible {
    case Pending
    case Testing
    case Passed
    case Failed
    
    var description : String {
        return self.rawValue
    }
}

func createTestStateMachine(withStartingState: TestStates = TestStates.Pending) -> StateMachine<TestStates> {
    return StateMachine(withStartingState: withStartingState)
}

func addTestStateRulesToTestStateMachine(inout stateMachine:StateMachine<TestStates>) {
    stateMachine.addStateChangeRulesFrom(.Pending, toDestinationState: .Testing)
    stateMachine.addStateChangeRulesFrom(.Testing, toDestinationStates:.Passed, .Failed)
    stateMachine.addStateChangeRulesFrom(.Passed, .Failed, toDestinationState: .Pending)
}
