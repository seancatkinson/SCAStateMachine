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

class StateChangeConditionTests: XCTestCase {

    func testCanSetConditions() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        do {            
            try stateMachine.addStateChangeCondition({ (destinationState, startingState, userInfo) throws in
                    throw StateConditionErrors.ErrorOne
                }, forDestinationStates: .Testing)
        }
        catch {
            XCTFail("Couldn't set a condition")
            return
        }
    }
    
    func testCannotSetStartingStateConditionsAfterActivation() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        stateMachine.activate()
        do {
            try stateMachine.addStateChangeCondition({ (destinationState, startingState, userInfo) throws in
                // do nothing :)
                }, forStartingStates: .Testing)
        }
        catch {
            return
        }
        XCTFail("Set a condition after activation")
    }
    
    func testCannotSetDestinationStateConditionsAfterActivation() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        stateMachine.activate()
        do {
            try stateMachine.addStateChangeCondition({ (destinationState, startingState, userInfo) throws in
                    // do nothing :)
                }, forDestinationStates: .Testing)
        }
        catch {
            return
        }
        XCTFail("Set a condition after activation")
    }
    
    func testConditionsForStartingStatesAreExecuted() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        let expectation = expectationWithDescription("condition should be executed")
        do {
            try! stateMachine.addStateChangeCondition({ (destinationState, startingState, userInfo) throws in
                    expectation.fulfill()
                }, forStartingStates: .Pending)
        }
        stateMachine.activate()
        
        do {
            try! stateMachine.changeToState(.Testing)
        }
        
        waitForExpectationsWithTimeout(0.5) { (error) -> Void in
            if let error = error {
                print(error.description)
            }
        }
    }
    
    func testConditionsForDestinationStatesAreExecuted() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        let expectation = expectationWithDescription("condition should be executed")
        try! stateMachine.addStateChangeCondition({ (destinationState, startingState, userInfo) throws in
                expectation.fulfill()
            }, forDestinationStates: .Testing)
        stateMachine.activate()
        
        try! stateMachine.changeToState(.Testing)
        
        waitForExpectationsWithTimeout(0.5) { (error) -> Void in
            if let error = error {
                print(error.description)
            }
        }
    }
    
    func testMultipleConditionsCanBeExecuted() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        let expectation = expectationWithDescription("condition should be executed")
        let expectationtwo = expectationWithDescription("condition two should be executed")
        do {
            try! stateMachine.addStateChangeCondition({ (destinationState, startingState, userInfo) throws in
                    expectation.fulfill()
                }, forStartingStates: .Pending)
            try! stateMachine.addStateChangeCondition({ (destinationState, startingState, userInfo) throws in
                    expectationtwo.fulfill()
                }, forDestinationStates: .Testing)
            
        }
        stateMachine.activate()
        
        try! stateMachine.changeToState(.Testing)
        
        waitForExpectationsWithTimeout(0.5) { (error) -> Void in
            if let error = error {
                print(error.description)
            }
        }
    }
    
    func testOnlyConditionsForSpecifiedStatesAreExecuted() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        do {
            try! stateMachine.addStateChangeCondition({ (destinationState, startingState, userInfo) throws in
                    XCTFail("Condition shouldn't be executed")
                }, forDestinationStates: .Passed)
        }
        stateMachine.activate()
        
        do {
            try! stateMachine.changeToState(.Testing)
        }
    }

}
