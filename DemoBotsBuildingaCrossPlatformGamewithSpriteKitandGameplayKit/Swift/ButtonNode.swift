/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `ButtonNode` is a custom `SKSpriteNode` that provides button-like behavior in a SpriteKit scene. It is supported by `ButtonNodeResponderType` (a protocol for classes that can respond to button presses) and `ButtonIdentifier` (an enumeration that defines all of the kinds of buttons that are supported in the game).
*/

import SpriteKit

/// A type that can respond to `ButtonNode` button press events.
protocol ButtonNodeResponderType: class {
    /// Responds to a button press.
    func buttonPressed(button: ButtonNode)
}

/// The complete set of button identifiers supported in the app.
enum ButtonIdentifier: String {
    case Resume = "resumeButton"
    case Home = "homeButton"
    case ProceedToNextScene = "proceedButton"
    case Replay = "replayButton"
    case Retry = "retryButton"
    case Cancel = "cancelButton"
    case ScreenRecorderToggle = "screenRecorderButton"
    case ViewRecordedContent = "viewRecordedContentButton"
    
    /// Convenience array of all available button identifiers.
    static let allIdentifiers: [ButtonIdentifier] = [
        .Resume, .Home, .ProceedToNextScene, .Replay, .Retry, .Cancel, .ScreenRecorderToggle, .ViewRecordedContent
    ]
    
    /// The name of the texture to use for a button when the button is selected.
    var selectedTextureName: String? {
        switch self {
            case .ScreenRecorderToggle:
                return "ButtonAutoRecordOn"
            default:
                return nil
        }
    }
}

/// A custom sprite node that represents a pressable and selectable button in a scene.
class ButtonNode: SKSpriteNode {
    // MARK: Properties
    
    /**
        The scene that contains a `ButtonNode` must be a `ButtonNodeResponderType`
        so that touch events can be forwarded along through `buttonPressed()`.
    */
    var responder: ButtonNodeResponderType {
        guard let responder = scene as? ButtonNodeResponderType else {
            fatalError("ButtonNode may only be used within a `ButtonNodeResponderType` scene.")
        }
        return responder
    }
    
    // MARK: Highlight overlay

    /// Indicates whether the button is currently highlighted (selected).
    var isHighlighted = false {
        didSet {
            // Enable the button's blended color overlay if it is highlighted.
            colorBlendFactor = isHighlighted ? 1.0 : 0.0
        }
    }
    
    /**
        Indicates whether the button is currently selected (on or off).
        Most buttons do not support or require selection. In DemoBots,
        selection is used by the screen recorder buttons to indicate whether
        screen recording is turned on or off.
    */
    var isSelected = false {
        didSet {
            // Change the texture based on the current selection state.
            texture = isSelected ? selectedTexture : defaultTexture
        }
    }
    
    /// The texture to use when the button is not selected.
    var defaultTexture: SKTexture?
    
    /// The texture to use when the button is selected.
    var selectedTexture: SKTexture?

    /// The identifier for this button, deduced from its name in the scene.
    var buttonIdentifier: ButtonIdentifier!
    
    // MARK: Initializers
    
    init(templateNode: SKSpriteNode) {
        // Use the template node's properties to create a new `ButtonNode`.
        super.init(texture: templateNode.texture, color: SKColor.clearColor(), size: templateNode.size)
        
        // Check that the template node has a supported button identifier as its name.
        guard let nodeName = templateNode.name, buttonIdentifier = ButtonIdentifier(rawValue: nodeName) else {
            fatalError("Unsupported button name found.")
        }
        self.buttonIdentifier = buttonIdentifier

        // Copy the node's other properties.
        name = templateNode.name
        position = templateNode.position
        
        // Set the button to be positioned above everything else in the scene.
        zPosition = WorldLayer.Top.rawValue
        
        // Set the color that will be blended in to the texture when the button is highlighted.
        color = SKColor(white: 0.8, alpha: 1.0)
        
        // Remember the button's default texture (taken from its texture in the scene).
        defaultTexture = texture
        
        if let textureName = buttonIdentifier.selectedTextureName {
            // Use a specific selected texture if one is specified for this identifier.
            selectedTexture = SKTexture(imageNamed: textureName)
        }
        else {
            // Otherwise, use the default `texture`.
            selectedTexture = texture
        }
        
        // Copy any child nodes (e.g. labels) from the template node to the new button node.
        for child in templateNode.children {
            addChild(child.copy() as! SKNode)
        }
        
        // Enable user interaction on the button node to detect tap and click events.
        userInteractionEnabled = true
    }

    /*
        All subclasses of `SKNode` must provide an implementation of init?(coder:).
        However, we do not want a `ButtonNode` to be initialized in this way,
        so we provide an implementation that triggers a fatal error if called.
    */
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Responder
    
    #if os(iOS)
    /// UIResponder touch handling.
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
    
        if hasTouchWithinButton(touches) {
            isHighlighted = true
        }
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        isHighlighted = false

        if hasTouchWithinButton(touches) {
            // Forward the button press event through to the responder.
            responder.buttonPressed(self)
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        isHighlighted = false
    }
    
    /// Determine if any of the touches are within the `ButtonNode`.
    func hasTouchWithinButton(touches: Set<UITouch>) -> Bool {
        guard let scene = scene else { fatalError("Button must be used within a scene.") }
    
        let touchesInButton = touches.filter { touch in
            let touchPoint = touch.locationInNode(scene)
            let touchedNode = scene.nodeAtPoint(touchPoint)
            return touchedNode === self || touchedNode.inParentHierarchy(self)
        }
        return !touchesInButton.isEmpty
    }
    
    #elseif os(OSX)
    /// NSResponder mouse handling.
    override func mouseDown(event: NSEvent) {
        if eventIsWithinButton(event) {
            isHighlighted = true
        }
    }
    
    override func mouseUp(event: NSEvent) {
        isHighlighted = false

        if eventIsWithinButton(event) {
            // Forward the button press event through to the responder.
            responder.buttonPressed(self)
        }
    }
    
    /// Determine if the event location is within the `ButtonNode`.
    func eventIsWithinButton(event: NSEvent) -> Bool {
        guard let scene = scene else { fatalError("Button must be used within a scene.")  }

        let location = event.locationInNode(scene)
        let touchedNode = scene.nodeAtPoint(location)
        return touchedNode === self || touchedNode.inParentHierarchy(self)
    }
    #endif
    
    // MARK: Convenience
    
    /// Replace nodes in the `containerNode` with `ButtonNode`s if they have known button identifiers.
    static func parseButtonsInNode(containerNode: SKNode) {
        // Iterate through each button identifer.
        for identifier in ButtonIdentifier.allIdentifiers {
            // Try to fetch a child node whose name matches the button identifier.
            guard let templateNode = containerNode.childNodeWithName(identifier.rawValue) as? SKSpriteNode else { continue }
            
            // Create a `ButtonNode` based on the template node we found.
            let buttonNode = ButtonNode(templateNode: templateNode)
            
            // Replace the template node with the new `ButtonNode`.
            containerNode.addChild(buttonNode)
            templateNode.removeFromParent()
        }
    }
}
