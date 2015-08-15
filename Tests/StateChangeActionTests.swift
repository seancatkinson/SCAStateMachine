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
            try stateMachine.perform({ (destinationState, startingState, userInfo) -> () in
                print("Hello World")
            }, beforeChangingToStates: .Testing)
        }
        catch {
            XCTFail("Couldn't set an action")
            return
        }
    }
    
    func testCannotSetBeforeChangingActionsAfterActivation() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        stateMachine.activate()
        do {
            try stateMachine.perform(beforeChanging: { (destinationState, startingState, userInfo) -> () in
                print("Hello World")
            })
        }
        catch {
            return
        }
        XCTFail("Set an action after activation")
    }
    
    func testCannotSetBeforeChangingToActionsAfterActivation() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        stateMachine.activate()
        do {
            try stateMachine.perform({ (destinationState, startingState, userInfo) -> () in
                print("Hello World")
                }, beforeChangingToStates: .Testing)
        }
        catch {
            return
        }
        XCTFail("Set an action after activation")
    }
    
    func testCannotSetBeforeChangingFromActionsAfterActivation() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        stateMachine.activate()
        do {
            try stateMachine.perform({ (destinationState, startingState, userInfo) -> () in
                print("Hello World")
                }, beforeChangingFromStates: .Testing)
        }
        catch {
            return
        }
        XCTFail("Set an action after activation")
    }
    
    func testCannotSetAfterChangingToActionsAfterActivation() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        stateMachine.activate()
        do {
            try stateMachine.perform({ (destinationState, startingState, userInfo) -> () in
                print("Hello World")
                }, afterChangingToStates: .Testing)
        }
        catch {
            return
        }
        XCTFail("Set an action after activation")
    }
    
    func testCannotSetAfterChangingFromActionsAfterActivation() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        stateMachine.activate()
        do {
            try stateMachine.perform({ (destinationState, startingState, userInfo) -> () in
                print("Hello World")
                }, afterChangingFromStates: .Testing)
        }
        catch {
            return
        }
        XCTFail("Set an action after activation")
    }
    
    func testCannotSetAfterChangingActionsAfterActivation() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        stateMachine.activate()
        do {
            try stateMachine.perform(afterChanging:{ (destinationState, startingState, userInfo) -> () in
                print("Hello World")
                })
        }
        catch {
            return
        }
        XCTFail("Set an action after activation")
    }
    
    

    func testActionsFireInTheCorrectOrder() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        
        var myNumber:Int = 0
        
        do {
            try stateMachine.perform(beforeChanging: { (destinationState, startingState, userInfo) -> () in
                myNumber += 1
                XCTAssertEqual(myNumber, 1, "myNumber should equal 1")
            })
            
            try stateMachine.perform({ (destinationState, startingState, userInfo) -> () in
                myNumber += 10
                XCTAssertEqual(myNumber, 11, "myNumber should equal 11")
            }, beforeChangingFromStates: .Pending)
            
            try stateMachine.perform({ (destinationState, startingState, userInfo) -> () in
                myNumber += 100
                XCTAssertEqual(myNumber, 111, "myNumber should equal 111")
                }, beforeChangingToStates: .Testing)
            
            try stateMachine.perform({ (destinationState, startingState, userInfo) -> () in
                myNumber += 1000
                XCTAssertEqual(myNumber, 1111, "myNumber should equal 1111")
            }, afterChangingToStates: .Testing)

            try stateMachine.perform({ (destinationState, startingState, userInfo) -> () in
                myNumber += 10000
                XCTAssertEqual(myNumber, 11111, "myNumber should equal 11111")
            }, afterChangingFromStates: .Pending)
            
            try stateMachine.perform(afterChanging: { (destinationState, startingState, userInfo) -> () in
                myNumber += 100000
                XCTAssertEqual(myNumber, 111111, "myNumber should equal 111111")
            })
        }
        catch {
            XCTFail("Couldn't set an action")
            return
        }
        
        stateMachine.activate()
        
        do {
            try stateMachine.changeToState(.Testing, userInfo: nil)
        }
        catch {
            XCTFail("Couldn't change to state .Testing")
            return
        }
        XCTAssertEqual(myNumber, 111111, "myNumber should equal 111111")
    }
    
    func testCorrectStatesArePassedDuringStateChange() {
        var stateMachine = createTestStateMachine()
        addTestStateRulesToTestStateMachine(&stateMachine)
        
        let myNumber:Int = 8000
        
        do {
            try stateMachine.perform(beforeChanging: { (destinationState, startingState, userInfo) -> () in
                XCTAssertTrue(destinationState == TestStates.Testing, "destinationState should equal .Testing but instead equals: \(destinationState)")
                XCTAssertTrue(startingState == TestStates.Pending, "startingState should equal .Pending but instead equals: \(startingState)")
                XCTAssertTrue(stateMachine.currentState == .Pending, "currentState should still equal .Pending but instead equals: \(stateMachine.currentState)")
                
                if let userInfo = userInfo where userInfo is Int {
                    let passedNumber = userInfo as! Int
                    XCTAssertTrue(passedNumber == myNumber, "userInfo should equal what is passed")
                } else {
                    XCTFail("userInfo isn't valid")
                }
            })
            
            try stateMachine.perform({ (destinationState, startingState, userInfo) -> () in
                XCTAssertTrue(destinationState == TestStates.Testing, "destinationState should equal .Testing but instead equals: \(destinationState)")
                XCTAssertTrue(startingState == TestStates.Pending, "startingState should equal .Pending but instead equals: \(startingState)")
                XCTAssertTrue(stateMachine.currentState == .Pending, "currentState should still equal .Pending but instead equals: \(stateMachine.currentState)")
                
                if let userInfo = userInfo where userInfo is Int {
                    let passedNumber = userInfo as! Int
                    XCTAssertTrue(passedNumber == myNumber, "userInfo should equal what is passed")
                } else {
                    XCTFail("userInfo isn't valid")
                }
            }, beforeChangingToStates: .Testing)

            try stateMachine.perform({ (destinationState, startingState, userInfo) -> () in
                XCTAssertTrue(destinationState == TestStates.Testing, "destinationState should equal .Testing but instead equals: \(destinationState)")
                XCTAssertTrue(startingState == TestStates.Pending, "startingState should equal .Pending but instead equals: \(startingState)")
                XCTAssertTrue(stateMachine.currentState == .Pending, "currentState should still equal .Pending but instead equals: \(stateMachine.currentState)")
                
                if let userInfo = userInfo where userInfo is Int {
                    let passedNumber = userInfo as! Int
                    XCTAssertTrue(passedNumber == myNumber, "userInfo should equal what is passed")
                } else {
                    XCTFail("userInfo isn't valid")
                }
            }, beforeChangingFromStates: .Pending)
            
            try stateMachine.perform({ (destinationState, startingState, userInfo) -> () in
                XCTAssertTrue(destinationState == TestStates.Testing, "destinationState should equal .Testing but instead equals: \(destinationState)")
                XCTAssertTrue(startingState == TestStates.Pending, "startingState should equal .Pending but instead equals: \(startingState)")
                XCTAssertTrue(stateMachine.currentState == .Testing, "currentState should now equal .Testing but instead equals: \(stateMachine.currentState)")
                
                if let userInfo = userInfo where userInfo is Int {
                    let passedNumber = userInfo as! Int
                    XCTAssertTrue(passedNumber == myNumber, "userInfo should equal what is passed")
                } else {
                    XCTFail("userInfo isn't valid")
                }
            }, afterChangingToStates: .Testing)
            
            try stateMachine.perform({ (destinationState, startingState, userInfo) -> () in
                XCTAssertTrue(destinationState == TestStates.Testing, "destinationState should equal .Testing but instead equals: \(destinationState)")
                XCTAssertTrue(startingState == TestStates.Pending, "startingState should equal .Pending but instead equals: \(startingState)")
                XCTAssertTrue(stateMachine.currentState == .Testing, "currentState should now equal .Testing but instead equals: \(stateMachine.currentState)")
                
                if let userInfo = userInfo where userInfo is Int {
                    let passedNumber = userInfo as! Int
                    XCTAssertTrue(passedNumber == myNumber, "userInfo should equal what is passed")
                } else {
                    XCTFail("userInfo isn't valid")
                }
            }, afterChangingFromStates: .Pending)
            
            try stateMachine.perform(afterChanging: { (destinationState, startingState, userInfo) -> () in
                XCTAssertTrue(destinationState == TestStates.Testing, "destinationState should equal .Testing but instead equals: \(destinationState)")
                XCTAssertTrue(startingState == TestStates.Pending, "startingState should equal .Pending but instead equals: \(startingState)")
                XCTAssertTrue(stateMachine.currentState == .Testing, "currentState should still equal .Pending but instead equals: \(stateMachine.currentState)")
                
                if let userInfo = userInfo where userInfo is Int {
                    let passedNumber = userInfo as! Int
                    XCTAssertTrue(passedNumber == myNumber, "userInfo should equal what is passed")
                } else {
                    XCTFail("userInfo isn't valid")
                }
            })
        }
        catch {
            XCTFail("Couldn't set an action")
            return
        }
        
        stateMachine.activate()
        
        do {
            try stateMachine.changeToState(.Testing, userInfo: myNumber)
        }
        catch {
            XCTFail("Couldn't change to state .Testing")
            return
        }
    }

}
