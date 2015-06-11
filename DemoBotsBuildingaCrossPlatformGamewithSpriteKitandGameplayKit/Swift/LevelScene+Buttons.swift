/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension of `LevelScene` to enable it to respond to button presses.
*/

import Foundation

/// Extends `LevelScene` to respond to ButtonNode events.
extension LevelScene: ButtonNodeResponderType {
    // MARK: ButtonNodeResponderType
    
    func buttonPressed(button: ButtonNode) {
        switch button.buttonIdentifier! {
            case .Resume:
                stateMachine.enterState(LevelSceneActiveState.self)
            
            case .Home:
                sceneManager.transitionToSceneWithSceneIdentifier(.Home)
            
            case .ProceedToNextScene:
                sceneManager.transitionToSceneWithSceneIdentifier(.NextLevel)
            
            case .Replay:
                sceneManager.transitionToSceneWithSceneIdentifier(.CurrentLevel)
            
            case .ScreenRecorderToggle:
                #if os(iOS)
                toggleScreenRecording(button)
                #endif
            
            case .ViewRecordedContent:
                #if os(iOS)
                displayRecordedContent()
                #endif
            
            default:
                fatalError("Unsupported ButtonNode type in LevelScene.")
        }
    }
}