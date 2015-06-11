/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `TaskBotBehavior` is a `GKBehavior` subclass that provides convenience class methods to construct the appropriate goals and behaviors for different `TaskBot` mandates.
*/

import SpriteKit
import GameplayKit

/// Provides factory methods to create `TaskBot`-specific goals and behaviors.
class TaskBotBehavior: GKBehavior {
    // MARK: Behavior factory methods
    
    /// Constructs a behavior to hunt a `TaskBot` or `PlayerBot` via a computed path.
    static func behaviorAndPathPointsForAgent(agent: GKAgent2D, huntingAgent target: GKAgent2D, pathRadius: Float, inScene scene: LevelScene) -> (behavior: GKBehavior, pathPoints: [CGPoint]) {
        let behavior = TaskBotBehavior()
        
        // Add basic goals to reach the `TaskBot`'s maximum speed and avoid obstacles.
        behavior.addTargetSpeedGoal(agent.maxSpeed)
        behavior.addAvoidObstaclesGoalForScene(scene)

        // Find any nearby "bad" TaskBots to flock with.
        let agentsToFlockWith: [GKAgent2D] = scene.entities.flatMap { entity in
            if let taskBot = entity as? TaskBot where !taskBot.isGood && taskBot.agent !== agent && taskBot.distanceToAgent(agent) <= GameplayConfiguration.Flocking.agentSearchDistanceForFlocking {
                return taskBot.agent
            }
            else {
                return nil
            }
        }
        
        if !agentsToFlockWith.isEmpty {
            // Add flocking goals for any nearby "bad" `TaskBot`s.
            let separationGoal = GKGoal(toSeparateFromAgents: agentsToFlockWith, maxDistance: GameplayConfiguration.Flocking.separationRadius, maxAngle: GameplayConfiguration.Flocking.separationAngle)
            behavior.setWeight(GameplayConfiguration.Flocking.separationWeight, forGoal: separationGoal)
            
            let alignmentGoal = GKGoal(toAlignWithAgents: agentsToFlockWith, maxDistance: GameplayConfiguration.Flocking.alignmentRadius, maxAngle: GameplayConfiguration.Flocking.alignmentAngle)
            behavior.setWeight(GameplayConfiguration.Flocking.alignmentWeight, forGoal: alignmentGoal)
            
            let cohesionGoal = GKGoal(toCohereWithAgents: agentsToFlockWith, maxDistance: GameplayConfiguration.Flocking.cohesionRadius, maxAngle: GameplayConfiguration.Flocking.cohesionAngle)
            behavior.setWeight(GameplayConfiguration.Flocking.cohesionWeight, forGoal: cohesionGoal)
        }

        // Add goals to follow a calculated path from the `TaskBot` to its target.
        let pathPoints = behavior.addGoalsToFollowPathFromStartPoint(agent.position, toEndPoint: target.position, pathRadius: pathRadius, inScene: scene)
        
        // Return a tuple containing the new behavior, and the found path points for debug drawing.
        return (behavior, pathPoints)
    }
    
    /// Constructs a behavior to return to the start of a `TaskBot` patrol path.
    static func behaviorAndPathPointsForAgent(agent: GKAgent2D, returningToPoint endPoint: float2, pathRadius: Float, inScene scene: LevelScene) -> (behavior: GKBehavior, pathPoints: [CGPoint]) {
        let behavior = TaskBotBehavior()
        
        // Add basic goals to reach the `TaskBot`'s maximum speed and avoid obstacles.
        behavior.addTargetSpeedGoal(agent.maxSpeed)
        behavior.addAvoidObstaclesGoalForScene(scene)
        
        // Add goals to follow a calculated path from the `TaskBot` to the start of its patrol path.
        let pathPoints = behavior.addGoalsToFollowPathFromStartPoint(agent.position, toEndPoint: endPoint, pathRadius: pathRadius, inScene: scene)

        // Return a tuple containing the new behavior, and the found path points for debug drawing.
        return (behavior, pathPoints)
    }
    
