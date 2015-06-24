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

      
        let random = GKRandomSource();
        let gauss = GKGaussianDistribution(randomSource: random, mean: 180, deviation: 20);
        
        
        var b170t190 = 0;
        var l170 = 0;
        var o190 = 0;
        var highest = Int.min;
        var lowest = Int.max;
        
        for(var i=0; i<20; i++) {
            let next = gauss.nextInt();
            if(next < 170) {
                l170++;
            } else if (next > 190) {
                o190++;
            } else {
                b170t190++;
            }
            highest = next > highest ? next : highest;
            lowest = next < lowest ? next : lowest;
            print(next);
        }
        
        print("b170t190: \(b170t190)");
        print("l170: \(l170)");
        print("o190: \(o190)");
        print("lowest: \(lowest)");
        print("highest: \(highest)");
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

