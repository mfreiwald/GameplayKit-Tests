/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An implementation of the `ControlInputSourceType` protocol that enables support for keyboard input on OS X.
*/

import Cocoa
import simd

class KeyboardControlInputSource: ControlInputSourceType {
    // MARK: Properties
    
    /// The vector used to keep track of movement.
    var currentDisplacement = float2()
    
    /// Bookkeeping to ignore repeating keys.
    var downKeys = Set<Character>()
    
    /// `ControlInputSourceType` delegates.
    weak var gameStateDelegate: ControlInputSourceGameStateDelegate? {
        didSet {
            // When the delegate is assigned, flush the tracked keys.
            downKeys.removeAll()
        }
    }
    
    weak var delegate: ControlInputSourceDelegate? {
        didSet {
            // When the delegate is assigned, reset the control state.
            downKeys.removeAll()
            currentDisplacement = float2()
        }
    }
    
    /// Values representing different relative motions the keyboard is capable of supplying.
    static let forwardVector          = float2(x: 1, y: 0)
    static let backwardVector         = float2(x: -1, y: 0)
    static let clockwiseVector        = float2(x: 0, y: -1)
    static let counterClockwiseVector = float2(x: 0, y: 1)
    
    // MARK: Control Handling
    
    func handleMouseDownEvent() {
        delegate?.controlInputSourceDidBeginAttacking(self)
        gameStateDelegate?.controlInputSourceDidTriggerAnyEvent(self)
    }
    
    func handleMouseUpEvent() {
        delegate?.controlInputSourceDidFinishAttacking(self)
    }
    
    /// The logic matching a key press to `ControlInputSourceDelegate` calls.
    func handleKeyDownForCharacter(character: Character) {
        // Ignore repeat input.
        if downKeys.contains(character) {
            return
        }
        downKeys.insert(character)
        
        // Retrieve the relativeDisplacement vector mapped for each character: WASD and arrow keys.
        if let relativeDisplacement = relativeDisplacementForCharacter(character) {
            /*
                If the displacement is directional: forward or backwards, 
                add to the current displacement.
            */
            if isDirectionalDisplacementVector(relativeDisplacement) {
                currentDisplacement += relativeDisplacement
                
                // Normalize the displacement so its magnitude is between [0.0 - ±1.0].
                if length(currentDisplacement) > 0.0 {
                    currentDisplacement = normalize(currentDisplacement)
                }

                delegate?.controlInputSource(self, didUpdateWithRelativeDisplacement: currentDisplacement)
            }
            else if isRotationalDisplacementVector(relativeDisplacement) {
                delegate?.controlInputSource(self, didUpdateWithRelativeAngularDisplacement: relativeDisplacement)
            }
            else {
                fatalError("Invalid relative displacement.")
            }
        }
        else if isAttackCharacter(character) {
            // An attack command was requested.
            delegate?.controlInputSourceDidBeginAttacking(self)
        }
        else {
            // Account for the other possible kinds of actions.
            #if DEBUG
            switch character {
                case "/":
                    gameStateDelegate?.controlInputSourceDidToggleDebugInfo(self)
                
                case "[":
                    gameStateDelegate?.controlInputSourceDidTriggerLevelSuccess(self)
                
                case "]":
                    gameStateDelegate?.controlInputSourceDidTriggerLevelFailure(self)
              
                default: ()
            }
            #endif
        }
        
        gameStateDelegate?.controlInputSourceDidTriggerAnyEvent(self)
    }
    
    // Handle the logic matching when a key is released to `ControlInputSource` delegate calls.
    func handleKeyUpForCharacter(character: Character) {
        downKeys.remove(character)
        
        // Retrieve the relativeDisplacement vector mapped for each character: WASD and arrow keys.
        if let relativeDisplacement = relativeDisplacementForCharacter(character) {
            /*
                If the displacement is directional: forward or backwards,
                subtract from the current displacement.
            */
            if isDirectionalDisplacementVector(relativeDisplacement) {
                currentDisplacement -= relativeDisplacement
                
                // Normalize the displacement so its magnitude is between [0.0 - ±1.0].
                if length(currentDisplacement) > 0.0 {
                    currentDisplacement = normalize(currentDisplacement)
                }
                
                delegate?.controlInputSource(self, didUpdateWithRelativeDisplacement: currentDisplacement)
            }
            else if isRotationalDisplacementVector(relativeDisplacement) {
                // Stop any existing rotation.
                delegate?.controlInputSource(self, didUpdateWithRelativeAngularDisplacement: float2())
            }
            else {
                fatalError("Invalid relative displacement.")
            }
        }
        else if isAttackCharacter(character) {
            // An attack command finished.
            delegate?.controlInputSourceDidFinishAttacking(self)
        }
        else {
            // Account for the other possible kinds of actions.
            switch character {
                case "p":
                    gameStateDelegate?.controlInputSourceDidTogglePauseState(self)

                default: ()
            }
        }
    }
    
    // MARK: Convenience Functions
    
    private func isDirectionalDisplacementVector(displacement: float2) -> Bool {
        return displacement == KeyboardControlInputSource.forwardVector
            || displacement == KeyboardControlInputSource.backwardVector
    }
    
    private func isRotationalDisplacementVector(displacement: float2) -> Bool {
        return displacement == KeyboardControlInputSource.counterClockwiseVector
            || displacement == KeyboardControlInputSource.clockwiseVector
    }
    
    private func relativeDisplacementForCharacter(character: Character) -> float2? {
        let mapping: [Character: float2] = [
            // Up arrow.
            Character(UnicodeScalar(0xF700)):   KeyboardControlInputSource.forwardVector,
            "w":                                KeyboardControlInputSource.forwardVector,
            
            // Down arrow.
            Character(UnicodeScalar(0xF701)):   KeyboardControlInputSource.backwardVector,
            "s":                                KeyboardControlInputSource.backwardVector,
            
            // Left arrow.
            Character(UnicodeScalar(0xF702)):   KeyboardControlInputSource.counterClockwiseVector,
            "a":                                KeyboardControlInputSource.counterClockwiseVector,
            
            // Right arrow.
            Character(UnicodeScalar(0xF703)):   KeyboardControlInputSource.clockwiseVector,
            "d":                                KeyboardControlInputSource.clockwiseVector
        ]
        
        return mapping[character]
    }
    
    /// Indicates whether the provided character should trigger an attack.
    private func isAttackCharacter(character: Character) -> Bool {
        return ["f", " "].contains(character)
    }
}
