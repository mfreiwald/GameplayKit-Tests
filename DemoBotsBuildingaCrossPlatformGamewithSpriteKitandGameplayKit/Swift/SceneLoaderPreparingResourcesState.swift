/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `SceneLoader` to indicate that resources for the scene are being loaded into memory.
*/

import GameplayKit

class SceneLoaderPreparingResourcesState: GKState {
    // MARK: Properties
    
    unowned let sceneLoader: SceneLoader
    
    // The loading progress. Updated when discrete chunks of loading are completed.
    var progress = NSProgress()
    
    /// An internal operation queue for loading scene resources in the background.
    let operationQueue = NSOperationQueue()

    // MARK: Initialization
    
    init(sceneLoader: SceneLoader) {
        self.sceneLoader = sceneLoader
        
        // Set the name of the operation queue to identify the queue at run time.
        operationQueue.name = "com.example.apple-samplecode.sceneloaderpreparingresourcesstate"
        operationQueue.qualityOfService = .UserInitiated
        
        /*
            Set the total unit count to include the number of entities that
            need to be loaded plus the scene.
        */
        progress.totalUnitCount = sceneLoader.sceneMetadata.loadableTypes.count + 1
        
        // The `operationQueue` is cancellable, but not the progress object.
        progress.cancellable = false
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        super.didEnterWithPreviousState(previousState)

        // Reset the progress in preparation for new load operation.
        progress.completedUnitCount = 0
        
        // Begin loading the scene and associated resources in the background.
        loadResourcesAsynchronously()
    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        switch stateClass {
            // Only valid if the `sceneLoader`s scene has been set and the next state is ready.
            case is SceneLoaderResourcesReadyState.Type where sceneLoader.scene != nil:
                return true
            
            case is SceneLoaderResourcesAvailableState.Type:
                return true
            
            default:
                return false
        }
    }
    
    override func willExitWithNextState(nextState: GKState) {
        super.willExitWithNextState(nextState)
        
        // Create a new progress object for future downloads.
        progress = NSProgress()
    }
    
    // MARK: Load Resources
    
    func cancelLoading() {
        operationQueue.cancelAllOperations()
        
        // Move back to the available state.
        stateMachine?.enterState(SceneLoaderResourcesAvailableState.self)
    }
    
    /**
        Loads all resources specific to the requested scene with a series of block
        operations.

        Note: You must ensure the resources have been downloaded before calling 
        this method. Attempting to load the scene without the necessary 
        resources in local storage will result in a crash.
    */
    private func loadResourcesAsynchronously() {
        let sceneMetadata = sceneLoader.sceneMetadata
        
        var scene: BaseScene!
        let loadSceneOperation = NSBlockOperation {
            // Load the scene into memory using `SKNode(fileNamed:)`.
            scene = sceneMetadata.sceneType.sceneWithFileName(sceneMetadata.fileName)

            // Update progress.
            self.progress.completedUnitCount++
        }
        
        // Load all other assets associated with the scene.
        for loaderType in sceneMetadata.loadableTypes {
            let loadResourcesOperation = LoadResourcesOperation(loadableType: loaderType)
            loadResourcesOperation.qualityOfService = .Background
            loadResourcesOperation.completionBlock = {
                // Update progress.
                self.progress.completedUnitCount++
            }
            
            /*
                By adding a dependency on the `loadResourcesOperation`
                we ensure all the `loaderType`s associated with this scene will 
                be complete before the scene is loaded. Cross queue dependency is
                a feature of `NSOperation`s.
            */
            loadSceneOperation.addDependency(loadResourcesOperation)
            
            // Preload texture atlases on the `operationQueue`.
            operationQueue.addOperation(loadResourcesOperation)
        }
        
        // Add the scene operation to the queue.
        operationQueue.addOperation(loadSceneOperation)
        
        let proceedToReadyStateOperation = NSBlockOperation {
            // Set the `sceneLoader`s scene to hold onto for presentation.
            self.sceneLoader.scene = scene
            
            self.stateMachine!.enterState(SceneLoaderResourcesReadyState.self)
        }
        
        proceedToReadyStateOperation.addDependency(loadSceneOperation)
        
        // Proceed to the available state on the main queue.
        NSOperationQueue.mainQueue().addOperation(proceedToReadyStateOperation)
    }
}
