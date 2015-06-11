/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Enemies in the Defeated state change appearance and zoom back to their starting points.
 */

#import "EnemyStates.h"

#import "AAPLGame.h"
#import "AAPLSpriteNode.h"
#import "AAPLLevel.h"
#import "AAPLEntity.h"
#import "AAPLSpriteComponent.h"

@implementation AAPLEnemyDefeatedState

#pragma mark - GKState Life Cycle

- (BOOL)isValidNextState:(Class __nonnull)stateClass {
	return stateClass == [AAPLEnemyRespawnState class];
}

- (void)didEnterWithPreviousState:(__nullable GKState *)previousState {
    // Change the enemy sprite's appearance to indicate defeat.
    AAPLSpriteComponent *component = (AAPLSpriteComponent *)[self.entity componentForClass:[AAPLSpriteComponent class]];
    [component useDefeatedAppearance];
    
    // Use pathfinding to find a route back to this enemy's starting position.
    GKGridGraph *graph = self.game.level.pathfindingGraph;
    GKGridGraphNode *enemyNode = [graph nodeAtGridPosition:self.entity.gridPosition];
    NSArray<GKGridGraphNode *> *path = [graph findPathFromNode:enemyNode toNode:self.respawnPosition];
    [component followPath:path completion:^{
        [self.stateMachine enterState:[AAPLEnemyRespawnState class]];
    }];
}

@end
