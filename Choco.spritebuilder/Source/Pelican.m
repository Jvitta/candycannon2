//
//  Pelican.m
//  Choco
//
//  Created by mac on 7/26/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Pelican.h"

@implementation Pelican

-(void)didLoadFromCCB{
    self.physicsBody.collisionType = @"choco";
}

@end
