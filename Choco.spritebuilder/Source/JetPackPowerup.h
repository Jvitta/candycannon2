//
//  JetPackPowerup.h
//  Choco
//
//  Created by mac on 8/6/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface JetPackPowerup : CCNode

@property(nonatomic, strong) CCClippingNode *jetVisable;
@property(nonatomic, strong) CCSprite *jetOpaque;
@property(nonatomic, strong) CCNodeColor *rectColor;
@property(nonatomic, strong) CCSprite *jetImage;
@property(nonatomic, strong) CCSprite *whitePower;

@end
