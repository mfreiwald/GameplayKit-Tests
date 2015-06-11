/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `SceneLoader` to indicate that all of the resources for the scene are loaded into memory and ready for use. This is the final state in the `SceneLoader`'s state machine.
*/

import GameplayKit

class SceneLoaderResourcesReadyState: GKState {
    // MARK: Properties
    
    unowned let sceneLoader: SceneLoader
    
    // MARK: Initialization
    
    init(sceneLoader: SceneLoader) {
        self.sceneLoader = sceneLoader
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        super.didEnterWithPreviousState(previousState)

        // Notify to any interested objects that the download has completed.
        NSNotificationCenter.defaultCenter().postNotificationName(SceneLoaderDidCompleteNotification, object: sceneLoader)
    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        switch stateClass {
            case is SceneLoaderResourcesAvailableState.Type, is SceneLoaderInitialState.Type:
                return true
            
            default:
                return false
        }
    }
    
    /// Returns the loaded scene and moves back to the "resources available" state.
    func vendLoadedScene() -> BaseScene {
        guard let scene = sceneLoader.scene else { fatalError("The scene is not available.") }
        /*
            Vending the scene is a one shot operation. The scene will need to be
            loaded again the next time it is presented.
        */
        sceneLoader.scene = nil
        stateMachine!.enterState(SceneLoaderResourcesAvailableState)
        
        return scene
    }
}