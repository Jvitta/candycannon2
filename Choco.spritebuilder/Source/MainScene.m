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
#import "Cannon.h"
#import "Bear.h"
#import "JetPackPowerup.h"
#import "HeightBar.h"
#import "GameOver.h"

@interface CGPointObject : NSObject

@property (nonatomic,readwrite) CGPoint ratio;
@property (nonatomic,readwrite) CGPoint offset;
@property (nonatomic,readwrite,unsafe_unretained) CCNode *child;

@end

typedef NS_ENUM(NSInteger, BearType) {
    Regular,
    HighlightedFull,
    HighlightedHalf,
    HighlightedLow,
    Angry
};

@implementation MainScene{
    BOOL _canFlap;
    BOOL _gameStarted;
    BOOL _gameOver;
    BOOL _startRotation;
    BOOL _accelerate;
    BOOL _isPelican;
    BOOL _firstTouch;
    BOOL _launched;
    BOOL _onShop;
    
    NSNumber *_score;
    int _candyNum;
    int _floackChance;
    int _flockType;
    int _maxCandy;
    float _candiesNeeded;
    float _obstacleHieght;
    float _cannonPower;
    
    BearType type;
    Pelican *_pelican;
    JetPackPowerup *_jetpack1;
    JetPackPowerup *_jetpack2;
    JetPackPowerup *_jetpack3;
    HeightBar *_heightBar;
    CCNodeGradient *_gradNode;
    CCNode *_contentNode;
    CCPhysicsNode *_physicsNode;
    CCLabelTTF *_distance;
    CCLabelTTF *_highScoreLabel;
    CCLabelTTF *_scoreLabel;
    
    CCSprite *shopButton;
    CCSprite *retryButton;
    CCSprite *woodEnd;
    Cannon *_cannon;
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
    GameOver *_gameOverNode;
    Bear *_bear;
    NSArray *_grounds;
    NSArray *_clouds;
    NSArray *_hills;
    NSArray *_backHills;
    NSArray *jetpacks;
    
    NSTimeInterval _sinceTouch;
    
    CGSize screenSize;
    CGPoint startPosition;
    NSMutableArray *obstaclePair;
    NSMutableArray *candies;
    NSMutableArray *bounceObjects;
    NSUserDefaults *defaults;
    NSNumber *_highscore;
    
    CCActionRepeatForever *_repeat;
    CCActionRepeatForever *_repeatBarSlide;
    CCActionRepeatForever *repeatRotate;
    
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
        type = Regular;
        _candiesNeeded = 6;
        _jetpack1.rectColor.contentSize = CGSizeMake(_jetpack1.rectColor.contentSize.width,_jetpack1.jetOpaque.contentSize.height);
        _firstTouch = YES;
        _obstacleSize = (Obstacle *) [CCBReader load:@"Obstacle"];
        _obstacleHieght = _obstacleSize.contentSize.height;
        _pelican.zOrder = 100;
        _canFlap = YES;
        _isPelican = NO;
        screenSize = [[CCDirector sharedDirector] viewSize];
        obstaclePair = [NSMutableArray array];
        candies = [NSMutableArray array];
        defaults = [NSUserDefaults standardUserDefaults];
        _parallaxHills = [CCParallaxNode node];
        _parallaxBackHills = [CCParallaxNode node];
        _parallaxClouds = [CCParallaxNode node];
    }
    return self;
}

