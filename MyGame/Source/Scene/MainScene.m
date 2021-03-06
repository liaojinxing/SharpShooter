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
static const uint32_t bigMonsterCategory     =  0x1 << 2;
static const uint32_t superMonsterCategory   =  0x1 << 3;

static const NSInteger kKillMonstersForWin        = 1000;
static const NSInteger kWillAppearBigMonster      = 10;
static const NSInteger kWillAppearSuperMonster    = 27;
static const NSInteger kWillAppearSuperProjectile = 39;

static const NSInteger kDestroyedMonsterToLevel1    = 10;
static const NSInteger kDestroyedMonsterToLevel2    = 30;
static const NSInteger kDestroyedMonsterToLevel3    = 100;

static const NSInteger kProjectileTotal = 50;

@interface MainScene () <SKPhysicsContactDelegate>

@property (nonatomic, strong) SKSpriteNode *player;
@property (nonatomic, strong) SKLabelNode *projectileLabel;
@property (nonatomic, assign) NSTimeInterval lastSpawnTimeInterval;
@property (nonatomic, assign) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic, assign) int monstersDestroyed;
@property (nonatomic, assign) int projectileUsed;
@property (nonatomic, assign) int projectileTotal;
@property (nonatomic, assign) int level;

@end

@implementation MainScene
- (id)initWithSize:(CGSize)size
{
  if (self = [super initWithSize:size]) {
    self.backgroundColor = [SKColor colorWithRed:0.2 green:0.4 blue:0.2 alpha:1.0];

    self.level = 0;
    self.projectileUsed = 0;
    self.projectileTotal = kProjectileTotal;
    
    self.player = [SKSpriteNode spriteNodeWithImageNamed:kImagePlayer];
    self.player.position = CGPointMake(self.player.size.width / 2, self.frame.size.height / 2);
    [self addChild:self.player];
    
    [self addProgressBar];
    self.physicsWorld.gravity = CGVectorMake(0, 0);
    self.physicsWorld.contactDelegate = self;
  }
  return self;
}

- (void)addProgressBar
{
  self.projectileLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
  self.projectileLabel.fontSize = 16;
  self.projectileLabel.fontColor = [SKColor whiteColor];
  self.projectileLabel.position = CGPointMake(130, self.frame.size.height - 20);
  [self addChild:self.projectileLabel];
  [self updateProgressBar];
}

