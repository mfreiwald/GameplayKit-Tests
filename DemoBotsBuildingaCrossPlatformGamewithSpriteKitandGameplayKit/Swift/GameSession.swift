/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Tracks player-related information from level to level. Manages the player's control input sources, and handles game controller connections / disconnections.
*/

import SpriteKit
import GameplayKit
import GameController

protocol GameSessionDelegate: class {
    // Called whenever a control input source is changed for the `player`.
    func gameSessionDidUpdateControlInputSources(gameSession: GameSession)
}

class GameSession: NSObject {
    // MARK: Properties
    weak var delegate: GameSessionDelegate?
    
    /// An internal queue to protect accessing the `player`.
    private let playersQueue = dispatch_queue_create("com.example.apple-samplecode.gamesession", DISPATCH_QUEUE_SERIAL)
    
    private var isAlreadyInSession = false

    let player: Player
    
    // MARK: Initialization
    
    init(player: Player) {
        self.player = player
        
        super.init()
        
        // Register for GameController pairing notifications.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleControllerDidConnectNotification:", name: GCControllerDidConnectNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleControllerDidDisconnectNotification:", name: GCControllerDidDisconnectNotification, object: nil)
    }
    
    // MARK: Methods
    
    func startSession() {
        // Update the player with any connected game controllers.
        for connectedGameController in GCController.controllers() {
            updatePlayerWithGameController(connectedGameController)
        }
        
        delegate?.gameSessionDidUpdateControlInputSources(self)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: GCControllerDidConnectNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: GCControllerDidDisconnectNotification, object: nil)
    }
    
    func updatePlayerWithGameController(gameController: GCController) {
        dispatch_sync(playersQueue) {
            /*
                If not already assigned, add a controller as the player's
                secondary control.
            */
            if self.player.secondaryControlInputSource == nil {
                let gameControllerInputSource = GameControllerInputSource(gameController: gameController)
                self.player.secondaryControlInputSource = gameControllerInputSource
                gameController.playerIndex = .Index1
            }
        }
    }
    
    // MARK: GameController Notification Handling
    
    @objc func handleControllerDidConnectNotification(notification: NSNotification) {
        let connectedGameController = notification.object as! GCController
        
        updatePlayerWithGameController(connectedGameController)
        delegate?.gameSessionDidUpdateControlInputSources(self)
    }
    
    @objc func handleControllerDidDisconnectNotification(notification: NSNotification) {
        let disconnectedGameController = notification.object as! GCController
        
        // Check if the player was being controlled by the disconnected controller.        
        if player.secondaryControlInputSource?.gameController == disconnectedGameController {
            dispatch_sync(playersQueue) {
                self.player.secondaryControlInputSource = nil
            }
            
            // Possibly use one of the other connected controllers.
            for gameController in GCController.controllers() {
                updatePlayerWithGameController(gameController)
            }
            
            delegate?.gameSessionDidUpdateControlInputSources(self)
        }
    }
}