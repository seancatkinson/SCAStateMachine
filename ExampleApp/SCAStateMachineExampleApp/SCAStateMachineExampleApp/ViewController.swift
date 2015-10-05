//
//  ViewController.swift
//  SCAStateMachineExampleApp
//
//  Created by Sean C Atkinson on 05/10/2015.
//  Copyright © 2015 seancatkinson. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    enum Colour : String, CustomStringConvertible {
        case White, Blue, Red
        
        var description : String {
            return self.rawValue
        }
    }
    
    let backgroundQueue = dispatch_queue_create("an example background queue", DISPATCH_QUEUE_SERIAL)
    var machine : StateMachine<Colour>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a state machine with a initial state 
        // we'll set the target queue to a background queue we've created for
        // the sake of the example. Any actions you add to be performed will be
        // dispatched to this queue - unless you override it
        machine = StateMachine(withStartingState: Colour.White, targetQueue: self.backgroundQueue)
        
        // blue and red can move between each other
        // white can move to anything but can never go back...
        // if we don't add any rules, all changes are allowed - assuming no 
        // additional conditions are defined
        // define rules in the order you're most comfortable with 
        // from -> to  /  to -> from
        machine.addStateChangeRulesFrom(.Red, .White, toDestinationState: .Blue)
        machine.addStateChangeRulesTo(.Red, fromStartingStates: .Blue, .White)
        
        
        // add some conditions that must pass before a change will be allowed
        // to prevent a change, simply throw an error from your condition
        // the error will automatically bubble up to your do/try/catch
        machine.checkConditionBeforeChangingFrom(.Blue) { (destinationState, startingState, userInfo) throws -> () in
            print("Check a condition before we move FROM Blue")
            print("We are currently: \(startingState)")
            print("We want to move to: \(destinationState)")
        }
        machine.checkConditionBeforeChangingTo(.Blue) { (destinationState, startingState, userInfo) throws -> () in
            print("Check a condition before we move TO Blue")
            print("We are currently: \(startingState)")
            print("We want to move to: \(destinationState)")
        }
        
        
        // add some actions to be performed when changing
        // this will get performed on the target queue we defined when we 
        // initialised the state machine
        machine.performAfterChanging { (destinationState, startingState, userInfo) -> () in
            print("I get performed after every change on our background thread")
            print("We were: \(startingState)")
            print("We are now: \(destinationState)")
        }

        // because we're doing UI work, let's override the target queue to be
        // the main queue
        machine.performAfterChangingTo(.Blue, onQueue:dispatch_get_main_queue()) { (destinationState, startingState, userInfo) -> () in
            print("We just changed to Blue")
            self.view.backgroundColor = UIColor.blueColor()
        }
        machine.performAfterChangingTo(.Red, onQueue:dispatch_get_main_queue()) { (destinationState, startingState, userInfo) -> () in
            print("We just changed to Red")
            self.view.backgroundColor = UIColor.redColor()
        }
    }
    
    @IBAction func blueButtonPressed() {
        do {
            try machine.changeToState(.Blue)
        }
        catch {
            print("An error occurred when changing the background to blue")
        }
    }
    
    @IBAction func redButtonPressed() {
        do {
            try machine.changeToState(.Red)
        }
        catch {
            print("An error occurred when changing the background to red")
        }
    }


}

