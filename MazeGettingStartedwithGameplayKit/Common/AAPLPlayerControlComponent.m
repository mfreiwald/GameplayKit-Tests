/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Handles the translation between a directional input and player movement.
 */

#import "AAPLPlayerControlComponent.h"

#import "AAPLLevel.h"
#import "AAPLSpriteComponent.h"
#import "AAPLEntity.h"

@interface AAPLPlayerControlComponent()

@property GKGridGraphNode *nextNode;

@end

@implementation AAPLPlayerControlComponent

- (instancetype)initWithLevel:(AAPLLevel *)level {
    self = [super init];
    
    if (self) {
        _level = level;
    }
    
    return self;
}

- (void)setDirection:(AAPLPlayerDirection)direction {
    GKGridGraphNode *proposedNode;
    if (_direction != AAPLDirectionNone) { // currently moving
        proposedNode = [self nodeInDirection:direction fromNode:self.nextNode];
    }
    else {
        GKGridGraphNode *currentNode = [self.level.pathfindingGraph nodeAtGridPosition:((AAPLEntity *)self.entity).gridPosition];
        proposedNode = [self nodeInDirection:direction fromNode:currentNode];
    }
    if (proposedNode == nil) {
        return;
    }
    _direction = direction;
}

- (GKGridGraphNode *)nodeInDirection:(AAPLPlayerDirection)direction fromNode:(GKGridGraphNode *)node {
    vector_int2 nextPosition;
    switch (direction) {
        case AAPLDirectionLeft:
            nextPosition = node.gridPosition + (vector_int2){-1, 0};
            break;
            
        case AAPLDirectionRight:
            nextPosition = node.gridPosition + (vector_int2){1, 0};
            break;
            
        case AAPLDirectionDown:
            nextPosition = node.gridPosition + (vector_int2){0, -1};
            break;
            
        case AAPLDirectionUp:
            nextPosition = node.gridPosition + (vector_int2){0, 1};
            break;
            
        case AAPLDirectionNone:
        default:
            return nil;
    }
    return [self.level.pathfindingGraph nodeAtGridPosition:nextPosition];
}

- (void)makeNextMove {
    GKGridGraphNode *currentNode = [self.level.pathfindingGraph nodeAtGridPosition:((AAPLEntity *)self.entity).gridPosition];
    GKGridGraphNode *nextNode = [self nodeInDirection:self.direction fromNode:currentNode];
    GKGridGraphNode *attemptedNextNode = [self nodeInDirection:self.attemptedDirection fromNode:currentNode];
    if (attemptedNextNode != nil) {
        // Move in the attempted direction.
        _direction = self.attemptedDirection;
        self.nextNode = attemptedNextNode;
        AAPLSpriteComponent *component = (AAPLSpriteComponent *)[self.entity componentForClass:[AAPLSpriteComponent class]];
        component.nextGridPosition = self.nextNode.gridPosition;
    } else if ((attemptedNextNode == nil) && (nextNode != nil)) {
        // Keep moving in the same direction.
        _direction = self.direction;
        self.nextNode = nextNode;
        AAPLSpriteComponent *component = (AAPLSpriteComponent *)[self.entity componentForClass:[AAPLSpriteComponent class]];
        component.nextGridPosition = self.nextNode.gridPosition;
    } else {
        // Can't move any more.
        _direction = AAPLDirectionNone;
    }
}

- (void)updateWithDeltaTime:(NSTimeInterval)seconds {
    [self makeNextMove];
}

@end
