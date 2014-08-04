//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"
#import "Pelican.h"
#import "Obstacle.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#import "Warning.h"
#import "ObstacleWarning.h"
#import "Candy.h"

@interface CGPointObject : NSObject

@property (nonatomic,readwrite) CGPoint ratio;
@property (nonatomic,readwrite) CGPoint offset;
@property (nonatomic,readwrite,unsafe_unretained) CCNode *child;

@end

@implementation MainScene{
    BOOL _canFlap;
    BOOL _gameStarted;
    BOOL _gameOver;
    BOOL _startRotation;
    BOOL _accelerate;
    
    NSNumber *_score;
    int _candyNum;
    int _floackChance;
    int _flockType;
    float _obstacleHieght;
    
    Pelican *_pelican;
    CCNodeGradient *_gradNode;
    CCNode *_contentNode;
    CCPhysicsNode *_physicsNode;
    CCLabelTTF *_distance;
    CCLabelTTF *_highScoreLabel;
    CCLabelTTF *_scoreLabel;
    
    CCNode *_cloud1;
    CCNode *_cloud2;
    CCNode *_cloud3;
    CCNode *_cloud4;
    Obstacle *_obstacleSize;
    CCNode *_ground1;
    CCNode *_ground2;
    CCNode *_hill1;
    CCNode *_hill2;
    CCNode *_backHill1;
    CCNode *_backHill2;
    CCNode *_gameOverNode;
    NSArray *_grounds;
    NSArray *_clouds;
    NSArray *_hills;
    NSArray *_backHills;
    
    NSTimeInterval _sinceTouch;
    
    CGSize screenSize;
    CGPoint startPosition;
    NSMutableArray *obstaclePair;
    NSMutableArray *candies;
    NSUserDefaults *defaults;
    NSNumber *_highscore;
    
    CGPoint _hillsParallaxRatio;
    CGPoint _cloudsParallaxRatio;
    CGPoint _backHillsParallaxRatio;
    CCNode *_parallaxContainer;
    CCParallaxNode *_parallaxHills;
    CCParallaxNode *_parallaxClouds;
    CCParallaxNode *_parallaxBackHills;
}

- (id)init
{
    self = [super init];
    if (self) {
        _obstacleSize = (Obstacle *) [CCBReader load:@"Obstacle"];
        _obstacleHieght = _obstacleSize.contentSize.height;
        _pelican.zOrder = 100;
        _canFlap = YES;
        screenSize = [[CCDirector sharedDirector] viewSize];
        obstaclePair = [NSMutableArray array];
        candies = [NSMutableArray array];
        defaults = [NSUserDefaults standardUserDefaults];
        _parallaxHills = [CCParallaxNode node];
        _parallaxBackHills = [CCParallaxNode node];
        _parallaxClouds = [CCParallaxNode node];
        _gameOverNode = [CCBReader load:@"GameOver" owner:self];
    }
    return self;
}

-(void)didLoadFromCCB{
    self.userInteractionEnabled = YES;
    CCActionFollow *follow = [CCActionFollow actionWithTarget:_pelican worldBoundary:CGRectMake(0.0f,0.0f,CGFLOAT_MAX,_gradNode.contentSize.height)];
    [_contentNode runAction:follow];
    _pelican.physicsBody.velocity = ccp(200,0);
    _clouds = @[_cloud1,_cloud2,_cloud3,_cloud4];
    _grounds = @[_ground1,_ground2];
    _hills = @[_hill1,_hill2];
    _backHills = @[_backHill1,_backHill2];
    _hillsParallaxRatio = ccp(0.7,1);
    _cloudsParallaxRatio = ccp(0.3,1);
    _backHillsParallaxRatio = ccp(0.5,1);
    [_parallaxContainer addChild:_parallaxBackHills];
    [_parallaxContainer addChild:_parallaxHills];
    [_parallaxContainer addChild:_parallaxClouds];
    
    _physicsNode.collisionDelegate = self;
    for (CCNode *backHill in _backHills) {
        CGPoint offset = backHill.position;
        [_contentNode removeChild:backHill cleanup:NO];
        [_parallaxBackHills addChild:backHill z:-1 parallaxRatio:_backHillsParallaxRatio positionOffset:offset];
    }
    for (CCNode *hill in _hills) {
        CGPoint offset = hill.position;
        [_contentNode removeChild:hill cleanup:NO];
        [_parallaxHills addChild:hill z:0 parallaxRatio:_hillsParallaxRatio positionOffset:offset];
    }
    for (CCNode *cloud in _clouds) {
        CGPoint offset = cloud.position;
        [_contentNode removeChild:cloud cleanup:NO];
        [_parallaxClouds addChild:cloud z:0 parallaxRatio:_cloudsParallaxRatio positionOffset:offset];
    }
}

-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    if(!_gameOver){
        [_pelican.physicsBody applyAngularImpulse:5000.f];
        _accelerate = YES;
        _sinceTouch = 0.f;
        if(!_gameStarted){
            startPosition = _pelican.position;
            _physicsNode.gravity = ccp(0,-750);
            [self schedule:@selector(createObstacles) interval:3.0f repeat:INFINITY delay:0.0f];
            [self schedule:@selector(createCandy) interval:3.0f repeat:INFINITY delay:0.0f];
            _gameStarted = YES;
        }
    }
}

