//
//  MyScene.m
//  MyGame
//
//  Created by liaojinxing on 14-4-8.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import "MainScene.h"
#import "GameOverScene.h"
#import "AppConstants.h"

static inline CGPoint rwAdd(CGPoint a, CGPoint b)
{
  return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint rwSub(CGPoint a, CGPoint b)
{
  return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint rwMult(CGPoint a, float b)
{
  return CGPointMake(a.x * b, a.y * b);
}

static inline float rwLength(CGPoint a)
{
  return sqrtf(a.x * a.x + a.y * a.y);
}

// 让向量的长度（模）等于1
static inline CGPoint rwNormalize(CGPoint a)
{
  float length = rwLength(a);
  return CGPointMake(a.x / length, a.y / length);
}

static const uint32_t projectileCategory     =  0x1 << 0;
static const uint32_t monsterCategory        =  0x1 << 1;
static const uint32_t superMonsterCategory   =  0x1 << 2;

static const NSInteger kKillMonstersForWin = 100;
static const NSInteger kWillAppearSuperMonster = 10;

@interface MainScene () <SKPhysicsContactDelegate>

@property (nonatomic) SKSpriteNode *player;
@property (nonatomic) NSTimeInterval lastSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) int monstersDestroyed;

@end

@implementation MainScene
- (id)initWithSize:(CGSize)size
{
  if (self = [super initWithSize:size]) {
    SKSpriteNode *backgroundNode = [SKSpriteNode spriteNodeWithImageNamed:kImageBackground];
    backgroundNode.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    [self addChild:backgroundNode];

    self.player = [SKSpriteNode spriteNodeWithImageNamed:kImagePlayer];
    self.player.position = CGPointMake(self.player.size.width / 2, self.frame.size.height / 2);
    [self addChild:self.player];

    self.physicsWorld.gravity = CGVectorMake(0, 0);
    self.physicsWorld.contactDelegate = self;
  }
  return self;
}

- (void)addMonsterWithPower:(NSInteger)power
{
  SKSpriteNode *monster = [SKSpriteNode spriteNodeWithImageNamed:kImageMonster];
  [monster setSize:CGSizeMake(monster.size.width * power, monster.size.height * power)];
  int minY = monster.size.height / 2;
  int maxY = self.frame.size.height - monster.size.height / 2;
  int rangeY = maxY - minY;
  int actualY = (arc4random() % rangeY) + minY;
  
  monster.position = CGPointMake(self.frame.size.width + monster.size.width / 2, actualY);
  [self addChild:monster];
  
  int minDuration = 3.0;
  int maxDuration = 5.0;
  int rangeDuration = maxDuration - minDuration;
  int actualDuration = (arc4random() % rangeDuration) + minDuration;
  
  SKAction *actionMove = [SKAction moveTo:CGPointMake(-monster.size.width / 2, actualY) duration:actualDuration];
  SKAction *actionMoveDone = [SKAction removeFromParent];
  
  SKAction *loseAction = [SKAction runBlock:^{
    SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
    SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:NO];
    [self.view presentScene:gameOverScene transition:reveal];
  }];
  [monster runAction:[SKAction sequence:@[actionMove, loseAction, actionMoveDone]]];
  
  monster.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:monster.size];
  monster.physicsBody.dynamic = YES;
  monster.physicsBody.categoryBitMask = 0x1 << power;
  monster.physicsBody.contactTestBitMask = projectileCategory;
  monster.physicsBody.collisionBitMask = 0;
  
  NSMutableDictionary *userData = [NSMutableDictionary dictionary];
  [userData setObject:@(0) forKey:kHittedTime];
  [userData setObject:@(power) forKey:kHitTimesToKill];
  monster.userData = userData;
}

- (void)addMonster
{
  [self addMonsterWithPower:1];
}

