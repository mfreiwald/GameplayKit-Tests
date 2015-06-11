/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Common superclass provides functionality shared by multiple states in the enemy AI state machine.
 */

@import GameplayKit;

@class AAPLGame, AAPLEntity;

@interface AAPLEnemyState : GKState

@property (weak) AAPLGame *game;
@property AAPLEntity *entity;

- (instancetype)initWithGame:(AAPLGame *)game entity:(AAPLEntity *)entity;

- (NSArray<GKGridGraphNode *> *)pathToNode:(GKGridGraphNode *)node;
- (void)startFollowingPath:(NSArray<GKGridGraphNode *> *)path;

@end