-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
    _accelerate = NO;
    if(!_gameOver){
    [_pelican.physicsBody applyAngularImpulse:-2000.f];
    }
}

-(void)update:(CCTime)delta{
    if(_gameStarted){
        _pelican.physicsBody.velocity = ccp(_pelican.physicsBody.velocity.x + 0.1,_pelican.physicsBody.velocity.y);
        if(_accelerate && !_gameOver){
            _pelican.physicsBody.velocity = ccp(_pelican.physicsBody.velocity.x,clampf(_pelican.physicsBody.velocity.y + 50,-500,300));
        }
        if(_pelican.position.y > _gradNode.contentSize.height){
            if(!_gameOver){
            [self gameOver];
            }
        }
        if(!_gameOver){
        _distance.string = [NSString stringWithFormat:@"%i",(int) (_pelican.position.x - startPosition.x)/5];
        }
        _sinceTouch += delta;
        _pelican.rotation = clampf(_pelican.rotation, -15.f, 30.f);
        
        if (_pelican.physicsBody.allowsRotation) {
            float angularVelocity = clampf(_pelican.physicsBody.angularVelocity, -2.f, 1.f);
            _pelican.physicsBody.angularVelocity = angularVelocity;
        }
    }
    for (CCNode *ground in _grounds) {
        CGPoint groundWorldPosition = [_physicsNode convertToWorldSpace:ground.position];
        CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
        // if the left corner is one complete width off the screen, move it to the right
            if (groundScreenPosition.x <= (-1 * ground.contentSize.width) - 30) {
                ground.position = ccp(ground.position.x + 2 * ground.contentSize.width - 1,ground.position.y);
            }
    }
    NSMutableArray *_deleteObs = [NSMutableArray array];
    for(ObstacleWarning *obs in obstaclePair){
            CGPoint worldSpace = [_physicsNode convertToWorldSpace:obs.obstacle.position];
            CGPoint nodeSpace = [self convertToNodeSpace:worldSpace];
            obs.warning.position = ccp(obs.warning.position.x,nodeSpace.y);
            obs.warning.warningSprite.opacity = clampf(1 - (nodeSpace.x/1000 - obs.warning.position.x/1000),0,1);
                if(obs.warning.warningSprite.opacity == 1){
                    
                }
                if(nodeSpace.x < obs.warning.position.x){
                    [obs.warning removeFromParent];
                    obs.warning = nil;
                }
                if(nodeSpace.x < 0 - _obstacleHieght){
                    [obs.obstacle removeFromParent];
                    obs.obstacle = nil;
                }
            if(!obs.warning && !obs.obstacle){
                [_deleteObs addObject:obs];
            }
    }
    NSMutableArray *_deleteCandy = [NSMutableArray array];
    for(Candy *candy in candies){
        CGPoint worldSpace = [_physicsNode convertToWorldSpace:candy.position];
        CGPoint nodeSpace = [self convertToNodeSpace:worldSpace];
        if(nodeSpace.x < -1 * candy.contentSize.width){
            [candy removeFromParent];
            [_deleteCandy addObject:candy];
        }
    }
    for(CCNode *candy in _deleteCandy){
        [candies removeObject:candy];
    }
    for(CCNode *obs in _deleteObs){
        [obstaclePair removeObject:obs];
    }
    for (CCNode *backHill in _backHills) {
        // get the world position of the ground
        CGPoint hillWorldPosition = [_physicsNode convertToWorldSpace:backHill.position];
        // get the screen position of the ground
        CGPoint hillScreenPosition = [self convertToNodeSpace:hillWorldPosition];
        // if the left corner is one complete width off the screen, move it to the right
        if (hillScreenPosition.x <= (-1 * backHill.contentSize.width)) {
            for (CGPointObject *child in _parallaxBackHills.parallaxArray) {
                if (child.child == backHill) {
                    child.offset = ccp(child.offset.x + 2 * backHill.contentSize.width - 3, child.offset.y);
                }
            }
        }
    }
    for (CCNode *hill in _hills) {
        // get the world position of the ground
        CGPoint hillWorldPosition = [_physicsNode convertToWorldSpace:hill.position];
        // get the screen position of the ground
        CGPoint hillScreenPosition = [self convertToNodeSpace:hillWorldPosition];
        // if the left corner is one complete width off the screen, move it to the right
        if (hillScreenPosition.x <= (-1 * hill.contentSize.width)) {
            for (CGPointObject *child in _parallaxHills.parallaxArray) {
                if (child.child == hill) {
                    child.offset = ccp(child.offset.x + 2 * hill.contentSize.width - 3, child.offset.y);
                }
            }
        }
    }
    for (CCNode *cloud in _clouds) {
        // get the world position of the ground
        CGPoint cloudWorldPosition = [_physicsNode convertToWorldSpace:cloud.position];
        // get the screen position of the ground
        CGPoint cloudScreenPosition = [self convertToNodeSpace:cloudWorldPosition];
        // if the left corner is one complete width off the screen, move it to the right
        if (cloudScreenPosition.x <= -1 * cloud.contentSize.width) {
            for (CGPointObject *child in _parallaxClouds.parallaxArray) {
                if (child.child == cloud) {
                    child.offset = ccp(child.offset.x + 2 * screenSize.width, child.offset.y);
                }
            }
        }
    }
}

