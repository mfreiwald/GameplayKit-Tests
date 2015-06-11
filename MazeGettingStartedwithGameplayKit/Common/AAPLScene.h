/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Minimal SKScene subclass to abstract game logic from scene content.
 */

@import SpriteKit;
@import GameplayKit;

#import "AAPLPlayerControlComponent.h"

static const CGFloat AAPLCellWidth = 27.0;

@class AAPLScene;

/*! 
    This protocol moves most of the game logic to the delegate,
    leaving the scene class to only handle input.
*/
@protocol AAPLSceneDelegate <SKSceneDelegate>

@property (readwrite, nonatomic) BOOL hasPowerup;
@property (readwrite, nonatomic) AAPLPlayerDirection playerDirection;

- (void)scene:(AAPLScene *)scene didMoveToView:(SKView *)view;

@end


@interface AAPLScene : SKScene

@property (nonatomic, assign) id<AAPLSceneDelegate> delegate;

- (CGPoint)pointForGridPosition:(vector_int2)position;

@end
