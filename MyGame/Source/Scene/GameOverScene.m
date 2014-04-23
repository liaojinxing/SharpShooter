//
//  GameOverScene.m
//  MyGame
//
//  Created by liaojinxing on 14-4-8.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import "GameOverScene.h"
#import "MainScene.h"
#import "AppConstants.h"

@implementation GameOverScene
- (id)initWithSize:(CGSize)size hitNums:(NSInteger)hitNums reason:(GameOverReason)reason
{
  if (self = [super initWithSize:size]) {
    self.backgroundColor = [SKColor colorWithRed:0.2 green:0.4 blue:0.2 alpha:1.0];

    NSString *reasonString = @"";
    switch (reason) {
      case kKillAllMonsters:
        reasonString = @"哦耶！所有怪兽都挂了";
        break;
      case kProjectileUseUp:
        reasonString = @"啊哦，没有更多的子弹了";
        break;
      case kLoseMonster:
        reasonString = @"哦漏，怪兽都跑家里来了";
        break;
      default:
        break;
    }
    SKLabelNode *reasonLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    reasonLabel.text = reasonString;
    reasonLabel.fontSize = 30;
    reasonLabel.fontColor = [SKColor blackColor];
    reasonLabel.position = CGPointMake(self.size.width / 2, self.size.height / 2);
    [self addChild:reasonLabel];
    
    SKLabelNode *countLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    countLabel.text = [NSString stringWithFormat:@"你击落了%d只怪兽！", hitNums];;
    countLabel.fontSize = 30;
    countLabel.fontColor = [SKColor blackColor];
    countLabel.position = CGPointMake(self.size.width / 2, self.size.height / 2 - 40);
    [self addChild:countLabel];
    

    SKLabelNode *nextGameNode = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    nextGameNode.position = CGPointMake(self.frame.size.width - 70, 30);
    nextGameNode.name = @"NextGame";
    nextGameNode.fontSize = 25;
    nextGameNode.text = @"再来一发";
    nextGameNode.fontColor = [SKColor redColor];
    [self addChild:nextGameNode];
  }
  return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInNode:self];
  SKNode *node = [self nodeAtPoint:location];

  if ([node.name isEqualToString:@"NextGame"]) {
    [self runAction:
     [SKAction sequence:@[
        [SKAction waitForDuration:0.0],
        [SKAction runBlock:^{
           SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
           SKScene *myScene = [[MainScene alloc] initWithSize:self.size];
           [self.view presentScene:myScene transition:reveal];
           [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationGameStart object:nil];
         }]
      ]]
    ];
  }
}

@end
