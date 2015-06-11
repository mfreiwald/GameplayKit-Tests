/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An implementation of the `ControlInputSourceType` protocol that enables support for `GCController`s on iOS and OS X.
*/

import SpriteKit
import GameController

class GameControllerInputSource: ControlInputSourceType {
    // MARK: Properties
    
    /// `ControlInputSourceType` delegates.
    weak var delegate: ControlInputSourceDelegate?
    weak var gameStateDelegate: ControlInputSourceGameStateDelegate?
    
    let gameController: GCController

    // MARK: Initializers
    
    init(gameController: GCController) {
        self.gameController = gameController
        
        registerPauseEvent()
        registerAttackEvents()
        registerMovementEvents()
        registerRotationEvents()
    }
    
    // MARK: Gamepad Registration Methods
    
    private func registerPauseEvent() {
        gameController.controllerPausedHandler = { _ in
            self.gameStateDelegate?.controlInputSourceDidTogglePauseState(self)
        }
    }
    
    private func registerAttackEvents() {
        /// A handler for button press events that trigger an attack action.
        let attackHandler: (GCControllerButtonInput, Float, Bool) -> Void = { [unowned self] _, _, pressed in
            if pressed {
                self.delegate?.controlInputSourceDidBeginAttacking(self)
                self.gameStateDelegate?.controlInputSourceDidTriggerAnyEvent(self)
            }
            else {
                self.delegate?.controlInputSourceDidFinishAttacking(self)
            }
        }
    
        // `GCGamepad` button handlers.
        if let gamepad = gameController.gamepad {
            /*
                Assign an action to every button, even if this means that multiple
                buttons provide the same functionality. It's better to have repeated
                functionality than to have a button that doesn't do anything.
            */
            gamepad.buttonA.pressedChangedHandler = attackHandler
            gamepad.buttonB.pressedChangedHandler = attackHandler
            gamepad.buttonX.pressedChangedHandler = attackHandler
            gamepad.buttonY.pressedChangedHandler = attackHandler
            gamepad.leftShoulder.pressedChangedHandler = attackHandler
            gamepad.rightShoulder.pressedChangedHandler = attackHandler
        }
        
        // `GCExtendedGamepad` trigger handlers.
        if let extendedGamepad = gameController.extendedGamepad {
            extendedGamepad.rightTrigger.pressedChangedHandler = attackHandler
            extendedGamepad.leftTrigger.pressedChangedHandler  = attackHandler
        }
    }
    
    private func registerMovementEvents() {
        /// An analog movement handler for D-pads and movement thumbsticks.
        let movementHandler: (GCControllerDirectionPad, Float, Float) -> Void = { [unowned self] _, xValue, yValue in
            // Move toward the direction of the axis.
            let displacement = float2(x: xValue, y: yValue)
            
            self.delegate?.controlInputSource(self, didUpdateDisplacement: displacement)
        }
        
        // `GCGamepad` D-pad handler.
        if let gamepad = gameController.gamepad {
            gamepad.dpad.valueChangedHandler = movementHandler 
        }
        
        // `GCExtendedGamepad` left thumbstick.
        if let extendedGamepad = gameController.extendedGamepad {
            extendedGamepad.leftThumbstick.valueChangedHandler = movementHandler
        }
    }
    
    private func registerRotationEvents() {
        // `GCExtendedGamepad` right thumbstick controls rotational attack independent of movement direction.
        if let extendedGamepad = gameController.extendedGamepad {
        
            extendedGamepad.rightThumbstick.valueChangedHandler = { [unowned self] _, xValue, yValue in
                // Rotate by the angle formed from the supplied axis.
                let angularDisplacement = float2(x: xValue, y: yValue)
                
                self.delegate?.controlInputSource(self, didUpdateAngularDisplacement: angularDisplacement)
                
                // Attack while rotating. This closely mirrors the behavior of the iOS touch controls.
                if length(angularDisplacement) > 0 {
                    self.delegate?.controlInputSourceDidBeginAttacking(self)
                }
                else {
                    self.delegate?.controlInputSourceDidFinishAttacking(self)
                }
            }
            
        }
    }
}

