/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Main class to handle game logic that isn't specific to individual entities.
 */

#import "AAPLGame.h"

@import GameplayKit;

#import "EnemyStates.h"
#import "AAPLScene.h"
#import "AAPLSpriteNode.h"
#import "AAPLIntelligenceComponent.h"
#import "AAPLLevel.h"
#import "AAPLEntity.h"
#import "AAPLPlayerControlComponent.h"
#import "AAPLSpriteComponent.h"

typedef NS_OPTIONS(NSUInteger, ContactCategory) {
	ContactCategoryPlayer	= 1 << 1,
	ContactCategoryEnemy	= 1 << 2,
};

@interface AAPLGame() <AAPLSceneDelegate, SKPhysicsContactDelegate>

@property (readwrite, nonatomic) AAPLLevel *level;
@property (readwrite, nonatomic) AAPLScene *scene;
@property (readwrite, nonatomic) NSArray<AAPLEntity *> *enemies;
@property (readwrite, nonatomic) AAPLEntity *player;
@property GKComponentSystem *intelligenceSystem;
@property NSTimeInterval prevUpdateTime;

@property (readwrite, nonatomic) CFTimeInterval powerupTimeRemaining;

@end

@implementation AAPLGame

- (instancetype)init {
    self = [super init];
    
    if (self) {
		_random = [[GKRandomSource alloc] init];
        _level = [[AAPLLevel alloc] init];
		
		// Create player entity with display and control components.
        _player = [[AAPLEntity alloc] init];
        _player.gridPosition = _level.startPosition.gridPosition;
        [_player addComponent:[[AAPLSpriteComponent alloc] initWithDefaultColor:[SKColor cyanColor]]];
        [_player addComponent:[[AAPLPlayerControlComponent alloc] initWithLevel:_level]];
		
		// Create enemy entities with display and AI components.
        NSArray<SKColor *> *colors = @[[SKColor redColor], [SKColor greenColor], [SKColor yellowColor], [SKColor magentaColor]];
		_intelligenceSystem = [[GKComponentSystem alloc] initWithComponentClass:[AAPLIntelligenceComponent class]];
        NSMutableArray<AAPLEntity *> *enemies = [NSMutableArray arrayWithCapacity:_level.enemyStartPositions.count];
        [_level.enemyStartPositions enumerateObjectsUsingBlock:^(GKGridGraphNode *node, NSUInteger index, BOOL *stop) {
            AAPLEntity *enemy = [[AAPLEntity alloc] init];
            enemy.gridPosition = node.gridPosition;
            [enemy addComponent:[[AAPLSpriteComponent alloc] initWithDefaultColor:colors[index]]];
			[enemy addComponent:[[AAPLIntelligenceComponent alloc] initWithGame:self enemy:enemy startingPosition:node]];
			[_intelligenceSystem addComponentWithEntity:enemy];
            [enemies addObject:enemy];
        }];
        _enemies = [enemies copy];
    }
    
    return self;
}

- (SKScene *)scene {
	if (_scene == nil) {
		_scene = [AAPLScene sceneWithSize:CGSizeMake(self.level.width * AAPLCellWidth,
													 self.level.height * AAPLCellWidth)];
		_scene.delegate = self;
		_scene.physicsWorld.gravity = CGVectorMake(0, 0);
		_scene.physicsWorld.contactDelegate = self;
	}
	return _scene;
}

- (void)setHasPowerup:(BOOL)hasPowerup {
	static const NSTimeInterval powerupDuration = 10;
    if (hasPowerup != _hasPowerup) {
        Class nextState;
        if (!_hasPowerup) {
            nextState = [AAPLEnemyFleeState class];
        }
        else {
            nextState = [AAPLEnemyChaseState class];
        }
        
        for (AAPLIntelligenceComponent *component in self.intelligenceSystem) {
            [component.stateMachine enterState:nextState];
        }
        self.powerupTimeRemaining = powerupDuration;
    }
    _hasPowerup = hasPowerup;
}

- (void)setPowerupTimeRemaining:(CFTimeInterval)powerupTime {
    _powerupTimeRemaining = powerupTime;
    if (_powerupTimeRemaining < 0) {
        self.hasPowerup = NO;
    }
}

#pragma mark - AAPLSceneDelegate (SKSceneDelegate)

