/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An `SKScene` used to represent and manage the home and end scenes of the game.
*/

import SpriteKit

class HomeEndScene: BaseScene, ButtonNodeResponderType {
    // MARK: Properties
    
    /// Returns the background node from the scene.
    var backgroundNode: SKSpriteNode {
        return childNodeWithName("backgroundNode") as! SKSpriteNode
    }
    
    /// The screen recorder button for the scene (if it has one).
    var screenRecorderButton: ButtonNode? {
        return backgroundNode.childNodeWithName(ButtonIdentifier.ScreenRecorderToggle.rawValue) as? ButtonNode
    }
    
    /// The "NEW GAME" button which allows the player to proceed to the first level.
    var proceedButton: ButtonNode? {
        return backgroundNode.childNodeWithName(ButtonIdentifier.ProceedToNextScene.rawValue) as? ButtonNode
    }
    
    /// An array of objects for `SceneLoader` notifications.
    private var sceneLoaderNotificationObservers = [AnyObject]()

    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        nativeSize = backgroundNode.size
    }
    
    deinit {
        // Deregister for scene loader notifications.
        for observer in sceneLoaderNotificationObservers {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
    }
    
    // MARK: Scene Life Cycle

    override func didMoveToView(view: SKView) {
        super.didMoveToView(view)

        registerForNotifications()
        
        ButtonNode.parseButtonsInNode(backgroundNode)
        
        centerCameraOnPoint(backgroundNode.position)

        gameSession.startSession()

        #if os(OSX)
        screenRecorderButton?.hidden = true
        #else
        screenRecorderButton?.isSelected = screenRecordingToggleEnabled
        #endif
        
        // Begin loading the first level as soon as the view appears.
        sceneManager.prepareSceneForSceneIdentifier(.Level(1))
        
        let levelLoader = sceneManager.sceneLoaderForSceneIdentifier(.Level(1))
        /*
            If the first level is not ready, hide the `proceedButton`
            until we are notified.
        */
        if !(levelLoader.stateMachine.currentState is SceneLoaderResourcesReadyState) {
            proceedButton?.alpha = 0.0
            screenRecorderButton?.alpha = 0.0
        }
    }
    
    func registerForNotifications() {
        // Only register for notifications if we haven't done so already.
        guard sceneLoaderNotificationObservers.isEmpty else { return }
        
        // Create a block to pass as a notification handler for when the `SceneLoader` completes or fails.
        let handleSceneLoaderNotification: (NSNotification) -> () = { [unowned self] notification in
            let sceneLoader = notification.object as! SceneLoader
            
            // Show the proceed button if the `sceneLoader` pertains to a `LevelScene`.
            if sceneLoader.sceneMetadata.sceneType is LevelScene.Type {
                // Fade in the proceed button.
                self.proceedButton?.runAction(SKAction.fadeInWithDuration(1.0))
                self.screenRecorderButton?.runAction(SKAction.fadeInWithDuration(1.0))
            }
        }
        
        // Register for scene loader notifications.
        let completeNotification = NSNotificationCenter.defaultCenter().addObserverForName(SceneLoaderDidCompleteNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: handleSceneLoaderNotification)
        let failNotification = NSNotificationCenter.defaultCenter().addObserverForName(SceneLoaderDownloadFailedNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: handleSceneLoaderNotification)
        
        // Keep track of the notifications we are registered to so we can remove them in `deinit`.
        sceneLoaderNotificationObservers += [completeNotification, failNotification]
    }
    
    // MARK: ButtonNodeResponderType
    
    func buttonPressed(button: ButtonNode) {
        switch button.buttonIdentifier! {
            case .ProceedToNextScene:
                sceneManager.transitionToSceneWithSceneIdentifier(.NextLevel)
            
            case .Home:
                sceneManager.transitionToSceneWithSceneIdentifier(.Home)
            
            case .ScreenRecorderToggle:
                #if os(iOS)
                toggleScreenRecording(button)
                #endif
                
            default:
                fatalError("Unsupported ButtonNode type in HomeEndScene.")
        }
    }
}
