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

    var stateMachine : StateMachine<TestStates>!
    
    override func setUp() {
        super.setUp()
        self.stateMachine = createTestStateMachine()
    }
    
    override func tearDown() {
        super.tearDown()
        self.stateMachine = nil
    }

}

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

func addTestStateRulesToTestStateMachine(stateMachine:StateMachine<TestStates>) -> StateMachine<TestStates> {
    stateMachine.addStateChangeRulesFrom(.Pending, toDestinationState: .Testing)
    stateMachine.addStateChangeRulesFrom(.Testing, toDestinationStates:.Passed, .Failed)
    stateMachine.addStateChangeRulesFrom(.Passed, .Failed, toDestinationState: .Pending)
    return stateMachine
}
