//
//  GameOverScene.m
//  MyGame
//
//  Created by liaojinxing on 14-4-8.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import "GameOverScene.h"
#import "MyScene.h"
@implementation GameOverScene
- (id)initWithSize:(CGSize)size won:(BOOL)won
{
  if (self = [super initWithSize:size]) {
    self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];

    NSString *message;
    if (won) {
      message = @"老鹰都被你打跑了耶";
    } else {
      message = @"啊哦，小鸡都被老鹰抓走了 :[";
    }

    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    label.text = message;
    label.fontSize = 40;
    label.fontColor = [SKColor blackColor];
    label.position = CGPointMake(self.size.width / 2, self.size.height / 2);
    [self addChild:label];

    [self runAction:
     [SKAction sequence:@[
        [SKAction waitForDuration:3.0],
        [SKAction runBlock:^{
           // 5
           SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
           SKScene *myScene = [[MyScene alloc] initWithSize:self.size];
           [self.view presentScene:myScene transition:reveal];
         }]
      ]]
    ];
  }
  return self;
}

@end
