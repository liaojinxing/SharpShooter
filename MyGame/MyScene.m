//
//  MyScene.m
//  MyGame
//
//  Created by liaojinxing on 14-4-8.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//


static inline CGPoint rwAdd(CGPoint a, CGPoint b) {
  return CGPointMake(a.x + b.x, a.y + b.y);
}
static inline CGPoint rwSub(CGPoint a, CGPoint b) {
  return CGPointMake(a.x - b.x, a.y - b.y);
}
static inline CGPoint rwMult(CGPoint a, float b) {
  return CGPointMake(a.x * b, a.y * b);
}
static inline float rwLength(CGPoint a) {
  return sqrtf(a.x * a.x + a.y * a.y);
}
// 让向量的长度（模）等于1
static inline CGPoint rwNormalize(CGPoint a) {
  float length = rwLength(a);
  return CGPointMake(a.x / length, a.y / length);
}

static const uint32_t projectileCategory     =  0x1 << 0;
static const uint32_t monsterCategory        =  0x1 << 1;


#import "MyScene.h"
#import "GameOverScene.h"

@interface MyScene () <SKPhysicsContactDelegate>

@property (nonatomic) SKSpriteNode *player;
@property (nonatomic) NSTimeInterval lastSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) int monstersDestroyed;


@end

@implementation MyScene
- (id)initWithSize:(CGSize)size
{
  if (self = [super initWithSize:size]) {
    // 2
    NSLog(@"Size: %@", NSStringFromCGSize(size));

    // 3
    self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];

    // 4
    self.player = [SKSpriteNode spriteNodeWithImageNamed:@"player"];
    self.player.position = CGPointMake(self.player.size.width / 2, self.frame.size.height / 2);
    [self addChild:self.player];
    
    self.physicsWorld.gravity = CGVectorMake(0,0);
    self.physicsWorld.contactDelegate = self;
  }
  return self;
}

- (void)addMonster
{
  // 创建怪物Sprite
  SKSpriteNode *monster = [SKSpriteNode spriteNodeWithImageNamed:@"monster"];

  // 决定怪物在竖直方向上的出现位置
  int minY = monster.size.height / 2;
  int maxY = self.frame.size.height - monster.size.height / 2;
  int rangeY = maxY - minY;
  int actualY = (arc4random() % rangeY) + minY;

  // Create the monster slightly off-screen along the right edge,
  // and along a random position along the Y axis as calculated above
  monster.position = CGPointMake(self.frame.size.width + monster.size.width / 2, actualY);
  [self addChild:monster];

  // 设置怪物的速度
  int minDuration = 2.0;
  int maxDuration = 4.0;
  int rangeDuration = maxDuration - minDuration;
  int actualDuration = (arc4random() % rangeDuration) + minDuration;

  // Create the actions
  SKAction *actionMove = [SKAction moveTo:CGPointMake(-monster.size.width / 2, actualY) duration:actualDuration];
  SKAction *actionMoveDone = [SKAction removeFromParent];

  SKAction * loseAction = [SKAction runBlock:^{
    SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
    SKScene * gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:NO];
    [self.view presentScene:gameOverScene transition: reveal];
  }];
  [monster runAction:[SKAction sequence:@[actionMove, loseAction, actionMoveDone]]];
  
  monster.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:monster.size]; // 1
  monster.physicsBody.dynamic = YES; // 2
  monster.physicsBody.categoryBitMask = monsterCategory; // 3
  monster.physicsBody.contactTestBitMask = projectileCategory; // 4
  monster.physicsBody.collisionBitMask = 0; // 5
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast {
  self.lastSpawnTimeInterval += timeSinceLast;
  if (self.lastSpawnTimeInterval > 1) {
    self.lastSpawnTimeInterval = 0;
    [self addMonster];
  }
}

- (void)update:(NSTimeInterval)currentTime {
  // 获取时间增量
  // 如果我们运行的每秒帧数低于60，我们依然希望一切和每秒60帧移动的位移相同
  CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
  self.lastUpdateTimeInterval = currentTime;
  if (timeSinceLast > 1) { // 如果上次更新后得时间增量大于1秒
    timeSinceLast = 1.0 / 60.0;
    self.lastUpdateTimeInterval = currentTime;
  }
  
  [self updateWithTimeSinceLastUpdate:timeSinceLast];
  
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  
  [self runAction:[SKAction playSoundFileNamed:@"pew-pew-lei.caf" waitForCompletion:NO]];
  
  // 1 - 选择其中的一个touch对象
  UITouch * touch = [touches anyObject];
  CGPoint location = [touch locationInNode:self];
  
  // 2 - 初始化子弹的位置
  SKSpriteNode * projectile = [SKSpriteNode spriteNodeWithImageNamed:@"projectile"];
  projectile.position = self.player.position;
  
  // 3- 计算子弹移动的偏移量
  CGPoint offset = rwSub(location, projectile.position);
  
  // 4 - 如果子弹是向后射的那就不做任何操作直接返回
  if (offset.x <= 0) return;
  
  // 5 - 好了，把子弹添加上吧，我们已经检查了两次位置了
  [self addChild:projectile];
  // 6 - 获取子弹射出的方向
  CGPoint direction = rwNormalize(offset);
  
  // 7 - 让子弹射得足够远来确保它到达屏幕边缘
  CGPoint shootAmount = rwMult(direction, 1000);
  
  // 8 - 把子弹的位移加到它现在的位置上
  CGPoint realDest = rwAdd(shootAmount, projectile.position);
  
  // 9 - 创建子弹发射的动作
  float velocity = 480.0/1.0;
  float realMoveDuration = self.size.width / velocity;
  SKAction * actionMove = [SKAction moveTo:realDest duration:realMoveDuration];
  SKAction * actionMoveDone = [SKAction removeFromParent];
  [projectile runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
  
  projectile.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:projectile.size.width/2];
  projectile.physicsBody.dynamic = YES;
  projectile.physicsBody.categoryBitMask = projectileCategory;
  projectile.physicsBody.contactTestBitMask = monsterCategory;
  projectile.physicsBody.collisionBitMask = 0;
  projectile.physicsBody.usesPreciseCollisionDetection = YES;
}

- (void)projectile:(SKSpriteNode *)projectile didCollideWithMonster:(SKSpriteNode *)monster {
  NSLog(@"Hit");
  [projectile removeFromParent];
  [monster removeFromParent];
  
  self.monstersDestroyed++;
  if (self.monstersDestroyed > 30) {
    SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
    SKScene * gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:YES];
    [self.view presentScene:gameOverScene transition: reveal];
  }
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
  // 1
  SKPhysicsBody *firstBody, *secondBody;
  
  if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
  {
    firstBody = contact.bodyA;
    secondBody = contact.bodyB;
  }
  else
  {
    firstBody = contact.bodyB;
    secondBody = contact.bodyA;
  }
  
  // 2
  if ((firstBody.categoryBitMask & projectileCategory) != 0 &&
      (secondBody.categoryBitMask & monsterCategory) != 0)
  {
    [self projectile:(SKSpriteNode *) firstBody.node didCollideWithMonster:(SKSpriteNode *) secondBody.node];
  }
}

@end
