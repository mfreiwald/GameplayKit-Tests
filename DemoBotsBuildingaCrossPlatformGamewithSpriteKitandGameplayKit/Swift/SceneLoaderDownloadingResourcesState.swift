/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `SceneLoader` to indicate that the loader is currently downloading on demand resources.
*/

import GameplayKit

class SceneLoaderDownloadingResourcesState: GKState {
    // MARK: Properties
    
    unowned let sceneLoader: SceneLoader
    
    /// Optionally progress directly to preparing state when download completes.
    var enterPreparingStateWhenFinished = false
    
    // MARK: Initialization
    
    init(sceneLoader: SceneLoader) {
        self.sceneLoader = sceneLoader
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        super.didEnterWithPreviousState(previousState)
        
        /*
            `NSBundleResourceRequest`s are single use objects.
            Create a new bundle request every time downloading needs to begin.
        */
        sceneLoader.bundleResourceRequest = NSBundleResourceRequest(tags: sceneLoader.sceneMetadata.onDemandResourcesTags)
        
        beginDownloadingScene()
    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        switch stateClass {
            case is SceneLoaderDownloadFailedState.Type, is SceneLoaderResourcesAvailableState.Type, is SceneLoaderPreparingResourcesState.Type:
                return true
                
            default:
                return false
        }
    }
    
    // MARK: Downloading Actions
    
    /**
        Cancels an in flight download. This will cause the completionHandler to
        be invoked on `beginAccessingResourcesWithCompletionHandler(_:)`
        with an NSUserCancelledError. See NSBundleResourceRequest the documentation
        for more information.
    */
    func cancelDownload() {
        // Cancel the request if it's in flight.
        if let bundleResourceRequest = sceneLoader.bundleResourceRequest {
            bundleResourceRequest.progress.cancel()
            bundleResourceRequest.endAccessingResources()
        }
    }

    /// Loads the scene into local storage.
    private func beginDownloadingScene() {
        guard let bundleResourceRequest = sceneLoader.bundleResourceRequest else { fatalError("The resource request does not exist.") }
        
        // Begin downloading the on demand resources.
        bundleResourceRequest.beginAccessingResourcesWithCompletionHandler { error in
            // Progress to the next appropriate state from the main queue.
            dispatch_async(dispatch_get_main_queue()) {
                if let error = error {
                    // Release the resources because we'll need to start a new request.
                    bundleResourceRequest.endAccessingResources()
                    
                    // Set the error on the sceneLoader. 
                    self.sceneLoader.error = error
                    
                    self.stateMachine!.enterState(SceneLoaderDownloadFailedState.self)
                }
                if self.enterPreparingStateWhenFinished {
                    // If requested, proceed to the preparing state immediately.
                    self.stateMachine!.enterState(SceneLoaderPreparingResourcesState.self)
                }
                else {
                    self.stateMachine!.enterState(SceneLoaderResourcesAvailableState.self)
                }
            }
        }
    }
}