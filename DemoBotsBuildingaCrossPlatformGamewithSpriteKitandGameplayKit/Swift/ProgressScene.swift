/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A scene used to indicate the progress of loading additional content between scenes.
*/

import SpriteKit

/**
    The KVO context for `ProgressScene` instances. This provides a stable
    address to use as the `context` parameter for the KVO observation methods.
*/
private var progressSceneKVOContext = 0

class ProgressScene: BaseScene, ButtonNodeResponderType {
    // MARK: Properties
    
    var backgroundNode: SKSpriteNode {
        return childNodeWithName("backgroundNode") as! SKSpriteNode
    }
    
    var loadingLabelNode: SKLabelNode {
        return backgroundNode.childNodeWithName("loadingLabel") as! SKLabelNode
    }
    
    var errorLabelNode: SKLabelNode {
        return backgroundNode.childNodeWithName("errorLabel") as! SKLabelNode
    }
    
    var progressBarNode: SKSpriteNode {
        return backgroundNode.childNodeWithName("progressBar") as! SKSpriteNode
    }
    
    /*
        Because we're using a factory method for initialization (we want to load
        the scene from a file, but `init(fileNamed:)` is not a designated init),
        we need to make most of the properties `var` and implicitly unwrapped
        optional so we can set the properties after creating the scene with
        `progressSceneWithSceneLoader(sceneLoader:)`.
    */
    
    /// The scene loader currently handling the requested scene.
    var sceneLoader: SceneLoader!
    
    /// Keeps track of the progress bar's initial width.
    var progressBarInitialWidth: CGFloat!
    
    /// Add child progress objects to track downloading and loading states.
    var progress: NSProgress? {
        didSet {
            // Unregister as an observer on the old value for the "fractionComplete" property.
            oldValue?.removeObserver(self, forKeyPath: "fractionComplete", context: &progressSceneKVOContext)

            // Register as an observer on the initial and for changes to the "fractionCompleted" property.
            progress?.addObserver(self, forKeyPath: "fractionCompleted", options: [.New, .Initial], context: &progressSceneKVOContext)
        }
    }
    
    /// A registered observer object for `SceneLoaderDownloadFailedNotification`s.
    private var downloadFailedObserver: AnyObject?
    
    // MARK: Initializers
    
    /**
        Constructs a `ProgressScene` that will monitor the download
        progress of on demand resources and the loading progress of bringing
        assets into memory.
    */
    static func progressSceneWithSceneLoader(sceneLoader: SceneLoader) -> Self {
        // Load the progress scene from it's sks file.
        let progressScene = self.sceneWithFileName("ProgressScene")
        
        progressScene.setupWithSceneLoader(sceneLoader)
        
        // Return the setup progress scene.
        return progressScene
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        nativeSize = backgroundNode.size
    }
    
    func setupWithSceneLoader(sceneLoader: SceneLoader) {
        // Set the sceneLoader. This may be in the downloading or preparing state.
        self.sceneLoader = sceneLoader
        
        /*
            Set the progress as the preparing state progress because loading
            the scene is guaranteed to pass through this state. Progress
            specific to downloading can be added as a child to this progress object.
        */
        guard let preparingState = sceneLoader.stateMachine.stateForClass(SceneLoaderPreparingResourcesState) else { fatalError("PreparingResourcesState does not exist.") }
        progress = preparingState.progress
        
        #if os(iOS)
        if let downloadingState = sceneLoader.stateMachine.currentState as? SceneLoaderDownloadingResourcesState {
            downloadingState.enterPreparingStateWhenFinished = true
            
            /*
                Add the bundle resource request's progress as a child to the
                existing progress to monitor the download, and increment the total
                unit count to account for this additional progress.
            */
            progress?.totalUnitCount++
            progress?.addChild(sceneLoader.bundleResourceRequest!.progress, withPendingUnitCount: 1)
        }
        #endif
        
        // Register for notifications posted when the `SceneDownloader` fails.
        downloadFailedObserver = NSNotificationCenter.defaultCenter().addObserverForName(SceneLoaderDownloadFailedNotification, object: sceneLoader, queue: nil) { [unowned self] _ in
            // Display the error state.
            self.showErrorState()
        }
    }
    