-(void)didLoadFromCCB{
    self.userInteractionEnabled = YES;
    _heightBar.highlighter.opacity = 0.0f;
    _heightBar.cascadeOpacityEnabled = YES;
    _heightBar.opacity = 0.0;
    _cannon.slider.scaleY = 0;
    _cannon.zOrder = 1;
    _pelican.physicsBody.velocity = ccp(200,0);
    _clouds = @[_cloud1,_cloud2,_cloud3,_cloud4];
    _grounds = @[_ground1,_ground2];
    jetpacks = @[_jetpack1,_jetpack2,_jetpack3];
    _ground1.zOrder = -1;
    _ground2.zOrder = -1;
    _hills = @[_hill1,_hill2];
    _backHills = @[_backHill1,_backHill2];
    _hillsParallaxRatio = ccp(0.7,1);
    _cloudsParallaxRatio = ccp(0.3,1);
    _backHillsParallaxRatio = ccp(0.5,1);
    [_parallaxContainer addChild:_parallaxBackHills];
    [_parallaxContainer addChild:_parallaxHills];
    [_parallaxContainer addChild:_parallaxClouds];
    _maxCandy = _candiesNeeded * jetpacks.count;
    [self createCandy];
    
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

-(void)onEnter{
    [super onEnter];
    
    [self rotateCannon];
}
-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    //boost
    if(_candyNum >= _candiesNeeded && _heightBar.highlighter.opacity > 0){
        _candyNum -= _candiesNeeded;
        float _multiplier;
        float _opacity = ceilf(_heightBar.highlighter.opacity * 100);
        if (_opacity == 32) {
            _multiplier = 0.7;
        }
        else if (_opacity == 64){
            _multiplier = 1;
        }
        else if (_opacity == 100){
            _multiplier = 1.3;
        }
        float speed = (abs(_bear.physicsBody.velocity.x) + abs(_bear.physicsBody.velocity.y)*_multiplier);
        _bear.physicsBody.velocity = ccp(.6*speed,-1.2*speed);
        for(int i = 1;i <= jetpacks.count;i++){
            float fill = _candyNum - ((i * _candiesNeeded) - _candiesNeeded);
            JetPackPowerup *powerup = jetpacks[i-1];
            float fillheight = (fill/_candiesNeeded) * powerup.jetOpaque.contentSize.height;
            powerup.rectColor.contentSize = CGSizeMake(_jetpack1.rectColor.contentSize.width, clampf(fillheight,0,_jetpack1.jetOpaque.contentSize.height));
        }
    }
    //beginning launch
    if(_firstTouch == NO && !_launched){
        [_cannon.slider stopAction:_repeatBarSlide];
        _cannonPower = _cannon.slider.scaleY;
        _bear = (Bear *) [CCBReader load:@"Bear"];
        [_physicsNode addChild:_bear];
        CGPoint bearPosition = [_cannon.barrel convertToWorldSpace:ccp(41.3, 41.3)];
        _bear.position = [_physicsNode convertToNodeSpace:bearPosition];
        startPosition = _bear.position;
        
        CGPoint _barrelEnd = [_cannon.barrel convertToWorldSpace:ccp(137, 87)];
        _barrelEnd = [_cannon.parent convertToNodeSpace:_barrelEnd];
        CGPoint _worldSpace = [_cannon convertToWorldSpace:_cannon.barrel.position];
        CGPoint _barrelStart = [_cannon.parent convertToNodeSpace:_worldSpace];
        CGPoint forceDirection = ccpSub(_barrelEnd,_barrelStart);
        CGPoint finalForce = ccpMult(forceDirection,4.0f * (_cannonPower + 1));
        [_bear.physicsBody applyImpulse:finalForce];
        CCActionRotateBy *rotate = [CCActionRotateBy actionWithDuration:4 angle:360];
        repeatRotate = [CCActionRepeatForever actionWithAction:rotate];
        [_bear runAction:repeatRotate];
        CCActionFollow *follow = [CCActionFollow actionWithTarget:_bear worldBoundary:CGRectMake(0.0f,0.0f,CGFLOAT_MAX,_gradNode.contentSize.height)];
        [_contentNode runAction:follow];
        _launched = YES;
        CCActionFadeIn *fade = [CCActionFadeIn actionWithDuration:1];
        [_heightBar runAction:fade];
        
        CCActionMoveBy *moveUp = [CCActionMoveBy actionWithDuration:1 position:ccp(_position.x,_position.y + 2 * _heightBar.greenBlock.contentSize.height)];
        
        CCActionMoveBy *moveDown = [CCActionMoveBy actionWithDuration:1 position:ccp(_position.x,_position.y - 2 * _heightBar.greenBlock.contentSize.height)];
        
        CCActionEaseOut *easeOut = [CCActionEaseOut actionWithAction:moveUp rate:1.5];
        
        CCActionEaseIn *easeIn = [CCActionEaseIn actionWithAction:moveDown rate:1.5];
  
        CCActionSequence *sequence = [CCActionSequence actions:easeOut,easeIn, nil];
        CCActionRepeatForever *repeat = [CCActionRepeatForever actionWithAction:sequence];
        [_heightBar.greenBlock runAction:repeat];
    }
    if(_firstTouch == YES){
        _firstTouch = NO;
        [_cannon.barrel stopAction:_repeat];
        
        CCActionScaleTo *scaleBarIn = [CCActionScaleTo actionWithDuration:1 scaleX:1 scaleY:1];
        CCActionEaseIn *easeIn = [CCActionEaseIn actionWithAction:scaleBarIn rate:3];
        
        CCActionScaleTo *scaleBarOut = [CCActionScaleTo actionWithDuration:1 scaleX:1 scaleY:0];
        CCActionEaseOut *easeOut = [CCActionEaseOut actionWithAction:scaleBarOut rate:3];
        
        CCActionSequence *sequence = [CCActionSequence actions:easeIn,easeOut, nil];
        _repeatBarSlide = [CCActionRepeatForever actionWithAction:sequence];
        [_cannon.slider runAction:_repeatBarSlide];
    }
    if(!_gameOver && _isPelican){
        [_pelican.physicsBody applyAngularImpulse:5000.f];
        _accelerate = YES;
        _sinceTouch = 0.f;
        if(!_gameStarted){
            _physicsNode.gravity = ccp(0,-750);
            [self schedule:@selector(createObstacles) interval:3.0f repeat:INFINITY delay:0.0f];
            [self schedule:@selector(createCandy) interval:3.0f repeat:INFINITY delay:0.0f];
            _gameStarted = YES;
        }
    }
}

