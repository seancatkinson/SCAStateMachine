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
    
    func testCanCreateStateChangeObjectsWithStartingStatesArray() {
        let stateChange = StateChange(withDestinationState: TestStates.Testing, fromStartingStates: [TestStates.Pending])
        XCTAssertEqual(stateChange.destinationState, TestStates.Testing)
        XCTAssertEqual(stateChange.startingStates, [TestStates.Pending])
    }
    
    func testCanCreateStateChangeObjectsWithVariadicStartingStates() {
        let stateChange = StateChange(withDestinationState: TestStates.Testing, fromStartingStates: TestStates.Pending)
        XCTAssertEqual(stateChange.destinationState, TestStates.Testing)
        XCTAssertEqual(stateChange.startingStates, [TestStates.Pending])
    }

// MARK:- Add State Change Rules
    func testCanAddStateChanges() {
        let stateMachine = createTestStateMachine()
        do {
            try stateMachine.addStateChangeTo(.Testing, fromStartingStates: .Pending)
        }
        catch {
            XCTFail("Could not add a state change")
        }
    }
    
    func testCannotAddStateChangeAfterActivation() {
        let stateMachine = createTestStateMachine()
        stateMachine.activate()
        
        do {
            try stateMachine.addStateChangeTo(.Testing, fromStartingStates: .Pending)
        }
        catch {
            return
        }
        XCTFail("Could add a state change after activation")
    }
    
// MARK:- Check State Change Rules
    func testCanCheckStateChangeRulesBeforeAddingRules() {
        let stateMachine = createTestStateMachine()
        // run a test before adding any rules
        do {
            try stateMachine.canChangeToState(.Testing)
        }
        catch {
            XCTFail("Could not check a state change")
            return
        }
    }
    
    func testCanCheckStateChangeRulesAfterAddingIncompleteRules() {
        let stateMachine = createTestStateMachine()
        do {
            try stateMachine.addStateChangeTo(.Testing, fromStartingStates: .Pending)
            try stateMachine.canChangeToState(.Testing)
        }
        catch {
            XCTFail("Could not change state")
            return
        }
    }
    
    func testCanCheckStateChangeRulesAfterAddingCompleteRules() {
        let stateMachine = createTestStateMachine()
        do {
            try stateMachine.addStateChangeTo(.Testing, fromStartingStates: .Pending)
            try stateMachine.canChangeToState(.Testing)
        }
        catch {
            XCTFail("Could not add a state change")
            return
        }
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
            XCTFail("Couldn't change the state")
            return
        }
    }
    
    func testCannotChangeToUnapplicableState() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        stateMachine.activate()
        
        do {
            try stateMachine.changeToState(.Passed, userInfo: nil)
        }
        catch {
            return
        }
        XCTFail("Managed to move to unapplicable state")
    }
    
    func testCannotChangeWithoutActivation() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        
        do {
            try stateMachine.changeToState(.Passed, userInfo: nil)
        }
        catch {
            return
        }
        XCTFail("Managed to change state without activation")
    }
    
// MARK:- State Types
    func testCanUseStringsAsStateTypes() {
        let stateMachine = StateMachine(withStartingState: "One")
        do {
            try stateMachine.canChangeToState("Two")
        }
        catch {
            XCTFail("Couldn't change the state")
            return
        }
        
        stateMachine.activate()
        
        do {
            try stateMachine.changeToState("Two", userInfo: nil)
        }
        catch {
            XCTFail("Couldn't change the state")
            return
        }
        XCTAssertEqual(stateMachine.currentState, "Two", "State should now equal Two")
    }

}
