/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension of `BaseScene` to provide iOS platform specific functionality. This file is only included in the iOS target.
*/

import UIKit

/*
    Extend `BaseScene` to forward events from the scene to a platform-specific
    control input source. On iOS, this is a `TouchControlInputSource`, which is
    overlaid on the scene to receive touch events.
*/
extension BaseScene {
    // MARK: Properties
    
    var touchControlInputSource: TouchControlInputSource {
        return gameSession.player.nativeControlInputSource as! TouchControlInputSource
    }
    
    // MARK: Setup Touch Handling
    
    func addTouchInputToScene() {
        guard let camera = camera else { fatalError("Touch input controls can only be added to a scene that has an associated camera.") }
        
        // Ensure the touch input source is not associated any other parent.
        touchControlInputSource.removeFromParent()
        
        if self is LevelScene {
            // Ensure the control node fills the scene's size.
            touchControlInputSource.size = size
            
            // Center the control node on the camera.
            touchControlInputSource.position = CGPointZero

            /*
                Assign a `zPosition` that is above in-game elements, but below the top
                layer where buttons are added.
            */
            touchControlInputSource.zPosition = WorldLayer.Top.rawValue - CGFloat(1.0)
            
            // Add the control node to the camera node so the controls remain stationary as the camera moves.
            camera.addChild(touchControlInputSource)
            
            // Make sure the controls are visible.
            touchControlInputSource.hideThumbStickControls = false
        }
    }
}