-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
    if(!_gameOver && _isPelican){
    _accelerate = NO;
    [_pelican.physicsBody applyAngularImpulse:-2000.f];
    }
}

-(void)update:(CCTime)delta{
    if(_launched && !_gameOver && _bear.physicsBody.velocity.x <= 1 && _bear.physicsBody.velocity.y <= 1){
        [self gameOver];
    }
    if(_bear.physicsBody.velocity.x <= 65 && _bear.physicsBody.velocity.y <= 65){
        [_bear stopAction:repeatRotate];
    }
     //_heightBar.playerCircle.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"NewAssets/BearOnBarHighlight.png"];
    if(!_gameOver && _launched){
        if(_heightBar.playerCircle.position.y > 46){
            type = Regular;
            _heightBar.highlighter.opacity = 0.0f;
        }
        if(_candyNum >= _candiesNeeded){
            if(_heightBar.playerCircle.position.y <= 14){
                type = HighlightedFull;
            }
            else if(_heightBar.playerCircle.position.y <= 28 && _heightBar.playerCircle.position.y >= 14){
                type = HighlightedHalf;
            }
            else if(_heightBar.playerCircle.position.y <= 46 && _heightBar.playerCircle.position.y >= 28){
                type = HighlightedLow;
            }
            switch(type){
                case HighlightedFull:
                    _heightBar.highlighter.opacity = 1.0f;
                    break;
                case HighlightedHalf:
                    _heightBar.highlighter.opacity = 0.64f;
                    break;
                case HighlightedLow:
                    _heightBar.highlighter.opacity = 0.32f;
                    break;
            }
            
        }
        _distance.string = [NSString stringWithFormat:@"%i",(int) (_bear.position.x - startPosition.x)/5];
        float heightPercent = (_bear.position.y - _ground1.contentSize.height)/_gradNode.contentSize.height;
        _heightBar.playerCircle.position = ccp(_heightBar.playerCircle.position.x, clampf(_heightBar.contentSize.height * heightPercent,0,_heightBar.contentSize.height*0.98));
    }
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
    //NSMutableArray *_deleteCandy = [NSMutableArray array];
    for(Candy *candy in candies){
        CGPoint worldSpace = [_physicsNode convertToWorldSpace:candy.position];
        CGPoint nodeSpace = [self convertToNodeSpace:worldSpace];
        if(nodeSpace.x <= -1 * candy.contentSize.width - 0.2*screenSize.width){
            candy.position = ccp(candy.position.x + screenSize.width*1.4,candy.position.y);
        }
        else if(nodeSpace.x >= screenSize.width*1.4){
            candy.position = ccp(candy.position.x - screenSize.width*1.4,candy.position.y);
        }
    }
    NSMutableArray *_deleteBounceObject = [NSMutableArray array];
    for(CCNode *bounceObject in bounceObjects){
        CGPoint worldSpace = [_physicsNode convertToWorldSpace:bounceObject.position];
        CGPoint nodeSpace = [self convertToNodeSpace:worldSpace];
        if(nodeSpace.x <= -1 * bounceObject.contentSize.width - 1.2*screenSize.width){
            [bounceObject removeFromParent];
            [_deleteBounceObject addObject:bounceObject];
        }
    }
    for(CCNode *bounceObject in _deleteBounceObject){
        [bounceObjects removeObject:bounceObject];
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
            [self createBounceObject];
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
-(void)rotateCannon{
    CCActionRotateBy *rotateCannon = [CCActionRotateBy actionWithDuration:1 angle:-90];
    CCActionRotateBy *rotateCannonBack = [CCActionRotateBy actionWithDuration:1 angle: 90];
    _repeat = [CCActionRepeatForever actionWithAction:[CCActionSequence actions:rotateCannon,rotateCannonBack, nil]];
    [_cannon.barrel runAction:_repeat];
}
-(BOOL)ccPhysicsCollisionPreSolve:(CCPhysicsCollisionPair *)pair ground:(CCNode *)nodeA bear:(CCNode *)nodeB{
    _bear.physicsBody.velocity = ccp(_bear.physicsBody.velocity.x * 0.94,_bear.physicsBody.velocity.y);
    
    return YES;
}

-(BOOL)ccPhysicsCollisionPreSolve:(CCPhysicsCollisionPair *)pair bounceObject:(CCNode *)nodeA bear:(CCNode *)nodeB{
    _bear.physicsBody.velocity = ccp(_bear.physicsBody.velocity.x * 0.94,_bear.physicsBody.velocity.y);
    [_bear.physicsBody applyImpulse:ccp(50,150)];
    return YES;
}

-(void)createBounceObject{
    CGPoint bounceWorldPosition;
    CGPoint bounceScreenPosition;
    CGPoint _bouncePosition;
    int chance;
    chance = arc4random()%3;
    if(chance == 0){
        CCNode *_bounceObject = [CCBReader load:@"BounceObject"];
        [_physicsNode addChild:_bounceObject];
        [bounceObjects addObject:_bounceObject];
        bounceWorldPosition = [_physicsNode convertToWorldSpace:self.position];
        bounceScreenPosition = [self convertToNodeSpace:bounceWorldPosition];
        _bouncePosition = ccp(-bounceScreenPosition.x + screenSize.width + arc4random()%(int) screenSize.width,_ground1.contentSize.height);
        _bounceObject.position = _bouncePosition;
    _bounceObject.physicsBody.sensor = YES;
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
    for(int i = 0;i < 15;i++){
        _floackChance = arc4random()%5 + 1;
        CGPoint candyWorldPosition = [_physicsNode convertToWorldSpace:self.position];
        CGPoint candyScreenPosition = [self convertToNodeSpace:candyWorldPosition];
        if(_floackChance == 1){
            CGPoint randomPosition = ccp(-candyScreenPosition.x + arc4random()%(int)screenSize.width*1.2,candyScreenPosition.y + arc4random()%(int)_gradNode.contentSize.height + screenSize.height/2);
            int _numInFlock = arc4random()%2 + 2;
            CGPoint speed = ccp(arc4random()%50 + 100,0);
            for(int i = 0;i < _numInFlock;i++){
                Candy *_candy = (Candy *) [CCBReader load:[NSString stringWithFormat:@"Candy%i",arc4random()%3 + 1]];
                [_physicsNode addChild:_candy];
                [candies addObject:_candy];
                _candy.position = ccp(randomPosition.x + arc4random()%100 - 50,randomPosition.y + arc4random()%100 - 50);
                _candy.physicsBody.velocity = speed;
            }
        }
        else{
        Candy *_candy = (Candy *) [CCBReader load:[NSString stringWithFormat:@"Candy%i",arc4random()%3 + 1]];
        [_physicsNode addChild:_candy];
        [candies addObject:_candy];
        _candy.position = ccp(-candyScreenPosition.x + arc4random()%(int)screenSize.width*1.2,candyScreenPosition.y + arc4random()%(int)_gradNode.contentSize.height + screenSize.height/2);
        _candy.physicsBody.velocity = ccp(arc4random()%50 + 100,0);
        }
    }
}

-(void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair choco:(CCNode *)nodeA ground:(CCNode *)nodeB{
    if(!_gameOver){
    [self gameOver];
    }
}

-(BOOL)ccPhysicsCollisionPreSolve:(CCPhysicsCollisionPair *)pair bear:(CCNode *)nodeA candy:(CCNode *)nodeB{
    if(!_gameOver){
        _candyNum += 1;
        for(int i = 1;i <= jetpacks.count;i++){
            float fill = _candyNum - ((i * _candiesNeeded) - _candiesNeeded);
            JetPackPowerup *powerup = jetpacks[i-1];
            float fillheight = (fill/_candiesNeeded) * powerup.jetOpaque.contentSize.height;
            powerup.rectColor.contentSize = CGSizeMake(_jetpack1.rectColor.contentSize.width, clampf(fillheight,0,_jetpack1.jetOpaque.contentSize.height));
        }
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
-(void)shop{
    if(!_onShop){
    CCAnimationManager *animationManager = _gameOverNode.userObject;
    [animationManager runAnimationsForSequenceNamed:@"SwitchStatsToShop"];
    }
    _onShop = YES;
}

-(void)stats{
    if(_onShop){
    CCAnimationManager *animationManager = _gameOverNode.userObject;
    [animationManager runAnimationsForSequenceNamed:@"SwitchShopToStats"];
    }
    _onShop = NO;
}

-(void)gameOver{
    
    CCAnimationManager *animationManager = self.userObject;
    [animationManager runAnimationsForSequenceNamed:@"MoveJetPacksAndBar"];
    
    _gameOverNode = (GameOver *) [CCBReader load:@"GameOver" owner:self];
    CCActionMoveBy *moveBar = [CCActionMoveBy actionWithDuration:1 position:ccp(_position.x - self.contentSize.width,_position.y)];
    [_heightBar runAction:moveBar];
    //NSNumber *_curHighScore = [defaults objectForKey:@"highscore"];
    [self addChild:_gameOverNode];
    [self unschedule:@selector(createObstacles)];
    [self unschedule:@selector(createCandy)];
    /*_score = [NSNumber numberWithInt:[_distance.string integerValue]];
    _scoreLabel.string = [NSString stringWithFormat:@"%@",_score];
    if(_score > _curHighScore){
        _highscore = _score;
        [defaults setInteger:_highscore forKey:@"highscore"];
    }
    _highScoreLabel.string = [defaults objectForKey:@"highscore"];*/
    _gameOverNode.position = ccp(screenSize.width/2,screenSize.height/2);
    _gameOver = YES;
}
@end