- (void)addSuperMonster
{
  [self addMonsterWithPower:2];
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast
{
  self.lastSpawnTimeInterval += timeSinceLast;
  if (self.lastSpawnTimeInterval > 1) {
    self.lastSpawnTimeInterval = 0;
    [self addMonster];
  }
}

- (void)update:(NSTimeInterval)currentTime
{
  CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
  self.lastUpdateTimeInterval = currentTime;
  if (timeSinceLast > 1) {
    timeSinceLast = 1.0 / 60.0;
    self.lastUpdateTimeInterval = currentTime;
  }

  [self updateWithTimeSinceLastUpdate:timeSinceLast];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  [self runAction:[SKAction playSoundFileNamed:kSoundExplosion waitForCompletion:NO]];

  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInNode:self];

  SKSpriteNode *projectile = [SKSpriteNode spriteNodeWithImageNamed:kImageProjectile];
  projectile.position = self.player.position;
  CGPoint offset = rwSub(location, projectile.position);
  if (offset.x <= 0) return;

  [self addChild:projectile];
  CGPoint direction = rwNormalize(offset);
  CGPoint shootAmount = rwMult(direction, 1000);
  CGPoint realDest = rwAdd(shootAmount, projectile.position);

  float velocity = 1400.0 / 1.0;
  float realMoveDuration = self.size.width / velocity;
  SKAction *actionMove = [SKAction moveTo:realDest duration:realMoveDuration];
  SKAction *actionMoveDone = [SKAction removeFromParent];
  [projectile runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];

  projectile.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:projectile.size.width / 2];
  projectile.physicsBody.dynamic = YES;
  projectile.physicsBody.categoryBitMask = projectileCategory;
  projectile.physicsBody.contactTestBitMask = monsterCategory | superMonsterCategory;
  projectile.physicsBody.collisionBitMask = 0;
  projectile.physicsBody.usesPreciseCollisionDetection = YES;
}

- (void)projectile:(SKSpriteNode *)projectile didCollideWithMonster:(SKSpriteNode *)monster atPoint:(CGPoint)contactPoint
{
  [self explosionAtCollidePoint:contactPoint];

  [projectile removeFromParent];
  [monster removeFromParent];

  self.monstersDestroyed++;
  if (self.monstersDestroyed % kWillAppearSuperMonster == 0) {
    [self addSuperMonster];
  }
  if (self.monstersDestroyed > kKillMonstersForWin) {
    SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
    SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:YES];
    [self.view presentScene:gameOverScene transition:reveal];
  }
}

- (void)explosionAtCollidePoint:(CGPoint)point
{
  SKSpriteNode *explosion = [SKSpriteNode spriteNodeWithImageNamed:kImageExplosion];
  explosion.position = point;

  [self addChild:explosion];

  SKAction *actionBoom = [SKAction scaleBy:2.0 duration:0.2];
  SKAction *actionMoveDone = [SKAction removeFromParent];
  [explosion runAction:[SKAction sequence:@[actionBoom, actionMoveDone]]];
  explosion.physicsBody.dynamic = NO;
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
  SKPhysicsBody *firstBody, *secondBody;

  if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
    firstBody = contact.bodyA;
    secondBody = contact.bodyB;
  } else {
    firstBody = contact.bodyB;
    secondBody = contact.bodyA;
  }
  
  if (secondBody.categoryBitMask & superMonsterCategory) {
    NSMutableDictionary *userData = secondBody.node.userData;
    NSNumber *hitTime = [userData objectForKey:kHittedTime];
    if (hitTime.integerValue == 0) {
      [secondBody.node.userData setObject:@(1) forKey:kHittedTime];
      [self explosionAtCollidePoint:contact.contactPoint];
    } else {
      if ((firstBody.categoryBitMask & projectileCategory) != 0) {
        [self projectile:(SKSpriteNode *)firstBody.node
   didCollideWithMonster:(SKSpriteNode *)secondBody.node
                 atPoint:contact.contactPoint];
      }
    }
  }

  if ((firstBody.categoryBitMask & projectileCategory) != 0 &&
      ((secondBody.categoryBitMask & monsterCategory) != 0)) {
    [self projectile:(SKSpriteNode *)firstBody.node
      didCollideWithMonster:(SKSpriteNode *)secondBody.node
                    atPoint:contact.contactPoint];
  }
}

@end
