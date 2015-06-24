//: Playground - noun: a place where people can play

import UIKit
import GameplayKit

print("Hallo");



let x = 4;
let y = 5;
let z = x * y;
print(z);

let d100 = GKRandomDistribution(forDieWithSideCount: 100);
d100.nextInt();
d100.nextBool();
d100.nextUniform();

for(var i=0; i<100; i++) {
    d100.nextUniform();
}