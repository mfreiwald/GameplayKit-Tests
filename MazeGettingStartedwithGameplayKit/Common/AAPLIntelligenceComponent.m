/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Uses a state machine to run the "AI" for an individual enemy character. Enemies switch between Chase, Flee, Defeated, and Respawn states according to various triggers in the game.
 */

#import "AAPLIntelligenceComponent.h"

#import "EnemyStates.h"
#import "AAPLGame.h"
#import "AAPLEntity.h"

@implementation AAPLIntelligenceComponent

- (instancetype)initWithGame:(AAPLGame *)game enemy:(AAPLEntity *)enemy startingPosition:(GKGridGraphNode *)origin {
    self = [super init];
    
    if (self) {
        AAPLEnemyChaseState *chase = [[AAPLEnemyChaseState alloc] initWithGame:game entity:enemy];
        AAPLEnemyFleeState *flee = [[AAPLEnemyFleeState alloc] initWithGame:game entity:enemy];
        AAPLEnemyDefeatedState *defeated = [[AAPLEnemyDefeatedState alloc] initWithGame:game entity:enemy];
		defeated.respawnPosition = origin;
        AAPLEnemyRespawnState *respawn = [[AAPLEnemyRespawnState alloc] initWithGame:game entity:enemy];

        _stateMachine = [GKStateMachine stateMachineWithStates:@[chase, flee, defeated, respawn]];
        [_stateMachine enterState:[AAPLEnemyChaseState class]];
    }
    
    return self;
}

- (void)updateWithDeltaTime:(NSTimeInterval)seconds {
    [self.stateMachine updateWithDeltaTime:seconds];
}

@end