    deinit {
        // Unregister as an observer of 'SceneLoaderDownloadFailedNotification' notifications.
        if let downloadFailedObserver = downloadFailedObserver {
            NSNotificationCenter.defaultCenter().removeObserver(downloadFailedObserver, name: SceneLoaderDownloadFailedNotification, object: sceneLoader)
        }
        
        // Set the progress property to nil which will remove this object as an observer.
        progress = nil
    }
    
    // MARK: Scene Life Cycle
    
    override func didMoveToView(view: SKView) {
        centerCameraOnPoint(backgroundNode.position)

        // Remember the progress bar's initial width. It will change to indicate progress.
        progressBarInitialWidth = progressBarNode.frame.width
        
        // Convert any button template nodes to `ButtonNode`s.
        ButtonNode.parseButtonsInNode(backgroundNode)
        
        // Show the default state of the progress scene if there is no error to show.
        if sceneLoader.error == nil {
            showDefaultState()
        }
        else {
            showErrorState()
        }
    }
    
    // MARK: Key Value Observing (KVO) for NSProgress
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [NSObject: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        // Check if this is the KVO notification we need.
        if context == &progressSceneKVOContext && keyPath == "fractionCompleted" && object === progress {
            // Do not update the progress if an error has occurred.
            guard sceneLoader.error == nil else { return }
            
            // Update the progress UI on the main queue.
            dispatch_async(dispatch_get_main_queue()) {
                guard let progress = self.progress else { return }
        
                // Update the progress bar to match the amount of progress completed.
                self.progressBarNode.size.width = self.progressBarInitialWidth * CGFloat(progress.fractionCompleted)
                
                // Display a contextually specific progress description.
                self.loadingLabelNode.text = progress.localizedDescription
            }
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: ButtonNodeResponderType
    
    func buttonPressed(button: ButtonNode) {
        switch button.buttonIdentifier! {
            case .Retry:
                showDefaultState()
                sceneManager.prepareSceneForSceneIdentifier(.CurrentLevel)
            
            case .Home:
                sceneManager.transitionToSceneWithSceneIdentifier(.Home)
            
            case .Cancel:
                sceneLoader.cancelPendingResourceRequests()
                showErrorState()
            
            default:
                fatalError("Unsupported ButtonNode type in ProgressScene.")
        }
    }
    
    // MARK: Convenience
    
    func buttonWithIdentifier(identifier: ButtonIdentifier) -> ButtonNode? {
        return backgroundNode.childNodeWithName(identifier.rawValue) as? ButtonNode
    }
    
    func showErrorState() {
        // Cancel the progress as downloading has stopped.
        progress?.cancel()
        
        errorLabelNode.hidden = false
        
        // Display the localized recovery suggestion if available.
        if let recoverySuggestion = sceneLoader.error?.localizedRecoverySuggestion {
            errorLabelNode.text = recoverySuggestion
        }
        else {
            // Display a generic error message if a specific localized recovery suggestion is not available.
            errorLabelNode.text = NSLocalizedString("Unable to load the next level.", comment: "Displayed when the scene loader does not have a more specific recovery suggestion.")
        }

        // Display "Quit" and "Retry" buttons.
        buttonWithIdentifier(.Home)?.hidden = false
        buttonWithIdentifier(.Retry)?.hidden = false
        buttonWithIdentifier(.Cancel)?.hidden = true

        // Hide normal state.
        loadingLabelNode.hidden = true
        progressBarNode.hidden = true
        progressBarNode.size.width = 0.0
    }
    
    func showDefaultState() {
        // Resume the progress. 
        progress?.resume()
        
        progressBarNode.hidden = false
        loadingLabelNode.hidden = false
        
        // Hide error state.
        errorLabelNode.hidden = true

        buttonWithIdentifier(.Home)?.hidden = true
        buttonWithIdentifier(.Retry)?.hidden = true
        buttonWithIdentifier(.Cancel)?.hidden = false
    }
}
