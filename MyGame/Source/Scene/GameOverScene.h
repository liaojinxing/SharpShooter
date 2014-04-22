//
//  GameOverScene.h
//  MyGame
//
//  Created by liaojinxing on 14-4-8.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef NS_ENUM(NSInteger, GameOverReason) {
  kProjectileUseUp = 0,
  kKillAllMonsters,
  kLoseMonster,
};


@interface GameOverScene : SKScene

-(id)initWithSize:(CGSize)size hitNums:(NSInteger)hitNums reason:(GameOverReason)reason;

@end