    /// Constructs a behavior to patrol a path of points, avoiding obstacles along the way.
    static func behaviorForAgent(agent: GKAgent2D, patrollingPathWithPoints patrolPathPoints: [CGPoint], pathRadius: Float, inScene scene: LevelScene) -> GKBehavior {
        let behavior = TaskBotBehavior()
        
        // Add basic goals to reach the `TaskBot`'s maximum speed and avoid obstacles.
        behavior.addTargetSpeedGoal(agent.maxSpeed)
        behavior.addAvoidObstaclesGoalForScene(scene)
        
        // Convert the patrol path to an array of `float2`s.
        let pathVectorPoints = patrolPathPoints.map { float2($0) }
        
        // Create a cyclical (closed) `GKPath` from the provided path points with the requested path radius.
        let path = GKPath(points: UnsafeMutablePointer<float2>(pathVectorPoints), count: pathVectorPoints.count, radius: pathRadius, cyclical: true)

        // Add "follow path" and "stay on path" goals for this path.
        behavior.addFollowAndStayOnPathGoalsForPath(path)

        return behavior
    }
    
    // MARK: Goals
    
    /**
        Calculates all of the extruded obstacle rectangles for the scene, and returns
        all rectangles that contain the provided point. The extrusion is based on
        the buffer radius of the pathfinding graph.
    */
    private func extrudedRectsInScene(scene: LevelScene, containingPoint point: float2) -> [CGRect] {
        let extrusionRadius = CGFloat(GameplayConfiguration.TaskBot.pathfindingGraphBufferRadius)
        
        return scene.obstacleSpriteNodes.flatMap { spriteNode in
            // Calculate the extruded version of this obstacle.
            let extrudedRect = spriteNode.frame.rectByInsetting(dx: -extrusionRadius, dy: -extrusionRadius)
            
            // Check to see if the extruded rectangle for this obstacle contains the point we are looking for.
            if extrudedRect.contains(CGPoint(point)) {
                return extrudedRect
            }
            return nil
        }
    }
        
    /// Calculates the nearest point on the pathfinding graph.
    private func nearestPointOnGraphInScene(scene: LevelScene, forPoint point: float2) -> float2 {

        // The best point we have found so far.
        var bestPoint = point

        // The current set of rects that contain this point.
        var extrudedRectsContainingPoint = extrudedRectsInScene(scene, containingPoint: bestPoint)

        // Refine the point until it is no longer contained in any obstacle's extruded rect.
        while !extrudedRectsContainingPoint.isEmpty {
            /*
                Iterate over the extruded rects we found earlier, calculating
                the nearest point to `bestPoint` on their perimeter.
            */
            for rect in extrudedRectsContainingPoint {
                /*
                    Make sure that the best point found so far is still inside this rect,
                    and skip this rect if it is not.
                */
                if !rect.contains(CGPoint(bestPoint)) { continue }
                
                /*
                    Construct a slightly larger rect, so that the point we find on its edge
                    will be just outside the original rect's bounds. This helps to ensure
                    that the eventual point is definitely on-graph.
                */
                let largerRect = rect.rectByInsetting(dx: -1.0, dy: -1.0)
                
                // Create an array of the four corner points for this rect.
                let points = [
                    float2(x: Float(largerRect.minX), y: Float(largerRect.minY)),
                    float2(x: Float(largerRect.maxX), y: Float(largerRect.minY)),
                    float2(x: Float(largerRect.maxX), y: Float(largerRect.maxY)),
                    float2(x: Float(largerRect.minX), y: Float(largerRect.maxY))
                ]
                
                /*
                    Create an array to track the point-distance pairs from the
                    point to each of the rect's four sides.
                */
                var pointDistances: [(point: float2, distance: Float)] = points.indices.map { currentIndex in
                    // Find the next point around the rect, looping back at the end.
                    let nextIndex: Int
                    if currentIndex + 1 >= points.count {
                        nextIndex = 0
                    }
                    else {
                        nextIndex = currentIndex + 1
                    }
                    
                    // Find the nearst point to `bestPoint` on this side of the rect.
                    let lineSegment = (points[currentIndex], points[nextIndex])
                    let closestPointToBestPoint = bestPoint.nearestPointOnLineSegment(lineSegment)
                    
                    // Calculate the distance to the nearest point.
                    let deltaX = bestPoint.x - closestPointToBestPoint.x
                    let deltaY = bestPoint.y - closestPointToBestPoint.y
                    
                    // Save this point and its distance for future reference.
                    return (point: closestPointToBestPoint, distance: hypot(deltaX, deltaY))
                }
                
                // Sort the point-distance pairings to find the edge point with the shortest distance.
                pointDistances = pointDistances.sort { $0.distance < $1.distance }
                
                // Update the best-guess point to be the point with the shortest distance.
                bestPoint = pointDistances.first!.point
            }

            // Find out if this point is now on the graph. The `while` loop will use this on its next iteration.
            extrudedRectsContainingPoint = extrudedRectsInScene(scene, containingPoint: bestPoint)

        }
            
        // `bestPoint` is now definitely on the graph, and outside of all extruded rect containing `point`.
        return bestPoint
    }
    
