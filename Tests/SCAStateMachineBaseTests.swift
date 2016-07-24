//
//  SCAStateMachineBaseTests.swift
//  SCAStateMachine
//
//  Created by Sean C Atkinson on 04/10/2015.
//
//

import XCTest
import Foundation
@testable import SCAStateMachine

class SCAStateMachineBaseTests: XCTestCase {

    var stateMachine : StateMachine<TestState>!
    
    override func setUp() {
        super.setUp()
        self.stateMachine = createTestStateMachine()
    }
    
    override func tearDown() {
        self.stateMachine = nil
        super.tearDown()
    }

}

// MARK:- Helper Methods
enum TestState : String, CustomStringConvertible {
    case Pending
    case Testing
    case Passed
    case Failed
    
    var description : String {
        return self.rawValue
    }
}

func createTestStateMachine(withStartingState: TestState = TestState.Pending) -> StateMachine<TestState> {
    return StateMachine(initialState: withStartingState)
}

func addTestStateRulesToTestStateMachine(stateMachine:StateMachine<TestState>) -> StateMachine<TestState> {
    stateMachine.allowChangingFrom(.Pending, to: [.Testing]) // this indicates a test started
    stateMachine.allowChangingFrom(.Testing, to: [.Passed, .Failed]) // this indicates test failed with a result
    stateMachine.allowChangingTo(.Pending, from: [.Passed, .Failed]) // this allows restarting the test
    return stateMachine
}
