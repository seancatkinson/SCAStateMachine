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
enum TestStates {
    case Pending
    case Testing
    case Passed
    case Failed
}

func createTestStateMachine() -> StateMachine<TestStates> {
    return StateMachine(withStartingState: TestStates.Pending)
}

func addTestStateRulesToTestStateMachine(inout stateMachine:StateMachine<TestStates>) {
    stateMachine.addStateChangeTo(.Testing, fromStartingStates: .Pending)
    stateMachine.addStateChangeTo(.Passed, fromStartingStates: .Testing)
    stateMachine.addStateChangeTo(.Failed, fromStartingStates: .Testing)
    stateMachine.addStateChangeTo(.Pending, fromStartingStates: .Passed, .Failed)
}