    /**
        Connects a point to an obstacle graph as a node on that graph.
        Finds and connects the nearest point on the graph if the request point is off-graph.
    */
    private func connectedNodeForPoint(point: float2, onObstacleGraphInScene scene: LevelScene) -> GKGraphNode2D {
        
        // Create a node for this point.
        var pointNode = GKGraphNode2D(point: point)

        // Try to connect this node to the graph.
        scene.graph.connectNodeUsingObstacles(pointNode)

        /*
            Check to see if we were able to connect the node to the graph.
            If not, this means that the point is inside the buffer zone of an obstacle
            somewhere in the level. We can't pathfind to a point that is off-graph,
            so we try to find the nearest point that is on the graph, and pathfind
            to there instead.
        */
        if pointNode.connectedNodes.isEmpty {

            // The previous connection attempt failed, so remove the node from the graph.
            scene.graph.removeNodes([pointNode])
            
            // Calculate the nearest point to this point that is definitely on-graph.
            let onGraphPoint = nearestPointOnGraphInScene(scene, forPoint: point)

            // Create a new node for this on-graph point, and connect it to the graph.
            pointNode = GKGraphNode2D(point: onGraphPoint)
            scene.graph.connectNodeUsingObstacles(pointNode)
        }

        // We now know that `pointNode` is definitely connected to the graph.
        return pointNode
    }
    
    /// Pathfinds around obstacles to create a path between two points, and adds goals to follow that path.
    private func addGoalsToFollowPathFromStartPoint(startPoint: float2, toEndPoint endPoint: float2, pathRadius: Float, inScene scene: LevelScene) -> [CGPoint] {
     
        // Convert the provided `CGPoint`s into nodes for the `GPGraph`.
        let startNode = connectedNodeForPoint(startPoint, onObstacleGraphInScene: scene)
        let endNode = connectedNodeForPoint(endPoint, onObstacleGraphInScene: scene)
        
        // Find a path between these two nodes.
        let pathNodes = scene.graph.findPathFromNode(startNode, toNode: endNode) as! [GKGraphNode2D]
        
        // Create a new `GKPath` from the found nodes with the requested path radius.
        let path = GKPath(graphNodes: pathNodes, radius: pathRadius)
        
        // Add "follow path" and "stay on path" goals for this path.
        addFollowAndStayOnPathGoalsForPath(path)
        
        // Remove the "start" and "end" nodes now that the path has been calculated.
        scene.graph.removeNodes([startNode, endNode])
        
        // Convert the `GKGraphNode2D` nodes into `CGPoint`s for debug drawing.
        let pathPoints: [CGPoint] = pathNodes.map { CGPoint($0.position) }
        return pathPoints
    }
    
    /// Adds a goal to avoid all polygon obstacles in the scene.
    private func addAvoidObstaclesGoalForScene(scene: LevelScene) {
        setWeight(1.0, forGoal: GKGoal(toAvoidObstacles: scene.polygonObstacles, maxPredictionTime: GameplayConfiguration.TaskBot.maxPredictionTimeForObstacleAvoidance))
    }
    
    /// Adds a goal to attain a target speed.
    private func addTargetSpeedGoal(speed: Float) {
        setWeight(0.5, forGoal: GKGoal(toReachTargetSpeed: speed))
    }
    
    /// Adds goals to follow and stay on a path.
    private func addFollowAndStayOnPathGoalsForPath(path: GKPath) {
        // The "follow path" goal tries to keep the agent facing in a forward direction when it is on this path.
        setWeight(1.0, forGoal: GKGoal(toFollowPath: path, maxPredictionTime: GameplayConfiguration.TaskBot.maxPredictionTimeWhenFollowingPath, forward: true))

        // The "stay on path" goal tries to keep the agent on the path within the path's radius.
        setWeight(1.0, forGoal: GKGoal(toStayOnPath: path, maxPredictionTime: GameplayConfiguration.TaskBot.maxPredictionTimeWhenFollowingPath))
    }
}
