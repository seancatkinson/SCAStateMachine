//
//  StateTransitionTests.swift
//  SCAStateMachine
//
//  Created by Sean C Atkinson on 06/10/2015.
//
//

import XCTest
import Foundation
@testable import SCAStateMachine

class StateTransitionTests: SCAStateMachineBaseTests {

    func testCanCreateTransition() {
        self.stateMachine.addStateTransition(named: "test", from: [.Pending], to: .Testing)
        
        do {
            _ = try self.stateMachine.canPerformTransition(named: "test")
            XCTAssertTrue(true)
        }
        catch {
            XCTFail("This shoudn't fail")
        }
    }
    
    func testWillCatchUndefinedTransitions() {
        do {
            _ = try self.stateMachine.canPerformTransition(named: "test")
            XCTFail("Should throw before we get here")
        }
        catch StateMachineError.noTransitionMatchingName(let name) {
            XCTAssertEqual(name, "test")
        }
        catch {
            XCTFail("This shoudn't get caught here")
        }
    }
    
    func testWillPerformTransitions() {
        
        let expectation = self.expectation(description: "Should be performed")
        
        self.stateMachine.addStateTransition(named: "test", from: [.Pending], to: .Testing)
        self.stateMachine.performAfterChangingFrom([.Pending]) { (destinationState, startingState, userInfo) -> () in
            expectation.fulfill()
        }
        
        do {
            try self.stateMachine.performTransition(named: "test")
        }
        catch {
            XCTFail("This shoudn't fail")
        }
        
        self.waitForExpectations(timeout: 0.5, handler: nil)
    }

}
