/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Extension of SKSpriteNode adds a back pointer to the component that controls a sprite.
 */

@import SpriteKit;

@class AAPLSpriteComponent;

@interface AAPLSpriteNode : SKSpriteNode

@property (nonatomic, weak) AAPLSpriteComponent *owner;

@end
