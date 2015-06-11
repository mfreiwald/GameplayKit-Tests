/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Common superclass provides functionality shared by multiple states in the enemy AI state machine.
 */

#import "AAPLEnemyState.h"

#import "AAPLGame.h"
#import "AAPLLevel.h"
#import "AAPLEntity.h"
#import "AAPLSpriteComponent.h"

@implementation AAPLEnemyState

- (instancetype)initWithGame:(AAPLGame *)game entity:(AAPLEntity *)entity {
	self = [super init];
    
	if (self) {
		_game = game;
		_entity = entity;
	}
    
	return self;
}

#pragma mark - Path Finding & Following

- (NSArray<GKGridGraphNode *> *)pathToNode:(GKGridGraphNode *)node {
	GKGridGraph *graph = self.game.level.pathfindingGraph;
	GKGridGraphNode *enemyNode = [graph nodeAtGridPosition:self.entity.gridPosition];
	NSArray<GKGridGraphNode *> *path = [graph findPathFromNode:enemyNode toNode:node];
	return path;
}

- (void)startFollowingPath:(NSArray<GKGridGraphNode *> *)path {
	/*
        Set up a move to the first node on the path, but
        no farther because the next update will recalculate the path.
    */
	if (path.count > 1) {
		GKGridGraphNode *firstMove = path[1]; // path[0] is the enemy's current position.
		AAPLSpriteComponent *component = (AAPLSpriteComponent *)[self.entity componentForClass:[AAPLSpriteComponent class]];
		component.nextGridPosition = firstMove.gridPosition;
	}
}

@end
