//
//  HeightBar.m
//  Choco
//
//  Created by Jack Vittimberga on 8/12/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "HeightBar.h"

@implementation HeightBar

- (instancetype)init
{
    self = [super init];
    if (self) {
        /*_highlighter = [CCSprite spriteWithImageNamed:@"NewAssets/BearOnBarHighlighter.png"];
        _highlighter.zOrder = -1;
        _highlighter.position = ccp(0,0);
        _highlighter.anchorPoint = ccp(0,0);*/
    }
    return self;
}

-(void)didLoadFromCCB{
    _highlighter.zOrder = -1;
}

@end