- (void)scene:(AAPLScene *)scene didMoveToView:(SKView *)view {
	scene.backgroundColor = [SKColor blackColor];

	// Generate maze.
	SKNode *maze = [SKNode node];
	CGSize cellSize = CGSizeMake(AAPLCellWidth, AAPLCellWidth);
	GKGridGraph *graph = self.level.pathfindingGraph;
	for (int i = 0; i < self.level.width; i++) {
		for (int j = 0; j < self.level.height; j++) {
			if ([graph nodeAtGridPosition:(vector_int2){i, j}]) {
				// Make nodes for traversable areas; leave walls as background color.
				SKSpriteNode *node = [[SKSpriteNode alloc] initWithColor:[SKColor grayColor] size:cellSize];
				node.position = CGPointMake(i * AAPLCellWidth + AAPLCellWidth / 2, j * AAPLCellWidth  + AAPLCellWidth / 2);
				[maze addChild:node];
			}
		}
	}
	[scene addChild:maze];

	// Add player entity to scene.
	AAPLSpriteComponent *playerComponent = (AAPLSpriteComponent *)[self.player componentForClass:[AAPLSpriteComponent class]];
	playerComponent.sprite = ({
		AAPLSpriteNode *sprite = [AAPLSpriteNode spriteNodeWithColor:[SKColor cyanColor] size:cellSize];
		sprite.owner = playerComponent;
		sprite.position = [scene pointForGridPosition:self.player.gridPosition];
		sprite.zRotation = M_PI_4;
		sprite.xScale = M_SQRT1_2;
		sprite.yScale = M_SQRT1_2;
		sprite.physicsBody = ({
			SKPhysicsBody *body = [SKPhysicsBody bodyWithCircleOfRadius:AAPLCellWidth/2];
			body.categoryBitMask = ContactCategoryPlayer;
			body.contactTestBitMask = ContactCategoryEnemy;
			body.collisionBitMask = 0;
			body;
		});
		sprite;
	});
    [scene addChild:playerComponent.sprite];

	// Add enemy entities to scene.
	for (AAPLEntity *entity in self.enemies) {
		AAPLSpriteComponent *enemyComponent = (AAPLSpriteComponent *)[entity componentForClass:[AAPLSpriteComponent class]];
		enemyComponent.sprite = [AAPLSpriteNode spriteNodeWithColor:enemyComponent.defaultColor size:cellSize];
		enemyComponent.sprite.owner = enemyComponent;
		enemyComponent.sprite.position = [scene pointForGridPosition:entity.gridPosition];
        
		enemyComponent.sprite.physicsBody = ({
			SKPhysicsBody *body = [SKPhysicsBody bodyWithCircleOfRadius:AAPLCellWidth/2];
			body.categoryBitMask = ContactCategoryEnemy;
			body.contactTestBitMask = ContactCategoryPlayer;
			body.collisionBitMask = 0;
			body;
		});
		[scene addChild:enemyComponent.sprite];
	};
}

- (void)update:(NSTimeInterval)currentTime forScene:(SKScene *)scene {
	// Track the time delta since the last update.
	if (self.prevUpdateTime < 0) {
		self.prevUpdateTime = currentTime;
	}
	float dt = currentTime - self.prevUpdateTime;
	self.prevUpdateTime = currentTime;
	
	// Track remaining time on the powerup.
	self.powerupTimeRemaining -= dt;

	// Update components with the new time delta.
	[self.intelligenceSystem updateWithDeltaTime:dt];
    [self.player updateWithDeltaTime:dt];
}

#pragma mark - SKPhysicsContactDelegate

- (void)didBeginContact:(SKPhysicsContact *)contact {
	AAPLSpriteNode *enemyNode;
	if (contact.bodyA.categoryBitMask == ContactCategoryEnemy) {
		enemyNode = (AAPLSpriteNode *)contact.bodyA.node;
	}
    else if (contact.bodyB.categoryBitMask == ContactCategoryEnemy) {
		enemyNode = (AAPLSpriteNode *)contact.bodyB.node;
	}
	NSAssert(enemyNode != nil, @"Expected player-enemy/enemy-player collision");
	
	// If the player contacts an enemy that's in the Chase state, the player is attackeed.
	AAPLEntity *entity = (AAPLEntity *)enemyNode.owner.entity;
	AAPLIntelligenceComponent *aiComponent = (AAPLIntelligenceComponent *)[entity componentForClass:[AAPLIntelligenceComponent class]];
    if ([aiComponent.stateMachine.currentState isKindOfClass:[AAPLEnemyChaseState class]]) {
        [self playerAttacked];
    }
    else {
        // Otherwise, that enemy enters the Defeated state only if in a state that allows that transition.
        [aiComponent.stateMachine enterState:[AAPLEnemyDefeatedState class]];
    }
}

- (void)playerAttacked {
	// Warp player back to starting point.
	AAPLSpriteComponent *spriteComponent = (AAPLSpriteComponent *)[self.player componentForClass:[AAPLSpriteComponent class]];
	[spriteComponent warpToGridPosition:self.level.startPosition.gridPosition];
	
	// Reset the player's direction controls upon warping.
    AAPLPlayerControlComponent *controlComponent = (AAPLPlayerControlComponent *)[self.player componentForClass:[AAPLPlayerControlComponent class]];
	controlComponent.direction = AAPLDirectionNone;
	controlComponent.attemptedDirection = AAPLDirectionNone;
}

- (void)setPlayerDirection:(AAPLPlayerDirection)playerDirection {
	// Forward directional input to the control component.
    AAPLPlayerControlComponent *component = (AAPLPlayerControlComponent *)[self.player componentForClass:[AAPLPlayerControlComponent class]];
    component.attemptedDirection = playerDirection;
}

- (AAPLPlayerDirection)playerDirection {
	// Forward directional input from the control component.
    AAPLPlayerControlComponent *component = (AAPLPlayerControlComponent *)[self.player componentForClass:[AAPLPlayerControlComponent class]];
    return component.direction;
}

@end
