# Maze: Getting Started with GameplayKit

This sample demonstrates how to use several features in GameplayKit to create a simple variation on several classic arcade games:
- GKEntity/GKComponent architecture for modular, reusable game logic
- GKStateMachine to control general behavior of game characters
- GKRuleSystem to control some aspects of game character behavior using fuzzy logic
- GKGraph and related classes for grid-based pathfinding to plan character routes in a maze

## Playing the game

Move the player character (bright blue diamond) around the maze while avoiding the enemy characters (colored squares). If you can't escape, use a powerup to make the enemy characters flee. While they're fleeing, run into one to defeat it, sending it back to its starting position.

OS X: Arrow keys to move the player, space bar for powerup.
iOS: Swipe to move the player, tap for powerup.

## Requirements

### Build

Xcode 7.0, iOS 9.0 SDK or OS X 10.11 SDK

### Runtime

iOS 9.0 or OS X 10.11

Copyright (C) 2015 Apple Inc. All rights reserved.