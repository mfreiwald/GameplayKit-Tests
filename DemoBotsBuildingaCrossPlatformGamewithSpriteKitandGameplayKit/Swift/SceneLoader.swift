/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class encapsulating the work necessary to load a scene and its resources based on a given `SceneMetadata` instance.
*/

import GameplayKit

/*
    Use these constants with `NSNotificationCenter` to listen for events from the
    scene resource states.

    The `object` property of the notification will contain the `SceneLoader`.
*/
let SceneLoaderDidCompleteNotification = "DemoBots.SceneLoaderDidCompleteNotification"
let SceneLoaderDownloadFailedNotification = "DemoBots.SceneLoaderDownloadFailedNotification"

/// A class encapsulating the work necessary to load a scene and its resources based on a given `SceneMetadata` instance.
class SceneLoader: NSObject {
    // MARK: Properties
    
    lazy var stateMachine: GKStateMachine = {
        var states = [
            SceneLoaderInitialState(sceneLoader: self),
            SceneLoaderResourcesAvailableState(sceneLoader: self),
            SceneLoaderPreparingResourcesState(sceneLoader: self),
            SceneLoaderResourcesReadyState(sceneLoader: self)
        ]
        
        #if os(iOS)
        // States associated with on demand resources only apply to iOS.
        states += [
            SceneLoaderDownloadingResourcesState(sceneLoader: self),
            SceneLoaderDownloadFailedState(sceneLoader: self)
        ]
        #endif
        
        return GKStateMachine(states: states)
    }()
    
    /// The metadata describing the scene whose resources should be loaded.
    let sceneMetadata: SceneMetadata
    
    /// The actual scene after it has been successfully loaded. Set in `SceneLoaderResourcesReadyState`.
    var scene: BaseScene?
    
    /// The error, if one occurs, from fetching resources. Set in `SceneLoaderDownloadFailedState`.
    var error: NSError?
    
    #if os(iOS)
    /**
        The current `NSBundleResourceRequest` used to download the necessary resources.
        We keep a reference to the resource request so that it can be modified
        while it is in progress, and pin the resources when complete.
        
        For example: the `loadingPriority` is updated when the user reaches
        the loading scene, and the request is cancelled and released as part of
        cleaning up the scene loader.
    */
    var bundleResourceRequest: NSBundleResourceRequest?
    #endif

    /**
        A computed property that returns `true` if the scene's resources are expected
        to take a long time to load.
    */
    var requiresProgressSceneForPreparing: Bool {
        return !sceneMetadata.loadableTypes.filter { loader in
            loader.resourcesNeedLoading
        }.isEmpty
    }
    
    /**
        Indicates whether the scene we are loading has been requested to be presented
        to the user. Used to change how aggressively the resources are being made available.
    */
    var requestedForPresentation = false {
        didSet {
            /*
                Don't adjust resource loading priorities if `requestedForPresentation`
                was just set to `false`.
            */
            guard requestedForPresentation else { return }
            
            #if os(iOS)
            if stateMachine.currentState is SceneLoaderDownloadingResourcesState {
                /*
                    The presentation of this scene is blocked by downloading the
                    scene's resources, so mark the bundle resource request's loading
                    priority as urgent.
                */
                bundleResourceRequest?.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent
            }
            #endif
            
            if let preparingState = stateMachine.currentState as? SceneLoaderPreparingResourcesState {
                /*
                    The presentation of this scene is blocked by the preparation of
                    the scene's resources, so bump up the quality of service of
                    the operation queue that is preparing the resources.
                */
                preparingState.operationQueue.qualityOfService = .UserInteractive
            }
        }
    }
    
    // MARK: Initialization
    
    init(sceneMetadata: SceneMetadata) {
        self.sceneMetadata = sceneMetadata
        super.init()
        
        // Enter the initial state as soon as the scene loader is created.
        stateMachine.enterState(SceneLoaderInitialState)
    }
    
    #if os(iOS)
    /**
        Moves the state machine to the appropriate state when a request is made to
        download the `sceneLoader`'s scene.
    */
    func downloadResourcesIfNecessary() {
        if sceneMetadata.requiresOnDemandResources {
            stateMachine.enterState(SceneLoaderDownloadingResourcesState.self)
        }
        else {
            stateMachine.enterState(SceneLoaderResourcesAvailableState.self)
        }
    }
    #endif
    
    /// Ensures that the resources for a scene are downloaded and begins loading them into memory.
    func prepareSceneForPresentation() {
        // Begin preparing the scene's resources if they are available.
        if stateMachine.currentState is SceneLoaderResourcesAvailableState {
            stateMachine.enterState(SceneLoaderPreparingResourcesState.self)
            return
        }
        
        #if os(iOS)
        stateMachine.enterState(SceneLoaderDownloadingResourcesState.self)
        
        let downloadingState = stateMachine.stateForClass(SceneLoaderDownloadingResourcesState)!
        downloadingState.enterPreparingStateWhenFinished = true
        
        // Increase the priority for the requested scene because it is about to be presented.
        bundleResourceRequest?.loadingPriority = 0.8
        #endif
    }
    
    /// Cancels any pending requests for downloading or loading the resources for the `sceneLoader`'s scene.
    func cancelPendingResourceRequests() {
        #if os(iOS)
        if let downloadingState = stateMachine.currentState as? SceneLoaderDownloadingResourcesState {
            downloadingState.cancelDownload()
        }
        #endif
        
        if let preparingState = stateMachine.currentState as? SceneLoaderPreparingResourcesState {
            preparingState.cancelLoading()
        }
    }
    
    #if os(iOS)
    /// Marks the resources as no longer necessary.
    func purgeResources() {
        // Unpin any on demand resources.
        bundleResourceRequest?.endAccessingResources()
        
        // Release the loaded scene instance.
        scene = nil
        
        // Reset the state machine back to the initial state. 
        stateMachine.enterState(SceneLoaderInitialState)
    }
    #endif
}