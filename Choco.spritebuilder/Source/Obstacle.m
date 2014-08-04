//
//  Obstacle.m
//  Choco
//
//  Created by mac on 7/26/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Obstacle.h"
#import "Warning.h"

@implementation Obstacle{
    float _warningHeight;
}

-(void)didLoadFromCCB{
    self.physicsBody.sensor = YES;
    self.physicsBody.collisionType = @"obstacle";
    int angle = arc4random()%3 + 1;
    switch(angle){
        case 1:
            self.rotation = 45;
            break;
        case 2:
            self.rotation = 135;
            break;
        case 3:
            self.rotation = 90;
            break;
    }
    CCActionRepeatForever *repeat = [CCActionRepeatForever actionWithAction:[CCActionRotateBy actionWithDuration:arc4random()%2 +1 angle:360]];
    [self runAction:repeat];
}
@end
