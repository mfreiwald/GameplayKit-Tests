/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The base class for all scenes in the app.
*/

import SpriteKit

#if os(iOS)
import ReplayKit
#endif

/**
    A base class for all of the scenes in the app.
*/
class BaseScene: SKScene, GameSessionDelegate, ControlInputSourceGameStateDelegate {
    // MARK: Properties

    #if os(iOS)
    /// ReplayKit preview view controller used when viewing recorded content.
    var previewViewController: RPPreviewViewController?
    #endif
    
    var nativeSize = CGSize.zeroSize
    
    var gameSession: GameSession! {
        didSet {
            // Listen for updates to the game session.
            gameSession.delegate = self
            
            #if os(iOS)
            /*
                Set up iOS touch controls. The player's `nativeControlInputSource`
                is added to the scene by the `BaseSceneTouchEventForwarding` extension.
            */
            addTouchInputToScene()
            #endif
        }
    }
    
    var overlay: SceneOverlay? {
        didSet {
            oldValue?.backgroundNode.removeFromParent()
            
            if let overlay = overlay, camera = camera {
                camera.addChild(overlay.backgroundNode)
                overlay.updateScale()
            }
        }
    }
    
    /**
        A weak reference to the scene manager to call `progressToNextScene()` 
        and `repeatCurrentScene()` for scene progression.
    */
    weak var sceneManager: SceneManager!
    
    // MARK: Initialization

    /** 
        We're using a factory method for initialization because we want to load
        the scene from a file, but `init(fileNamed:)` is not a designated initializer.
    */
    static func sceneWithFileName(fileName: String) -> Self {
        let scene = self(fileNamed: fileName)!

        // If the native size has not been set, store the initial size as its reference size.
        if scene.nativeSize == CGSize.zeroSize {
            scene.nativeSize = scene.size
        }

        let camera = SKCameraNode()
        scene.camera = camera
        scene.addChild(camera)
        
        scene.updateCameraScale()
        
        return scene
    }
    
    // MARK SKScene life cycle
    
    override func didMoveToView(view: SKView) {
        super.didMoveToView(view)
        
        updateCameraScale()
        overlay?.updateScale()
    }
    
    override func didChangeSize(oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        updateCameraScale()
        overlay?.updateScale()
    }
    
    // MARK: GameSessionDelegate
    
    func gameSessionDidUpdateControlInputSources(gameSession: GameSession) {
        // Setup all player controlInputSources to delegate game actions to `BaseScene`.
        for controlInputSource in gameSession.player.controlInputSources {
            controlInputSource.gameStateDelegate = self
        }
    }
    
    // MARK: ControlInputSourceGameStateDelegate

    func controlInputSourceDidTriggerAnyEvent(controlInputSource: ControlInputSourceType) {
        // Subclasses implement in response to any control event.
    }
    
    func controlInputSourceDidTogglePauseState(controlInputSource: ControlInputSourceType) {
        // Subclasses implement to toggle pause state.
    }
    
    #if DEBUG
    func controlInputSourceDidToggleDebugInfo(controlInputSource: ControlInputSourceType) {
        // Subclasses implement if necessary, to display useful debug info.
    }
    
    func controlInputSourceDidTriggerLevelSuccess(controlInputSource: ControlInputSourceType) {
        // Implemented by subclasses to switch to next level while debugging.
    }
    
    func controlInputSourceDidTriggerLevelFailure(controlInputSource: ControlInputSourceType) {
        // Implemented by subclasses to force failing the level while debugging.
    }
    #endif
    
    // MARK: Camera actions
    
    /// Centers the scene's camera on a given point.
    func centerCameraOnPoint(point: CGPoint) {
        if let camera = camera {
            camera.position = point
        }
    }
    
    /// Scales the scene's camera.
    func updateCameraScale() {
        /*
            Because the game is normally playing in landscape, use the scene's current and
            original heights to calulate the camera scale.
        */
        if let camera = camera {
            camera.setScale(nativeSize.height / size.height)
        }
    }
}
