/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used to represent the `TaskBot` when being zapped by a `PlayerBot` attack.
*/

import SpriteKit
import GameplayKit

class TaskBotZappedState: GKState {
    // MARK: Properties
    
    unowned var entity: TaskBot
    
    /// The amount of time the `TaskBot` has been in its "zapped" state.
    var elapsedTime: NSTimeInterval = 0.0
    
    /// The `AnimationComponent` associated with the `entity`.
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.componentForClass(AnimationComponent.self) else { fatalError("A TaskBotZappedState's entity must have an AnimationComponent.") }
        return animationComponent
    }

    // MARK: Initializers
    
    required init(entity: TaskBot) {
        self.entity = entity
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        super.didEnterWithPreviousState(previousState)
        
        // Reset the elapsed time.
        elapsedTime = 0.0

        // Check if the `TaskBot` has a movement component. (`GroundBot`s do, `FlyingBot`s do not.)
        if let movementComponent = entity.componentForClass(MovementComponent.self) {
            // Clear any pending movement.
            movementComponent.nextTranslation = nil
            movementComponent.nextRotation = nil

        }
            
        // Request the "zapped" animation for this `TaskBot`.
        animationComponent.requestedAnimationState = .Zapped
    }

    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        super.updateWithDeltaTime(seconds)
        
        elapsedTime += seconds
        
        /*
            If the `TaskBot` has become "good" or has been in the current state long enough,
            re-enter `TaskBotAgentControlledState`.
        */
        if entity.isGood || elapsedTime >= GameplayConfiguration.TaskBot.zappedStateDuration {
            stateMachine?.enterState(TaskBotAgentControlledState.self)
        }
    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        switch stateClass {
            case is TaskBotZappedState.Type, is TaskBotAgentControlledState.Type, is FlyingBotBlastState.Type:
                return true
                
            default:
                return false
        }
    }
}
