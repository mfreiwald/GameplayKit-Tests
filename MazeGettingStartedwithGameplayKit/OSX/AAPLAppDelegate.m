/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	iOS view controller presents the SpriteKit scene and owns the main Game object.
 */

#import "AAPLAppDelegate.h"

#import "AAPLGame.h"
#import "AAPLScene.h"

@interface AAPLAppDelegate()

@property AAPLGame *game;

@end

@implementation AAPLAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Create the game and its SpriteKit scene.
	self.game = [[AAPLGame alloc] init];
    SKScene *scene = self.game.scene;
    scene.scaleMode = SKSceneScaleModeAspectFit;

	// Present the scene and configure the SpriteKit view.
	[self.skView presentScene:scene];
    self.skView.ignoresSiblingOrder = YES;
    self.skView.showsFPS = YES;
    self.skView.showsNodeCount = YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
