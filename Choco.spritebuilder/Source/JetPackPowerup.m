//
//  JetPackPowerup.m
//  Choco
//
//  Created by mac on 8/6/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "JetPackPowerup.h"

@implementation JetPackPowerup

-(void)didLoadFromCCB{
    _rectColor = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.0f] width:_jetOpaque.contentSize.width height:0];
    _jetVisable = [CCClippingNode clippingNodeWithStencil:_rectColor];
    _rectColor.position = ccp(0,-_jetOpaque.contentSize.height/2);
    _rectColor.anchorPoint = ccp(0.5,0.0);
    _jetVisable.alphaThreshold = 0;
    [self addChild:_jetVisable];
    _jetVisable.position = ccp(0,0);
    _jetImage = [CCSprite spriteWithImageNamed:@"NewAssets/jetpack-powerup-nowhite.png"];
    [_jetVisable addChild:_jetImage];
    _jetImage.position = ccp(0,0);
    
}

@end
