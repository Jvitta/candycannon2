//
//  Menu.m
//  Choco
//
//  Created by mac on 7/28/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Menu.h"
#import "CCPhysics+ObjectiveChipmunk.h"

@implementation Menu{
    CCNode *_cloud1;
    CCNode *_cloud2;
    CCNode *_cloud3;
    CCNode *_cloud4;
    NSArray *_clouds;
}

-(void)didLoadFromCCB{
    _clouds = @[_cloud1,_cloud2,_cloud3,_cloud4];
    self.userInteractionEnabled = YES;
}

-(void)update:(CCTime)delta{
    _cloud1.position = ccp(_cloud1.position.x -0.50,_cloud1.position.y);
    _cloud2.position = ccp(_cloud2.position.x -0.20,_cloud2.position.y);
    _cloud3.position = ccp(_cloud3.position.x -0.40,_cloud3.position.y);
    _cloud4.position = ccp(_cloud4.position.x -0.45,_cloud4.position.y);
    
    for(CCNode *cloud in _clouds){
        if(cloud.position.x < -200){
            cloud.position = ccp([[CCDirector sharedDirector] viewSize].width + 200,cloud.position.y);
        }
    }
}

-(void)start{
    CCScene *gameplayScene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:gameplayScene];
}

@end
