/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	iOS view controller presents the SpriteKit scene, and owns and funnels input into the main Game object.
 */

#import "AAPLGameViewController.h"

#import "AAPLGame.h"
#import "AAPLScene.h"
#import "AAPLPlayerControlComponent.h"

@interface AAPLGameViewController()

@property AAPLGame *game;

@end

@implementation AAPLGameViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	// Create the game and its SpriteKit scene.
    self.game = [[AAPLGame alloc] init];
    SKScene *scene = self.game.scene;
    scene.scaleMode = SKSceneScaleModeAspectFit;

	// Present the scene and configure the SpriteKit view.
    SKView * skView = (SKView *)self.view;
    [skView presentScene:scene];
    skView.ignoresSiblingOrder = YES;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
	self.game.playerDirection = AAPLDirectionLeft;
}

- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {
	self.game.playerDirection = AAPLDirectionRight;
}

- (IBAction)swipeDown:(UISwipeGestureRecognizer *)sender {
	self.game.playerDirection = AAPLDirectionDown;
}

- (IBAction)swipeUp:(UISwipeGestureRecognizer *)sender {
	self.game.playerDirection = AAPLDirectionUp;
}

- (IBAction)tap:(UITapGestureRecognizer *)sender {
	self.game.hasPowerup = YES;
}

@end
