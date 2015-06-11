/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Handles the translation between a directional input and player movement.
 */

@import GameplayKit;

@class AAPLLevel;

typedef NS_ENUM(NSInteger, AAPLPlayerDirection) {
    AAPLDirectionNone = 0,
    AAPLDirectionLeft,
    AAPLDirectionRight,
    AAPLDirectionDown,
    AAPLDirectionUp,
};

@interface AAPLPlayerControlComponent : GKComponent

- (instancetype)initWithLevel:(AAPLLevel *)level;
@property (nonatomic) AAPLLevel *level;
@property (nonatomic) AAPLPlayerDirection direction;
@property (nonatomic) AAPLPlayerDirection attemptedDirection;

@end
