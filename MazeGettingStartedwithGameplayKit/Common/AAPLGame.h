/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Main class to handle game logic that isn't specific to individual entities.
 */

@import SpriteKit;

#import "AAPLPlayerControlComponent.h"

@class AAPLLevel, AAPLScene, AAPLEntity;

@interface AAPLGame : NSObject

@property (readonly, nonatomic) AAPLScene *scene;
@property (readonly, nonatomic) AAPLLevel *level;
@property (readonly, nonatomic) NSArray<AAPLEntity *> *enemies;
@property (readonly, nonatomic) AAPLEntity *player;

@property (nonatomic) AAPLPlayerDirection playerDirection;
@property (readwrite, nonatomic) BOOL hasPowerup;

// Random source shared by various game mechanics.
@property GKRandomSource *random;

@end
