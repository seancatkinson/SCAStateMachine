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
enum TestStates :CustomStringConvertible {
    case Pending
    case Testing
    case Passed
    case Failed
    
    var description: String {
        switch self {
        case .Pending:
            return ".Pending"
        case .Testing:
            return ".Testing"
        case .Passed:
            return ".Passed"
        case .Failed:
            return ".Failed"
        }
    }
}

func createTestStateMachine() -> StateMachine<TestStates> {
    return StateMachine(withInitialState: TestStates.Pending)
}

func addTestStateRulesToTestStateMachine(inout stateMachine:StateMachine<TestStates>) {
    do {
        try stateMachine.addStateChangeTo(.Testing, fromStartingStates: .Pending)
        try stateMachine.addStateChangeTo(.Passed, fromStartingStates: .Testing)
        try stateMachine.addStateChangeTo(.Failed, fromStartingStates: .Testing)
        try stateMachine.addStateChangeTo(.Pending, fromStartingStates: .Passed, .Failed)
    }
    catch {
        XCTAssertTrue(false, "Could not add State Change Rules")
    }
}
