//  StateChangeTests.swift
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



import XCTest
import Foundation
@testable import SCAStateMachine

class StateChangeTests: XCTestCase {

// MARK:- Add State Change Rules
    func testCanAddStateChanges() {
        let stateMachine = createTestStateMachine()
        do {
            try stateMachine.addStateChangeTo(.Testing, fromStartingStates: .Pending)
        }
        catch {
            XCTAssertTrue(false, "Could not add a state change")
        }
    }
    
    func testCannotAddStateChangeAfterActivation() {
        let stateMachine = createTestStateMachine()
        stateMachine.activate()
        
        do {
            try stateMachine.addStateChangeTo(.Testing, fromStartingStates: .Pending)
        }
        catch {
            XCTAssertTrue(true, "Could not add a state change")
            return
        }
        XCTAssertTrue(false, "Could add a state change after activation")
    }
    
// MARK:- Check State Change Rules
    func testCanCheckStateChangeRulesBeforeAddingRules() {
        let stateMachine = createTestStateMachine()
        // run a test before adding any rules
        let result = stateMachine.canChangeToState(.Testing)
        XCTAssertFalse(result, "Should be false since no rules have been added yet")
    }
    
    func testCanCheckStateChangeRulesAfterAddingIncompleteRules() {
        let stateMachine = createTestStateMachine()
        do {
            try stateMachine.addStateChangeTo(.Passed, fromStartingStates: .Testing)
        }
        catch {
            XCTAssertTrue(false, "Could not add a state change")
        }
        
        let result = stateMachine.canChangeToState(.Testing)
        XCTAssertFalse(result, "Should be false since no rules have been added yet for this change")
    }
    
    func testCanCheckStateChangeRulesAfterAddingCompleteRules() {
        let stateMachine = createTestStateMachine()
        do {
            try stateMachine.addStateChangeTo(.Testing, fromStartingStates: .Pending)
        }
        catch {
            XCTAssertTrue(false, "Could not add a state change")
        }
        let result = stateMachine.canChangeToState(.Testing)
        XCTAssertTrue(result, "Should be true since we have just added a supporting rule")
    }
    
// MARK:- Change State
    func testCanChangeState() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        stateMachine.activate()
        
        do {
            try stateMachine.changeToState(.Testing, userInfo: nil)
        }
        catch {
            XCTAssertTrue(false, "Couldn't change the state")
            return
        }
        XCTAssertTrue(true)
    }
    
    func testCannotChangeToUnapplicableState() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        stateMachine.activate()
        
        do {
            try stateMachine.changeToState(.Passed, userInfo: nil)
        }
        catch {
            XCTAssertTrue(true, "Couldn't change the state")
            return
        }
        XCTAssertTrue(false, "Managed to move to unapplicable state")
    }
    
    func testCannotChangeWithoutActivation() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        
        do {
            try stateMachine.changeToState(.Passed, userInfo: nil)
        }
        catch {
            XCTAssertTrue(true, "Couldn't change the state")
            return
        }
        XCTAssertTrue(false, "Managed to change state without activation")
    }

}
