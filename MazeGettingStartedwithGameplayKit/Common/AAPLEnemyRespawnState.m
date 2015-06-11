/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Enemies in the Respawn state wait for a short time before returning to normal and chasing the player.
 */

#import "EnemyStates.h"

#import "AAPLSpriteNode.h"
#import "AAPLEntity.h"
#import "AAPLSpriteComponent.h"

@interface AAPLEnemyRespawnState()

@property NSTimeInterval timeRemaining;

@end

@implementation AAPLEnemyRespawnState

#pragma mark - GKState Life Cycle

- (BOOL)isValidNextState:(Class __nonnull)stateClass {
	return stateClass == [AAPLEnemyChaseState class];
}

- (void)didEnterWithPreviousState:(__nullable GKState *)previousState {
	static const NSTimeInterval defaultRespawnTime = 10;
    self.timeRemaining = defaultRespawnTime;
    
	AAPLSpriteComponent *component = (AAPLSpriteComponent *)[self.entity componentForClass:[AAPLSpriteComponent class]];
    component.pulseEffectEnabled = YES;
}

- (void)willExitWithNextState:(GKState * __nonnull)nextState {
    // Restore the sprite's original appearance.
    AAPLSpriteComponent *component = (AAPLSpriteComponent *)[self.entity componentForClass:[AAPLSpriteComponent class]];
    component.pulseEffectEnabled = NO;
}

- (void)updateWithDeltaTime:(NSTimeInterval)seconds {
    self.timeRemaining -= seconds;
    if (self.timeRemaining < 0) {
        [self.stateMachine enterState:[AAPLEnemyChaseState class]];
    }
}

@end