- (void)updateProgressBar
{
  NSString *text = [NSString stringWithFormat:@"击落%d怪兽,子弹:%d/%d",
                    self.monstersDestroyed,self.projectileUsed, self.projectileTotal];
  self.projectileLabel.text = text;
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

  int minDuration = 3;
  int maxDuration = 5;

  if (self.level >= 2) {
    minDuration = 2;
  }
  if (self.level > 0) {
    maxDuration = 4;
  }
  if (self.level >= 3) {
    maxDuration = 3;
  }

  int rangeDuration = maxDuration - minDuration;
  int actualDuration = (arc4random() % rangeDuration) + minDuration;

  SKAction *actionMove = [SKAction moveTo:CGPointMake(-monster.size.width / 2, actualY) duration:actualDuration];
  SKAction *actionMoveDone = [SKAction removeFromParent];

  SKAction *loseAction = [SKAction runBlock:^{
                            [self gameOverWithReason:kLoseMonster];
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

- (void)addBigMonster
{
  [self addMonsterWithPower:2];
}

- (void)addSuperMonster
{
  [self addMonsterWithPower:3];
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast
{
  self.lastSpawnTimeInterval += timeSinceLast;
  
  CGFloat interval = 0.8;
  if (self.level == 2) {
    interval = 0.7;
  } else if (self.level == 3) {
    interval = 0.6;
  }
  
  if (self.lastSpawnTimeInterval > interval) {
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

- (void)addProjectileWithDirection:(CGPoint)direction
{
  SKSpriteNode *projectile = [SKSpriteNode spriteNodeWithImageNamed:kImageProjectile];
  projectile.position = self.player.position;

  [self addChild:projectile];
  CGPoint shootAmount = rwMult(direction, 1000);
  CGPoint realDest = rwAdd(shootAmount, projectile.position);

  float velocity = 500 / 1.0;
  float realMoveDuration = self.size.width / velocity;
  SKAction *actionMove = [SKAction moveTo:realDest duration:realMoveDuration];
  SKAction *actionMoveDone = [SKAction removeFromParent];
  [projectile runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];

  projectile.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:projectile.size.width / 2];
  projectile.physicsBody.dynamic = YES;
  projectile.physicsBody.categoryBitMask = projectileCategory;
  projectile.physicsBody.contactTestBitMask = monsterCategory | bigMonsterCategory | superMonsterCategory;
  projectile.physicsBody.collisionBitMask = 0;
  projectile.physicsBody.usesPreciseCollisionDetection = YES;
}

- (void)addSuperProjectile
{
  CGFloat x = 120, y = 0;
  while (y < self.frame.size.height) {
    CGPoint location = CGPointMake(x, y);
    CGPoint offset = rwSub(location, self.player.position);
    if (offset.x <= 0) {
      return;
    }
    CGPoint direction = rwNormalize(offset);
    [self addProjectileWithDirection:direction];
    y += 10;
  }
}

- (void)projectile:(SKSpriteNode *)projectile didCollideWithMonster:(SKSpriteNode *)monster atPoint:(CGPoint)contactPoint
{
  [self explosionAtCollidePoint:contactPoint];
  [self runAction:[SKAction playSoundFileNamed:kSoundExplosion waitForCompletion:NO]];
  [projectile removeFromParent];
  [monster removeFromParent];

  self.monstersDestroyed++;
  [self addBigEffect];
  [self setLevelByMonstersDestroyed];
  [self updateProgressBar];
  if (self.monstersDestroyed >= kKillMonstersForWin) {
    [self gameOverWithReason:kKillAllMonsters];
  }
}

- (void)gameOverWithReason:(GameOverReason)reason
{
  SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
  SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size hitNums:self.monstersDestroyed reason:reason];
  [self.view presentScene:gameOverScene transition:reveal];
  [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationGameOver object:nil];
}

- (void)addBigEffect
{
  if (self.monstersDestroyed % kWillAppearBigMonster == 0) {
    [self addBigMonster];
  }
  if (self.monstersDestroyed % kWillAppearSuperMonster == 0) {
    [self addSuperMonster];
  }
  if (self.monstersDestroyed % kWillAppearSuperProjectile == 0) {
    [self addSuperProjectile];
  }
  if (self.monstersDestroyed % 40 == 0) {
    if (self.monstersDestroyed * 1.0 / self.projectileUsed <= 1.05) {
      [self addProjectileNum:kProjectileTotal];
    }
  }
}

- (void)addProjectileNum:(int)num
{
  self.projectileTotal += num;
  [self updateProgressBar];
  [self runAction:[SKAction playSoundFileNamed:kSoundExplosion waitForCompletion:NO]];
}

- (void)setLevelByMonstersDestroyed
{
  if (self.monstersDestroyed >= kDestroyedMonsterToLevel3) {
    self.level = 3;
    [self addProjectileNum:kProjectileTotal * 2];
  } else if (self.monstersDestroyed >= kDestroyedMonsterToLevel2) {
    self.level = 2;
  } else if (self.monstersDestroyed >= kDestroyedMonsterToLevel1) {
    self.level = 1;
  } else {
    self.level = 0;
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

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInNode:self];
  CGPoint offset = rwSub(location, self.player.position);
  if (offset.x <= 0) {
    return;
  }
  
  self.projectileUsed++;
  [self updateProgressBar];
  if (self.projectileUsed >= self.projectileTotal) {
    [self gameOverWithReason:kProjectileUseUp];
    return;
  }
  
  CGPoint direction = rwNormalize(offset);
  [self addProjectileWithDirection:direction];
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

  if (secondBody.categoryBitMask & bigMonsterCategory || secondBody.categoryBitMask & superMonsterCategory) {
    NSMutableDictionary *userData = secondBody.node.userData;
    NSNumber *hitToKill = [userData objectForKey:kHitTimesToKill];
    NSNumber *hitTime = [userData objectForKey:kHittedTime];
    if (hitTime.integerValue < hitToKill.integerValue - 1) {
      [secondBody.node.userData setObject:[NSNumber numberWithInteger:hitTime.integerValue + 1] forKey:kHittedTime];
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