-(void)createObstacles{
    
    NSMutableArray *_newObsSet = [NSMutableArray array];
    BOOL _canPlace;
    CGPoint ObsWorldPosition;
    CGPoint ObsScreenPosition;
    CGPoint _obsPosition;
    for(int i = 0;i < 3;i++){
        _canPlace = NO;
        Obstacle *_obstacle = (Obstacle *) [CCBReader load:@"Obstacle"];
        while(!_canPlace){
            //do while the position is taken
            ObsWorldPosition = [_physicsNode convertToWorldSpace:self.position];
            ObsScreenPosition = [self convertToNodeSpace:ObsWorldPosition];
            _obsPosition = ccp(-ObsScreenPosition.x + 2 * screenSize.width + arc4random()%(int) screenSize.width,ObsScreenPosition.y + arc4random()%(int)_gradNode.contentSize.height + _hill1.contentSize.height * 2);
            if(_newObsSet.count == 0){
                _canPlace = true;
            }
                //check if I can place at this position
                for(int i = 0;i < _newObsSet.count && !_canPlace;i++){
                    float _disBetweenObs;
                    CCNode *node = _newObsSet[i];
                    _disBetweenObs = ccpDistance(_obsPosition, node.position);
                    if(!(_disBetweenObs >= _obstacle.contentSize.height + 50)){
                        break;
                    }
                    else if(i == _newObsSet.count - 1){
                        _canPlace = YES;
                    }
                }
        }
        [_physicsNode addChild:_obstacle];
        ObstacleWarning *obstacleWarPair = [[ObstacleWarning alloc] init];
        obstacleWarPair.obstacle = _obstacle;
        _obstacle.position = _obsPosition;
        Warning *_warning = (Warning *) [CCBReader load:@"Warning"];
        obstacleWarPair.warning = _warning;
        _warning.position = ccp(screenSize.width,_obstacle.position.y);
        [self addChild:_warning];
        [obstaclePair addObject:obstacleWarPair];
        [_newObsSet addObject:_obstacle];
    }
}
-(void)createCandy{
    for(int i = 0;i < 10;i++){
        _floackChance = arc4random()%5 + 1;
        CGPoint candyWorldPosition = [_physicsNode convertToWorldSpace:self.position];
        CGPoint candyScreenPosition = [self convertToNodeSpace:candyWorldPosition];
        if(_floackChance == 1){
            _flockType = arc4random()%3 + 1;
            CCNode *_flock = [CCBReader load:[NSString stringWithFormat:@"Flocks/Flock%i",_flockType]];
            [_physicsNode addChild:_flock];
            [candies addObject:_flock];
            _flock.position = ccp(-candyScreenPosition.x + screenSize.width + 300 + arc4random()%1500,candyScreenPosition.y + arc4random()%(int)_gradNode.contentSize.height + 300);
        }
        else{
        Candy *_candy = (Candy *) [CCBReader load:@"Candy"];
        [_physicsNode addChild:_candy];
        [candies addObject:_candy];
        _candy.position = ccp(-candyScreenPosition.x + screenSize.width + 100 + arc4random()%1500,candyScreenPosition.y + arc4random()%(int)_gradNode.contentSize.height + 300);
        }
    }
}

-(void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair choco:(CCNode *)nodeA ground:(CCNode *)nodeB{
    if(!_gameOver){
    [self gameOver];
    }
}

-(BOOL)ccPhysicsCollisionPreSolve:(CCPhysicsCollisionPair *)pair choco:(CCNode *)nodeA candy:(CCNode *)nodeB{
    if(!_gameOver){
        _candyNum += 1;
        [nodeB removeFromParent];
    }
    return YES;
}

-(BOOL)ccPhysicsCollisionPreSolve:(CCPhysicsCollisionPair *)pair choco:(CCNode *)nodeA obstacle:(CCNode *)nodeB{
    if(!_gameOver){
    [self gameOver];
    }
    return YES;
}
-(void)retry:(id)sender{
    CCScene *gameplayScene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:gameplayScene];
}
-(void)gameOver{
    NSNumber *_curHighScore = [defaults objectForKey:@"highscore"];
    [self addChild:_gameOverNode];
    [self unschedule:@selector(createObstacles)];
    [self unschedule:@selector(createCandy)];
    _score = [NSNumber numberWithInt:[_distance.string integerValue]];
    _scoreLabel.string = [NSString stringWithFormat:@"%@",_score];
    if(_score > _curHighScore){
        _highscore = _score;
        [defaults setInteger:_highscore forKey:@"highscore"];
    }
    _highScoreLabel.string = [NSString stringWithFormat:@"%@",_highscore];
    _gameOverNode.position = ccp(screenSize.width/2,screenSize.height/2);
    _gameOver = YES;
}
@end