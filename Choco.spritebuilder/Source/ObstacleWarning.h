//
//  ObstacleWarning.h
//  Choco
//
//  Created by mac on 7/28/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Obstacle;
@class Warning;

@interface ObstacleWarning : NSObject

@property(nonatomic, weak) Obstacle *obstacle;
@property(nonatomic, weak) Warning *warning;

@end
