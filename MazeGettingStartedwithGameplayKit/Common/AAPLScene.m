/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Minimal SKScene subclass to abstract game logic from scene content.
 */

#import "AAPLScene.h"

#import "AAPLGame.h"
#import "AAPLLevel.h"
#import "AAPLPlayerControlComponent.h"
#import "AAPLSpriteComponent.h"

@implementation AAPLScene

@dynamic delegate;

- (void)didMoveToView:(SKView *)view {
	[self.delegate scene:self didMoveToView:view];
}

- (CGPoint)pointForGridPosition:(vector_int2)position {
	return CGPointMake(position.x * AAPLCellWidth + AAPLCellWidth / 2, position.y * AAPLCellWidth  + AAPLCellWidth / 2);
}

#if !TARGET_OS_IOS
- (void)keyDown:(NSEvent *)theEvent {
	switch ([theEvent.characters characterAtIndex:0]) {
		case NSLeftArrowFunctionKey:
            self.delegate.playerDirection = AAPLDirectionLeft;
			break;

        case NSRightArrowFunctionKey:
            self.delegate.playerDirection = AAPLDirectionRight;
			break;
		
        case NSDownArrowFunctionKey:
            self.delegate.playerDirection = AAPLDirectionDown;
			break;
		
        case NSUpArrowFunctionKey:
            self.delegate.playerDirection = AAPLDirectionUp;
			break;
		
        case ' ': // space
			self.delegate.hasPowerup = YES;
			break;
		
        default:
			break;
	}
}
#endif

@end
