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

class StateChangeTests: SCAStateMachineBaseTests {
    
    func testCanCreateStateChangeObjectsWithStartingStatesArray() {
        let stateChange = StateChange(withDestinationStates: [TestState.Testing], fromStartingStates: [TestState.Pending])
        XCTAssertEqual(stateChange.destinationStates, [.Testing])
        XCTAssertEqual(stateChange.startingStates, [.Pending])
        XCTAssertTrue(stateChange.destinationStates.contains(.Testing))
        XCTAssertTrue(stateChange.startingStates.contains(.Pending))
    }

// MARK:- Add State Change Rules
    func testCanAddToStateChangesFromMultipleStartingStates() {
        var stateMachine = createTestStateMachine(.Passed)
        stateMachine.allowChangingTo(.Pending, from: [.Passed, .Failed])
        
        guard let _ = try? stateMachine.canChangeTo(.Pending) else {
            XCTFail("Could not add a state change")
            return
        }
        
        stateMachine = createTestStateMachine(.Failed)
        stateMachine.allowChangingTo(.Pending, from: [.Passed, .Failed])
        
        guard let _ = try? stateMachine.canChangeTo(.Pending) else {
            XCTFail("Could not add a state change")
            return
        }
    }
    
    func testCanAddToStateChangesToMultipleDestinationStates() {
        let stateMachine = createTestStateMachine(.Testing)
        stateMachine.allowChangingFrom(.Testing, to: [.Passed, .Failed])
        
        guard let _ = try? stateMachine.canChangeTo(.Passed) else {
            XCTFail("Could not change from .Testing to .Passed")
            return
        }
        
        guard let _ = try? stateMachine.canChangeTo(.Failed) else {
            XCTFail("Could not change from .Testing to .Failed")
            return
        }
    }
    
    func testCanAddFromStateChangeRulesFromMultipleStartingStates() {
        var stateMachine = createTestStateMachine(.Passed)
        stateMachine.allowChangingTo(.Pending, from: [.Passed, .Failed])
        
        guard let _ = try? stateMachine.canChangeTo(.Pending) else {
            XCTFail("Could not add a state change")
            return
        }
        
        stateMachine = createTestStateMachine(.Failed)
        stateMachine.allowChangingTo(.Pending, from: [.Passed, .Failed])
        
        guard let _ = try? stateMachine.canChangeTo(.Pending) else {
            XCTFail("Could not add a state change")
            return
        }
    }
    
    func testCanAddFromStateChangeRulesToMultipleDestinationStates() {
        let stateMachine = createTestStateMachine(.Testing)
        stateMachine.allowChangingFrom(.Testing, to: [.Passed, .Failed])
        
        guard let _ = try? stateMachine.canChangeTo(.Passed) else {
            XCTFail("Could not add a state change")
            return
        }
        
        guard let _ = try? stateMachine.canChangeTo(.Failed) else {
            XCTFail("Could not add a state change")
            return
        }
    }
    
    
    
// MARK:- Check State Change Rules
    func testCanCheckStateChangeRulesBeforeAddingRules() {
        let stateMachine = createTestStateMachine(.Pending)
        guard let _ = try? stateMachine.canChangeTo(.Testing) else {
            XCTFail("Could not change state to .Testing")
            return
        }
        guard let _ = try? stateMachine.canChangeTo(.Passed) else {
            XCTFail("Could not change state to .Passed")
            return
        }
        guard let _ = try? stateMachine.canChangeTo(.Failed) else {
            XCTFail("Could not change state to .Failed")
            return
        }
    }
    
    func testCannotChangeStateWithoutCorrectRules() {
        let stateMachine = createTestStateMachine()
        stateMachine.allowChangingTo(.Testing, from: [.Pending])
        
        guard let _ = try? stateMachine.canChangeTo(.Testing) else {
            XCTFail("Could not change state to .Testing")
            return
        }
        
        guard let _ = try? stateMachine.canChangeTo(.Passed) else {
            // we want this to fail
            // no rules have been setup
            return
        }
        
        XCTFail("Could change state to .Passed even though no rules were set up")
    }
    
    func testCanCheckStateChangeRulesAfterAddingCompleteRules() {
        let stateMachine = createTestStateMachine()
        stateMachine.allowChangingTo(.Testing, from: [.Pending])
        do {
            try stateMachine.canChangeTo(.Testing)
        }
        catch {
            XCTFail("Could not add a state change")
            return
        }
    }
    
// MARK:- Change State
    func testCanChangeState() {
        stateMachine = addTestStateRulesToTestStateMachine(stateMachine)
        
        do {
            try stateMachine.changeTo(.Testing, userInfo: nil)
        }
        catch {
            XCTFail("Couldn't change the state")
            return
        }
    }
    
    func testCannotChangeToUnapplicableState() {
        stateMachine = addTestStateRulesToTestStateMachine(stateMachine)
        
        do {
            try stateMachine.changeTo(.Passed, userInfo: nil)
        }
        catch {
            return
        }
        XCTFail("Managed to move to unapplicable state")
    }
    
    func testCannotChangeWithoutActivation() {
        stateMachine = addTestStateRulesToTestStateMachine(stateMachine)
        
        do {
            try stateMachine.changeTo(.Passed, userInfo: nil)
        }
        catch {
            return
        }
        XCTFail("Managed to change state without activation")
    }
    
// MARK:- State Types
    func testCanUseStringsAsStateTypes() {
        let stateMachine = StateMachine(initialState: "One")
        do {
            try stateMachine.canChangeTo("Two")
        }
        catch {
            XCTFail("Couldn't change the state")
            return
        }
        
        do {
            try stateMachine.changeTo("Two", userInfo: nil)
        }
        catch {
            XCTFail("Couldn't change the state")
            return
        }
        XCTAssertEqual(stateMachine.currentState, "Two", "State should now equal Two")
    }
    
    func testStateMachineErrorHasDescription() {
        let string = StateMachineError.unsupportedStateChange.description
        XCTAssertTrue(string.characters.count > 0)
        
        let stringTwo = StateMachineError.alreadyInRequestedState.description
        XCTAssertTrue(stringTwo.characters.count > 0)
        
        let stringThree = StateMachineError.noTransitionMatchingName("Hello").description
        XCTAssertTrue(stringThree.characters.count > 0)
        
        let stringFour = StateMachineError.invalidStateMachineSetup.description
        XCTAssertTrue(stringFour.characters.count > 0)
        
        let stringFive = StateMachineError.invalidStateMachineSetup.debugDescription
        XCTAssertTrue(stringFive.characters.count > 0)
    }

}
