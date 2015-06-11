/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Enemies in the Flee state pick a random corner of the map and go there.
 */

#import "EnemyStates.h"

#import "AAPLGame.h"
#import "AAPLSpriteNode.h"
#import "AAPLLevel.h"
#import "AAPLEntity.h"
#import "AAPLSpriteComponent.h"

@interface AAPLEnemyFleeState()

@property GKGridGraphNode *target;

@end

@implementation AAPLEnemyFleeState

- (BOOL)isValidNextState:(Class __nonnull)stateClass {
	return stateClass == [AAPLEnemyChaseState class] ||
		stateClass == [AAPLEnemyDefeatedState class];
}

#pragma mark - GKState Life Cycle

- (void)didEnterWithPreviousState:(__nullable GKState *)previousState {
    AAPLSpriteComponent *component = (AAPLSpriteComponent *)[self.entity componentForClass:[AAPLSpriteComponent class]];
    [component useFleeAppearance];

	// Choose a location to flee towards.
	self.target = [[self.game.random arrayByShufflingObjectsInArray:self.game.level.enemyStartPositions] firstObject];
}

- (void)updateWithDeltaTime:(NSTimeInterval)seconds {
	// If the enemy has reached its target, choose a new target.
	vector_int2 position = self.entity.gridPosition;
	if (position.x == self.target.gridPosition.x && position.y == self.target.gridPosition.y) {
		self.target = [[self.game.random arrayByShufflingObjectsInArray:self.game.level.enemyStartPositions] firstObject];
	}
	// Flee towards the current target point.
	[self startFollowingPath:[self pathToNode:self.target]];
}

@end
