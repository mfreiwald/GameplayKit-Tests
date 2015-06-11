/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Handles all aspects of a player or enemy entity's appearance in a SpriteKit scene.
 */

#import "AAPLSpriteComponent.h"

#import "AAPLScene.h"
#import "AAPLSpriteNode.h"
#import "AAPLEntity.h"

@implementation AAPLSpriteComponent

- (instancetype)initWithDefaultColor:(SKColor *)color {
	self = [super init];
    
	if (self) {
		_defaultColor = color;
	}
    
	return self;
}

#pragma mark - Appearance

- (void)setPulseEffectEnabled:(BOOL)pulseEffectEnabled {
	_pulseEffectEnabled = pulseEffectEnabled;
	if (pulseEffectEnabled) {
		SKAction *grow = [SKAction scaleBy:1.5 duration:0.5];
		SKAction *sequence = [SKAction sequence:@[grow, [grow reversedAction]]];
		[self.sprite runAction:[SKAction repeatActionForever:sequence] withKey:@"pulse"];
	}
	else {
		[self.sprite removeActionForKey:@"pulse"];
		[self.sprite runAction:[SKAction scaleTo:1.0 duration:0.5]];
	}
}

- (void)useNormalAppearance {
	self.sprite.color = self.defaultColor;
}

- (void)useFleeAppearance {
	self.sprite.color = [SKColor whiteColor];
}

- (void)useDefeatedAppearance {
	[self.sprite runAction:[SKAction scaleTo:0.25 duration:0.25]];
}

#pragma mark - Movement

- (void)setNextGridPosition:(vector_int2)nextGridPosition {
	if (_nextGridPosition.x != nextGridPosition.x || _nextGridPosition.y != nextGridPosition.y) {
		_nextGridPosition = nextGridPosition;

        SKAction *action = [SKAction moveTo:[(AAPLScene *)self.sprite.scene pointForGridPosition:nextGridPosition] duration:0.35];
		SKAction *update = [SKAction runBlock:^{
			((AAPLEntity *)self.entity).gridPosition = nextGridPosition;
		}];
        
		[self.sprite runAction:[SKAction sequence:@[action, update]] withKey:@"move"];
	}
}

- (void)warpToGridPosition:(vector_int2)gridPosition {
	SKAction *fadeOut = [SKAction fadeOutWithDuration:0.5];
	SKAction *warp = [SKAction moveTo:[(AAPLScene *)self.sprite.scene pointForGridPosition:gridPosition] duration:0.5];
	SKAction *fadeIn = [SKAction fadeInWithDuration:0.5];
	SKAction *update = [SKAction runBlock:^{
		((AAPLEntity *)self.entity).gridPosition = gridPosition;
	}];
    
	[self.sprite runAction:[SKAction sequence:@[fadeOut, update, warp, fadeIn]]];
}

- (void)followPath:(NSArray<GKGridGraphNode *> *)path completion:(void(^)(void))completionHandler {
	// Ignore the first node in the path -- it's the starting position.
	NSArray<GKGridGraphNode *> *dropFirst =[path subarrayWithRange:NSMakeRange(1, path.count - 1)];
	NSMutableArray<SKAction *> *sequence = [NSMutableArray arrayWithCapacity:dropFirst.count];
    
	for (GKGridGraphNode *node in dropFirst) {
		CGPoint point = [(AAPLScene *)self.sprite.scene pointForGridPosition:node.gridPosition];
		[sequence addObject:[SKAction moveTo:point duration:0.15]];
		[sequence addObject:[SKAction runBlock:^{
			((AAPLEntity *)self.entity).gridPosition = node.gridPosition;
		}]];
	}
    
	[sequence addObject:[SKAction runBlock:completionHandler]];
	[self.sprite runAction:[SKAction sequence:sequence]];
}

@end
