/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Handles all aspects of a player or enemy entity's appearance in a SpriteKit scene.
 */


@import SpriteKit;
@import GameplayKit;

@class AAPLSpriteNode;

@interface AAPLSpriteComponent : GKComponent

@property AAPLSpriteNode *sprite;
@property SKColor *defaultColor;

- (instancetype)initWithDefaultColor:(SKColor *)color;

#pragma mark - Appearance

@property (nonatomic) BOOL pulseEffectEnabled;

- (void)useNormalAppearance;
- (void)useFleeAppearance;
- (void)useDefeatedAppearance;


#pragma mark - Movement

@property (nonatomic) vector_int2 nextGridPosition;

- (void)warpToGridPosition:(vector_int2)gridPosition;

- (void)followPath:(NSArray<GKGridGraphNode *> *)path completion:(void(^)(void))completionHandler;


@end
