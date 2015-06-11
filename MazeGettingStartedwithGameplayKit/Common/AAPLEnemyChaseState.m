/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Enemies in the Chase state use a rule system to decide when to switch between chasing the player and randomly scattering toward a corner of the map.
 */

#import "EnemyStates.h"

#import "AAPLGame.h"
#import "AAPLLevel.h"
#import "AAPLSpriteComponent.h"
#import "AAPLEntity.h"
#import "AAPLSpriteNode.h"

@interface AAPLEnemyChaseState()

@property GKRuleSystem *ruleSystem;
@property (nonatomic, getter=isHunting) BOOL hunting;
@property GKGridGraphNode *scatterTarget;

@end

@implementation AAPLEnemyChaseState

- (instancetype)initWithGame:(AAPLGame *)game entity:(AAPLEntity *)entity {
    self = [super initWithGame:game entity:entity];
    
    if (self) {
        _ruleSystem = [[GKRuleSystem alloc] init];

        NSPredicate *playerFar = [NSPredicate predicateWithFormat:@"$distanceToPlayer.floatValue >= 10.0"];
        [_ruleSystem addRule:[GKRule ruleWithPredicate:playerFar assertingFact:@"hunt" grade:1.0]];
        
        NSPredicate *playerNear = [NSPredicate predicateWithFormat:@"$distanceToPlayer.floatValue < 10.0"];
        [_ruleSystem addRule:[GKRule ruleWithPredicate:playerNear retractingFact:@"hunt" grade:1.0]];
    }
    
    return self;
}

- (void)setHunting:(BOOL)hunting {
    if (_hunting != hunting) {
        if (!hunting) {
			NSArray *positions = [self.game.random arrayByShufflingObjectsInArray:self.game.level.enemyStartPositions];
            self.scatterTarget = [positions firstObject];
        }
    }
    _hunting = hunting;
}

- (NSArray<GKGridGraphNode *> *)pathToPlayer {
    GKGridGraph *graph = self.game.level.pathfindingGraph;
    GKGridGraphNode *playerNode = [graph nodeAtGridPosition:self.game.player.gridPosition];
    return [self pathToNode:playerNode];
}

#pragma mark - GKState Life Cycle

- (BOOL)isValidNextState:(Class __nonnull)stateClass {
    return stateClass == [AAPLEnemyFleeState class];
}

- (void)didEnterWithPreviousState:(__nullable GKState *)previousState {
    // Set the enemy sprite to its normal appearance, undoing any changes that happened in other states.
    AAPLSpriteComponent *component = (AAPLSpriteComponent *)[self.entity componentForClass:[AAPLSpriteComponent class]];
    [component useNormalAppearance];
}

- (void)updateWithDeltaTime:(NSTimeInterval)seconds {
	// If the enemy has reached its target, choose a new target.
	vector_int2 position = self.entity.gridPosition;
	if (position.x == self.scatterTarget.gridPosition.x && position.y == self.scatterTarget.gridPosition.y) {
		self.hunting = YES;
	}

    NSUInteger distanceToPlayer = [self pathToPlayer].count;
    self.ruleSystem.state[@"distanceToPlayer"] = @(distanceToPlayer);
    
    [self.ruleSystem reset];
    [self.ruleSystem evaluate];
    
    self.hunting = ([self.ruleSystem gradeForFact:@"hunt"] > 0.0);
    if (self.hunting) {
		[self startFollowingPath:[self pathToPlayer]];
    }
    else {
		[self startFollowingPath:[self pathToNode:self.scatterTarget]];
    }
}

@end
