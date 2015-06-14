//
//  ViewController.swift
//  GameplaySingleApp
//
//  Created by Michael Freiwald on 14.06.15.
//  Copyright © 2015 Michael Freiwald. All rights reserved.
//

import UIKit
import GameplayKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let d20 = GKShuffledDistribution.d20();
        
        var array = [Int]()
        for(var i=0; i<20; i++) {
            let choice = d20.nextInt();
            array.append(choice);
        }
        
        print(array);

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

