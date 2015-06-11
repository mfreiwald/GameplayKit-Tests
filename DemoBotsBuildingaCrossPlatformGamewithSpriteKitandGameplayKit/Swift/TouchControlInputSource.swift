/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An implementation of the `ControlInputSourceType` protocol that enables support for touch-based thumbsticks on iOS.
*/

import SpriteKit

class TouchControlInputSource: SKSpriteNode, ThumbStickControlDelegate, ControlInputSourceType {
    // MARK: Properties
    
    /// `ControlInputSourceType` delegates.
    weak var delegate: ControlInputSourceDelegate?
    weak var gameStateDelegate: ControlInputSourceGameStateDelegate?
    
    /// Analog thumb stick controls for the left and right half of the screen.
    let leftThumbStickControl: ThumbStickControl
    let rightThumbStickControl: ThumbStickControl
    
    /// Node representing the touch area for the pause button.
    let pauseButton: SKSpriteNode
    
    /// Sets used to keep track of touches, and their relevant controls.
    var leftControlTouches = Set<UITouch>()
    var rightControlTouches = Set<UITouch>()
    
    /// The width of the zone in the center of the screen where the touch controls cannot be placed.
    let centerDividerWidth: CGFloat
    var hideThumbStickControls: Bool = false {
        didSet {
            leftThumbStickControl.hidden = hideThumbStickControls
            rightThumbStickControl.hidden = hideThumbStickControls
        }
    }
    
    // MARK: Initialization
    
