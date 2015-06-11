/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An abstraction representing the user currently playing the game. Manages the player's control input sources.
*/

import SpriteKit

class Player: NSObject {
    // MARK: Properties
    
     /// The control input source that is native to the platform (keyboard or touch). 
    let nativeControlInputSource: ControlInputSourceType
    
    /// An optional secondary input source for a connected game controller.
    var secondaryControlInputSource: GameControllerInputSource?

    var controlInputSources: [ControlInputSourceType] {
        return [nativeControlInputSource, secondaryControlInputSource as ControlInputSourceType?].flatMap { $0 }
    }
    
    // MARK: Initialization

    init(nativeControlInputSource: ControlInputSourceType) {
        self.nativeControlInputSource = nativeControlInputSource
    }
}
