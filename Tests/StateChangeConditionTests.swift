//  StateChangeConditionTests.swift
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

enum StateConditionErrors : ErrorType {
    case ErrorOne
    case ErrorTwo
}

class StateChangeConditionTests: SCAStateMachineBaseTests {

    func testCanSetConditions() {
        stateMachine = addTestStateRulesToTestStateMachine(stateMachine)
        
        stateMachine.checkConditionBeforeChangingTo([.Testing]) { (destinationState, startingState, userInfo) throws in
            throw StateConditionErrors.ErrorOne
        }
        
        do {
            try stateMachine.canChangeTo(.Testing)
        }
        catch StateConditionErrors.ErrorOne {
            return
        }
        catch {}
        
        XCTFail("Could change to state")
        return
    }
    
    func testConditionsForStartingStatesAreExecuted() {
        stateMachine = addTestStateRulesToTestStateMachine(stateMachine)
        
        var number = 0
        stateMachine.checkConditionBeforeChangingFrom([.Pending]) { (destinationState, startingState, userInfo) -> () in
            number = 12
        }
        
        do {
            try! stateMachine.changeTo(.Testing)
        }
        
        XCTAssertEqual(number, 12)
    }
    
    func testConditionsForDestinationStatesAreExecuted() {
        stateMachine = addTestStateRulesToTestStateMachine(stateMachine)
        
        var number = 0
        stateMachine.checkConditionBeforeChangingTo([.Testing]) { (destinationState, startingState, userInfo) -> () in
            number = 12
        }
        
        try! stateMachine.changeTo(.Testing)
        
        XCTAssertEqual(number, 12)
    }
    
    func testMultipleConditionsCanBeExecuted() {
        stateMachine = addTestStateRulesToTestStateMachine(stateMachine)
        
        var number = 0
        
        stateMachine.checkConditionBeforeChangingFrom([.Pending]) { (destinationState, startingState, userInfo) -> () in
            number = number + 1
        }
        stateMachine.checkConditionBeforeChangingTo([.Testing]) { (destinationState, startingState, userInfo) -> () in
            number = number + 1
        }
        
        try! stateMachine.changeTo(.Testing)
        
        XCTAssertEqual(number, 2)
    }
    
    func testOnlyConditionsForSpecifiedStatesAreExecuted() {
        stateMachine = addTestStateRulesToTestStateMachine(stateMachine)
        
        stateMachine.checkConditionBeforeChangingTo([.Passed]) { (destinationState, startingState, userInfo) -> () in
            XCTFail("Condition shouldn't be executed")
        }
        
        do {
            try! stateMachine.changeTo(.Testing)
        }
    }

}
