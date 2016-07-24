//  StateChangeActionTests.swift
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

class StateChangeActionTests: SCAStateMachineBaseTests {        
    
    func testCanSetActions() {
        stateMachine = addTestStateRulesToTestStateMachine(stateMachine)
        
        let expectation = self.expectationWithDescription("Should be performed")
        stateMachine.performAfterChangingTo([.Testing]) { (destinationState, startingState, userInfo) -> () in
            expectation.fulfill()
        }
        
        do {
            try stateMachine.changeTo(.Testing)
        }
        catch {
            XCTFail("Couldn't change state")
            return
        }
        
        self.waitForExpectationsWithTimeout(0.5, handler: nil)
    }
    
    func testActionsAreNotAddedWhenNoStatesProvided() {
        
        stateMachine.allowChangingFrom(.Pending, to: [])
        stateMachine.allowChangingTo(.Testing, from: [])
        
        stateMachine.addStateTransition(named: "Test", from: [], to: .Testing)
        
        do { try stateMachine.canPerformTransition(named: "Test") }
        catch StateMachineError.NoTransitionMatchingName(let name) {
            XCTAssertEqual(name, "Test")
        }
        catch {
            XCTFail("Should have been caught earlier")
        }
        
        stateMachine.performAfterChangingTo([]) { _,_,_ in }
        stateMachine.performAfterChangingFrom([]) { _,_,_ in }
        
        stateMachine.checkConditionBeforeChangingTo([]) { _,_,_ in }
        stateMachine.checkConditionBeforeChangingFrom([]) { _,_,_ in }
        
        
    }
    

    func testActionsFireInTheCorrectOrder() {
        stateMachine = addTestStateRulesToTestStateMachine(stateMachine)
        
        var myNumber:Int = 0
        let expectation1 = self.expectationWithDescription("Should be performed")
        let expectation2 = self.expectationWithDescription("Should be performed")
        let expectation3 = self.expectationWithDescription("Should be performed")
        
        stateMachine.performAfterChangingTo([.Testing]) { (destinationState, startingState, userInfo) -> () in
            myNumber += 1
            XCTAssertEqual(myNumber, 1, "myNumber should equal 1")
            expectation1.fulfill()
        }
        
        stateMachine.performAfterChangingFrom([.Pending]) { (destinationState, startingState, userInfo) -> () in
            myNumber += 10
            XCTAssertEqual(myNumber, 11, "myNumber should equal 11")
            expectation2.fulfill()
        }
        
        stateMachine.performAfterChanging { (destinationState, startingState, userInfo) -> () in
            myNumber += 100
            XCTAssertEqual(myNumber, 111, "myNumber should equal 111")
            expectation3.fulfill()
        }
        
        do {
            try stateMachine.changeTo(.Testing, userInfo: nil)
        }
        catch {
            XCTFail("Couldn't change to state .Testing")
            return
        }
        
        self.waitForExpectationsWithTimeout(0.5, handler: nil)
    }
    
    func testCorrectStatesArePassedDuringStateChange() {
        stateMachine = addTestStateRulesToTestStateMachine(stateMachine)
        
        let myNumber:Int = 8000
        
        stateMachine.performAfterChangingTo([.Testing]) { (destinationState, startingState, userInfo) -> () in
            XCTAssertTrue(destinationState == TestState.Testing, "destinationState should equal .Testing but instead equals: \(destinationState)")
            XCTAssertTrue(startingState == TestState.Pending, "startingState should equal .Pending but instead equals: \(startingState)")
            
            if let userInfo = userInfo where userInfo is Int {
                let passedNumber = userInfo as! Int
                XCTAssertTrue(passedNumber == myNumber, "userInfo should equal what is passed")
            } else {
                XCTFail("userInfo isn't valid")
            }
        }

        stateMachine.performAfterChangingFrom([.Pending]) { (destinationState, startingState, userInfo) -> () in
            XCTAssertTrue(destinationState == TestState.Testing, "destinationState should equal .Testing but instead equals: \(destinationState)")
            XCTAssertTrue(startingState == TestState.Pending, "startingState should equal .Pending but instead equals: \(startingState)")
            
            if let userInfo = userInfo where userInfo is Int {
                let passedNumber = userInfo as! Int
                XCTAssertTrue(passedNumber == myNumber, "userInfo should equal what is passed")
            } else {
                XCTFail("userInfo isn't valid")
            }
        }
        
        stateMachine.performAfterChanging { (destinationState, startingState, userInfo) -> () in
            XCTAssertTrue(destinationState == TestState.Testing, "destinationState should equal .Testing but instead equals: \(destinationState)")
            XCTAssertTrue(startingState == TestState.Pending, "startingState should equal .Pending but instead equals: \(startingState)")
            
            if let userInfo = userInfo where userInfo is Int {
                let passedNumber = userInfo as! Int
                XCTAssertTrue(passedNumber == myNumber, "userInfo should equal what is passed")
            } else {
                XCTFail("userInfo isn't valid")
            }
        }
        
        do {
            try stateMachine.changeTo(.Testing, userInfo: myNumber)
        }
        catch {
            XCTFail("Couldn't change to state .Testing")
            return
        }
    }
    
    func  testCannotChangeToStateWhenAlreadyInRequestedState() {
        
        do {
            try stateMachine.changeTo(.Pending)
        }
        catch {
            return
        }
        XCTFail("Error should have thrown")
    }
    
    func testCanAutomaticallyChangeTo3rdStateAfterChangingTo2ndState() {
        
        let expectation1 = self.expectationWithDescription("Should be performed")
        stateMachine.performAfterChangingTo([.Failed]) { [weak stateMachine] (destinationState, startingState, userInfo) -> () in
            XCTAssertEqual(stateMachine!.currentState, TestState.Failed)
            do {
                try stateMachine?.changeTo(.Pending)
            }
            catch {
                XCTFail("\(error)")
            }
            expectation1.fulfill()
        }
        
        let expectation2 = self.expectationWithDescription("Should be performed")
        stateMachine.performAfterChangingTo([.Pending]) { (destinationState, startingState, userInfo) -> () in
            expectation2.fulfill()
        }
        
        do {
            try stateMachine.changeTo(.Testing)
            try stateMachine.changeTo(.Failed)

            
        }
        catch {
            XCTFail("\(error)")
        }
        
        self.waitForExpectationsWithTimeout(0.5) { errorOptional in
            XCTAssertEqual(self.stateMachine.currentState, TestState.Pending)
        }
    }


    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

}
