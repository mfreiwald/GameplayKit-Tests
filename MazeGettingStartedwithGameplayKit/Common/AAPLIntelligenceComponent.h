/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Uses a state machine to run the "AI" for an individual enemy character. Enemies switch between Chase, Flee, Defeated, and Respawn states according to various triggers in the game.
 */

@import GameplayKit;

@class AAPLGame, AAPLEntity;

@interface AAPLIntelligenceComponent : GKComponent

@property GKStateMachine *stateMachine;

- (instancetype)initWithGame:(AAPLGame *)game
                       enemy:(AAPLEntity *)enemy
            startingPosition:(GKGridGraphNode *)origin;

@end