    /*
        `TouchControlInputSource` is intended as an overlay for the entire screen,
        therefore the `frame` is usually the scene's bounds or something equivalent.
    */
    init(frame: CGRect, thumbStickControlSize: CGSize) {
        // An approximate width appropriate for different scene sizes.
        centerDividerWidth = frame.width / 4.5
        
        // Setup the thumbStickControls.
        let initialVerticalOffset = -thumbStickControlSize.height
        let initialHorizontalOffset = frame.width / 2 - thumbStickControlSize.width
        
        leftThumbStickControl = ThumbStickControl(size: thumbStickControlSize)
        leftThumbStickControl.position = CGPoint(x: -initialHorizontalOffset, y: initialVerticalOffset)
        
        rightThumbStickControl = ThumbStickControl(size: thumbStickControlSize)
        rightThumbStickControl.position = CGPoint(x: initialHorizontalOffset, y: initialVerticalOffset)
        
        // Setup pause button.
        let buttonSize = CGSize(width: frame.height / 4, height: frame.height / 4)
        pauseButton = SKSpriteNode(texture: nil, color: UIColor.clearColor(), size: buttonSize)
        pauseButton.position = CGPoint(x: 0, y: frame.height / 2)
        
        super.init(texture: nil, color: UIColor.clearColor(), size: frame.size)
        rightThumbStickControl.delegate = self
        leftThumbStickControl.delegate = self
        
        addChild(leftThumbStickControl)
        addChild(rightThumbStickControl)
        addChild(pauseButton)
        
        /*
            `TouchControlInputSource` receives all user interaction and 
            forwards it along to the child controls.
        */
        userInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: ThumbStickControlDelegate
    
    func thumbStickControl(thumbStickControl: ThumbStickControl, didUpdateXValue xValue: Float, yValue: Float) {
        // Determine which control this update is relevant to by comparing it to the references.
        if thumbStickControl === leftThumbStickControl {
            let displacement = float2(x: xValue, y: yValue)
            delegate?.controlInputSource(self, didUpdateDisplacement: displacement)
        }
        else if thumbStickControl === rightThumbStickControl {
            let displacement = float2(x: xValue, y: yValue)
            
            // Rotate the character only if the `thumbStickControl` is sufficiently displaced.
            if length(displacement) >= GameplayConfiguration.TouchControl.minimumRequiredThumbstickDisplacement {
                delegate?.controlInputSource(self, didUpdateAngularDisplacement: displacement)
            }
            else {
                delegate?.controlInputSource(self, didUpdateAngularDisplacement: float2())
            }
        }
    }
    
    func thumbStickControl(thumbStickControl: ThumbStickControl, isPressed: Bool) {
        if thumbStickControl === rightThumbStickControl {
            if isPressed {
                delegate?.controlInputSourceDidBeginAttacking(self)
            }
            else {
                delegate?.controlInputSourceDidFinishAttacking(self)
            }
        }
    }
    
    // MARK: UIResponder
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        
        for touch in touches {
            let touchPoint = touch.locationInNode(self)
            
            /*
                Ignore touches if the thumb stick controls are hidden, or if
                the touch is in the center of the screen.
            */
            let touchIsInCenter = touchPoint.x < centerDividerWidth / 2 && touchPoint.x > -centerDividerWidth / 2
            if hideThumbStickControls || touchIsInCenter {
                    continue
            }
            
            if touchPoint.x < 0 {
                leftControlTouches.unionInPlace([touch])
                leftThumbStickControl.position = pointByCheckingControlOffset(touchPoint)
                leftThumbStickControl.touchesBegan([touch], withEvent: event)
            }
            else {
                rightControlTouches.unionInPlace([touch])
                rightThumbStickControl.position = pointByCheckingControlOffset(touchPoint)
                rightThumbStickControl.touchesBegan([touch], withEvent: event)
            }
        }
        
        gameStateDelegate?.controlInputSourceDidTriggerAnyEvent(self)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        /*
            If the touch pertains to a `thumbStickControl`, pass the
            touch along to be handled.
            
            Holding onto individual touches allows the user to drag
            a touch that initially started on the `leftThumbStickControl`
            over the the `rightThumbStickControl`s zone or vice versa,
            while ensuring it is handled by the correct thumb stick.
        */
        let movedLeftTouches = touches.intersect(leftControlTouches)
        leftThumbStickControl.touchesMoved(movedLeftTouches, withEvent: event)
        
        let movedRightTouches = touches.intersect(rightControlTouches)
        rightThumbStickControl.touchesMoved(movedRightTouches, withEvent: event)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        
        for touch in touches {
            let touchPoint = touch.locationInNode(self)
            
            /// Toggle pause when touching in the pause node.
            if pauseButton === nodeAtPoint(touchPoint) {
                gameStateDelegate?.controlInputSourceDidTogglePauseState(self)
                break
            }
        }
        
        let endedLeftTouches = touches.intersect(leftControlTouches)
        leftThumbStickControl.touchesEnded(endedLeftTouches, withEvent: event)
        leftControlTouches.subtractInPlace(endedLeftTouches)
        
        let endedRightTouches = touches.intersect(rightControlTouches)
        rightThumbStickControl.touchesEnded(endedRightTouches, withEvent: event)
        rightControlTouches.subtractInPlace(endedRightTouches)
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        
        leftThumbStickControl.resetTouchPad()
        rightThumbStickControl.resetTouchPad()
        
        // Keep the set's capacity, because roughly the same number of touch events are being received.
        leftControlTouches.removeAll(keepCapacity: true)
        rightControlTouches.removeAll(keepCapacity: true)
    }
    
    // MARK: Convenience Methods
    
    /// Calculates a point that keeps the `thumbStickControl` completely on screen.
    func pointByCheckingControlOffset(suggestedPoint: CGPoint) -> CGPoint {
        // `leftThumbStickControl` is an arbitrary choice - both are the same size.
        let controlSize = leftThumbStickControl.size
        
        /*
            The origin of `SKNode`'s coordinate system is at the center of the screen.
            Points to the left and below the origin are negative;
            points above and to the right are positive.
            
            Offset by 1.5 times the size of the control to maintain some padding
            around the edge of the view.
        */
        let minX = -scene!.size.width / 2 + controlSize.width / 1.5
        let maxX = scene!.size.width / 2 - controlSize.width / 1.5
        
        let minY = -scene!.size.height / 2 + controlSize.height / 1.5
        let maxY = scene!.size.height / 2 - controlSize.height / 1.5
        
        let boundX = max(min(suggestedPoint.x, maxX), minX)
        let boundY = max(min(suggestedPoint.y, maxY), minY)
        
        return CGPoint(x: boundX, y: boundY)
    }
    
}