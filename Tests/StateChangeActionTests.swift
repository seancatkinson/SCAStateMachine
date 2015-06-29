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

class StateChangeActionTests: XCTestCase {
    
    func testCanSetActions() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        do {
            try stateMachine.perform({ (newState, oldState, userInfo) -> () in
                print("Hello World")
            }, beforeChangingToStates: .Testing)
        }
        catch {
            XCTAssertTrue(false, "Couldn't set an action")
            return
        }
        XCTAssertTrue(true, "Set the action")
    }
    
    func testCannotSetActionsAfterActivation() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        stateMachine.activate()
        do {
            try stateMachine.perform({ (newState, oldState, userInfo) -> () in
                print("Hello World")
                }, beforeChangingToStates: .Testing)
        }
        catch {
            XCTAssertTrue(true, "Couldn't set an action")
            return
        }
        XCTAssertTrue(false, "Set an action after activation")
    }

    func testActionsFireInTheCorrectOrder() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        
        var myNumber:Int = 0
        
        do {
            try stateMachine.perform(beforeChanging: { (newState, oldState, userInfo) -> () in
                myNumber += 1
                XCTAssertEqual(myNumber, 1, "myNumber should equal 1")
            })
            
            try stateMachine.perform({ (newState, oldState, userInfo) -> () in
                myNumber += 10
                XCTAssertEqual(myNumber, 11, "myNumber should equal 11")
            }, beforeChangingFromStates: .Pending)
            
            try stateMachine.perform({ (newState, oldState, userInfo) -> () in
                myNumber += 100
                XCTAssertEqual(myNumber, 111, "myNumber should equal 111")
                }, beforeChangingToStates: .Testing)
            
            try stateMachine.perform({ (newState, oldState, userInfo) -> () in
                myNumber += 1000
                XCTAssertEqual(myNumber, 1111, "myNumber should equal 1111")
            }, afterChangingToStates: .Testing)

            try stateMachine.perform({ (newState, oldState, userInfo) -> () in
                myNumber += 10000
                XCTAssertEqual(myNumber, 11111, "myNumber should equal 11111")
            }, afterChangingFromStates: .Pending)
            
            try stateMachine.perform(afterChanging: { (newState, oldState, userInfo) -> () in
                myNumber += 100000
                XCTAssertEqual(myNumber, 111111, "myNumber should equal 111111")
            })
        }
        catch {
            XCTAssertTrue(false, "Couldn't set an action")
            return
        }
        
        stateMachine.activate()
        
        do {
            try stateMachine.changeToState(.Testing, userInfo: nil)
        }
        catch {
            XCTAssertTrue(false, "Couldn't change to state .Testing")
            return
        }
        XCTAssertTrue(true, "Changed State")
        XCTAssertEqual(myNumber, 111111, "myNumber should equal 111111")
    }
    
    func testCorrectStatesArePassedDuringStateChange() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        
        let myNumber:Int = 8000
        
        do {
            try stateMachine.perform({ (newState, oldState, userInfo) -> () in
                XCTAssertTrue(newState == TestStates.Testing, "newState should equal .Testing but instead equals: \(newState)")
                XCTAssertTrue(oldState == TestStates.Pending, "oldState should equal .Pending but instead equals: \(oldState)")
                XCTAssertTrue(stateMachine.currentState == .Pending, "currentState should still equal .Pending but instead equals: \(stateMachine.currentState)")
                
                if let userInfo = userInfo where userInfo is Int {
                    let passedNumber = userInfo as! Int
                    XCTAssertTrue(passedNumber == myNumber, "userInfo should equal what is passed")
                } else {
                    XCTAssertTrue(false, "userInfo isn't valid")
                }
            }, beforeChangingToStates: .Testing)

            try stateMachine.perform({ (newState, oldState, userInfo) -> () in
                XCTAssertTrue(newState == TestStates.Testing, "newState should equal .Testing but instead equals: \(newState)")
                XCTAssertTrue(oldState == TestStates.Pending, "oldState should equal .Pending but instead equals: \(oldState)")
                XCTAssertTrue(stateMachine.currentState == .Pending, "currentState should still equal .Pending but instead equals: \(stateMachine.currentState)")
                
                if let userInfo = userInfo where userInfo is Int {
                    let passedNumber = userInfo as! Int
                    XCTAssertTrue(passedNumber == myNumber, "userInfo should equal what is passed")
                } else {
                    XCTAssertTrue(false, "userInfo isn't valid")
                }
            }, beforeChangingFromStates: .Pending)
            
            try stateMachine.perform({ (newState, oldState, userInfo) -> () in
                XCTAssertTrue(newState == TestStates.Testing, "newState should equal .Testing but instead equals: \(newState)")
                XCTAssertTrue(oldState == TestStates.Pending, "oldState should equal .Pending but instead equals: \(oldState)")
                XCTAssertTrue(stateMachine.currentState == .Testing, "currentState should now equal .Testing but instead equals: \(stateMachine.currentState)")
                
                if let userInfo = userInfo where userInfo is Int {
                    let passedNumber = userInfo as! Int
                    XCTAssertTrue(passedNumber == myNumber, "userInfo should equal what is passed")
                } else {
                    XCTAssertTrue(false, "userInfo isn't valid")
                }
            }, afterChangingToStates: .Testing)
            
            try stateMachine.perform({ (newState, oldState, userInfo) -> () in
                XCTAssertTrue(newState == TestStates.Testing, "newState should equal .Testing but instead equals: \(newState)")
                XCTAssertTrue(oldState == TestStates.Pending, "oldState should equal .Pending but instead equals: \(oldState)")
                XCTAssertTrue(stateMachine.currentState == .Testing, "currentState should now equal .Testing but instead equals: \(stateMachine.currentState)")
                
                if let userInfo = userInfo where userInfo is Int {
                    let passedNumber = userInfo as! Int
                    XCTAssertTrue(passedNumber == myNumber, "userInfo should equal what is passed")
                } else {
                    XCTAssertTrue(false, "userInfo isn't valid")
                }
            }, afterChangingFromStates: .Pending)
        }
        catch {
            XCTAssertTrue(false, "Couldn't set an action")
            return
        }
        
        stateMachine.activate()
        
        do {
            try stateMachine.changeToState(.Testing, userInfo: myNumber)
        }
        catch {
            XCTAssertTrue(false, "Couldn't change to state .Testing")
            return
        }
        XCTAssertTrue(true, "Changed State")
    }

}
