/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Model class for a level (in this sample, the only level) in the maze game.
 */

@import GameplayKit;

@interface AAPLLevel : NSObject

@property (readonly) NSUInteger width;
@property (readonly) NSUInteger height;
@property (nonatomic) GKGridGraph *pathfindingGraph;
@property (readonly) GKGridGraphNode *startPosition;
@property (readonly) NSArray<GKGridGraphNode *> *enemyStartPositions;

@end
