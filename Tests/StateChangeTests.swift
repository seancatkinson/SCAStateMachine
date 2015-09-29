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
        let stateChange = StateChange(withDestinationStates: [TestStates.Testing], fromStartingStates: [TestStates.Pending])
        XCTAssertEqual(stateChange.destinationStates, [.Testing])
        XCTAssertEqual(stateChange.startingStates, [.Pending])
        XCTAssertTrue(stateChange.destinationStates.contains(.Testing))
        XCTAssertTrue(stateChange.startingStates.contains(.Pending))
    }

// MARK:- Add State Change Rules
    func testCanAddToStateChangesFromMultipleStartingStates() {
        var stateMachine = createTestStateMachine(.Passed)
        stateMachine.addStateChangeRulesTo(.Pending, fromStartingStates: .Passed, .Failed)
        
        guard let _ = try? stateMachine.canChangeToState(.Pending) else {
            XCTFail("Could not add a state change")
            return
        }
        
        stateMachine = createTestStateMachine(.Failed)
        stateMachine.addStateChangeRulesTo(.Pending, fromStartingStates: .Passed, .Failed)
        
        guard let _ = try? stateMachine.canChangeToState(.Pending) else {
            XCTFail("Could not add a state change")
            return
        }
    }
    
    func testCanAddToStateChangesToMultipleDestinationStates() {
        let stateMachine = createTestStateMachine(.Testing)
        stateMachine.addStateChangeRulesTo(.Passed, .Failed, fromStartingState: .Testing)
        
        guard let _ = try? stateMachine.canChangeToState(.Passed) else {
            XCTFail("Could not add a state change")
            return
        }
        
        guard let _ = try? stateMachine.canChangeToState(.Failed) else {
            XCTFail("Could not add a state change")
            return
        }
    }
    
    func testCanAddFromStateChangeRulesFromMultipleStartingStates() {
        var stateMachine = createTestStateMachine(.Passed)
        stateMachine.addStateChangeRulesFrom(.Passed, .Failed, toDestinationState: .Pending)
        
        guard let _ = try? stateMachine.canChangeToState(.Pending) else {
            XCTFail("Could not add a state change")
            return
        }
        
        stateMachine = createTestStateMachine(.Failed)
        stateMachine.addStateChangeRulesFrom(.Passed, .Failed, toDestinationState: .Pending)
        
        guard let _ = try? stateMachine.canChangeToState(.Pending) else {
            XCTFail("Could not add a state change")
            return
        }
    }
    
    func testCanAddFromStateChangeRulesToMultipleDestinationStates() {
        let stateMachine = createTestStateMachine(.Testing)
        stateMachine.addStateChangeRulesFrom(.Testing, toDestinationStates: .Passed, .Failed)
        
        guard let _ = try? stateMachine.canChangeToState(.Passed) else {
            XCTFail("Could not add a state change")
            return
        }
        
        guard let _ = try? stateMachine.canChangeToState(.Failed) else {
            XCTFail("Could not add a state change")
            return
        }
    }
    
    
    
// MARK:- Check State Change Rules
    func testCanCheckStateChangeRulesBeforeAddingRules() {
        let stateMachine = createTestStateMachine(.Pending)
        guard let _ = try? stateMachine.canChangeToState(.Testing) else {
            XCTFail("Could not change state to .Testing")
            return
        }
        guard let _ = try? stateMachine.canChangeToState(.Passed) else {
            XCTFail("Could not change state to .Passed")
            return
        }
        guard let _ = try? stateMachine.canChangeToState(.Failed) else {
            XCTFail("Could not change state to .Failed")
            return
        }
    }
    
    func testCannotChangeStateWithoutCorrectRules() {
        let stateMachine = createTestStateMachine()
        stateMachine.addStateChangeRulesTo(.Testing, fromStartingStates: .Pending)
        
        guard let _ = try? stateMachine.canChangeToState(.Testing) else {
            XCTFail("Could not change state to .Testing")
            return
        }
        
        guard let _ = try? stateMachine.canChangeToState(.Passed) else {
            // we want this to fail
            // no rules have been setup
            return
        }
        
        XCTFail("Could change state to .Passed even though no rules were set up")
    }
    
    func testCanCheckStateChangeRulesAfterAddingCompleteRules() {
        let stateMachine = createTestStateMachine()
        stateMachine.addStateChangeRulesTo(.Testing, fromStartingStates: .Pending)
        do {
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
        
        do {
            try stateMachine.changeToState("Two", userInfo: nil)
        }
        catch {
            XCTFail("Couldn't change the state")
            return
        }
        XCTAssertEqual(stateMachine.currentState, "Two", "State should now equal Two")
    }
    
    func testStateMachineErrorHasDescription() {
        let string = StateMachineError.UnsupportedStateChange.description
        XCTAssertTrue(string.characters.count > 0)
        
        let stringTwo = StateMachineError.AlreadyInRequestedState.description
        XCTAssertTrue(stringTwo.characters.count > 0)
    }

}
