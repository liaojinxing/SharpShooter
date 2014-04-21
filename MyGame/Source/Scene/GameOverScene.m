//
//  GameOverScene.m
//  MyGame
//
//  Created by liaojinxing on 14-4-8.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import "GameOverScene.h"
#import "MainScene.h"
@implementation GameOverScene
- (id)initWithSize:(CGSize)size hitNums:(NSInteger)hitNums
{
  if (self = [super initWithSize:size]) {
    self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];

    NSString *message = [NSString stringWithFormat:@"你击落了%d 只怪兽！", hitNums];
    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    label.text = message;
    label.fontSize = 30;
    label.fontColor = [SKColor blackColor];
    label.position = CGPointMake(self.size.width / 2, self.size.height / 2);
    [self addChild:label];

    SKLabelNode *nextGameNode = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    nextGameNode.position = CGPointMake(self.frame.size.width - 100, 50);
    nextGameNode.name = @"NextGame";
    nextGameNode.fontSize = 20;
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
         }]
      ]]
    ];
  }
}

@end
