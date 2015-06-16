//
//  Gameworld.swift
//  WumpusEnvironment
//
//  Created by Michael Freiwald on 16.06.15.
//  Copyright © 2015 Michael Freiwald. All rights reserved.
//

import Foundation
import GameplayKit

class Gameworld: NSObject {
    
    let width: Int32 = 10;
    let height: Int32 = 10;

    let graph: GKGridGraph
    
    override init() {
        
        self.graph = GKGridGraph(fromGridStartingAt: [0,0], width: width, height: height, diagonalsAllowed: false);
        
        let startNode = self.graph.nodeAtGridPosition([0,0]);
        let endNode = self.graph.nodeAtGridPosition([9,9]);
        
        if(startNode != nil && endNode != nil) {
            let pathOfNodes = self.graph.findPathFromNode(startNode!, toNode: endNode!);
            
            for node in pathOfNodes {
                if(node is GKGridGraphNode) {
                    let node = node as! GKGridGraphNode;
                    print(node.gridPosition);
                }
            }
            
        }
        
        
    }
    
    
}