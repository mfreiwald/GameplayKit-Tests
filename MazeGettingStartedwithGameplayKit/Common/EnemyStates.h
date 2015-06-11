/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Shared header for the state classes used in the enemy AI state machine.
 */

@import GameplayKit;

#import "AAPLEnemyState.h"

@interface AAPLEnemyChaseState : AAPLEnemyState
@end

@interface AAPLEnemyFleeState : AAPLEnemyState
@end

@interface AAPLEnemyDefeatedState : AAPLEnemyState

@property GKGridGraphNode *respawnPosition;

@end

@interface AAPLEnemyRespawnState : AAPLEnemyState
@end