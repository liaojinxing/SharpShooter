//
//  ViewController.m
//  MyGame
//
//  Created by liaojinxing on 14-4-8.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import "ViewController.h"
#import "MainScene.h"
#import "AppConstants.h"
@import AVFoundation;


@interface ViewController ()
@property (nonatomic) AVAudioPlayer *backgroundMusicPlayer;
@property (nonatomic, strong) UIButton *pauseButton;
@end

@implementation ViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.pauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.pauseButton setTitle:@"暂停" forState:UIControlStateNormal];
  [self.pauseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [self.pauseButton setFrame:CGRectMake(self.view.frame.size.height - 80, 10, 100, 30)];
  [self.pauseButton addTarget:self action:@selector(pauseGame) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.pauseButton];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(showPauseButton)
                                               name:kNotificationGameStart
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(hidePauseButton)
                                               name:kNotificationGameOver
                                             object:nil];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];

  NSError *error;
  NSURL *backgroundMusicURL = [[NSBundle mainBundle] URLForResource:kSoundBackground withExtension:@"caf"];
  self.backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:&error];
  self.backgroundMusicPlayer.numberOfLoops = -1;
  [self.backgroundMusicPlayer prepareToPlay];
  //[self.backgroundMusicPlayer play];

  SKView *skView = (SKView *)self.view;
  if (!skView.scene) {
    skView.showsFPS = NO;
    skView.showsNodeCount = NO;
    SKScene *scene = [MainScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    [skView presentScene:scene];
  }
}

- (void)showPauseButton
{
  self.pauseButton.hidden = NO;
}

- (void)hidePauseButton
{
  self.pauseButton.hidden = YES;
}

- (void)pauseGame
{
  SKView *skView = (SKView *)self.view;
  if (![skView.scene isKindOfClass:[MainScene class]]) {
    return;
  }
  if (skView.scene.isPaused) {
    skView.scene.paused = NO;
    [self.pauseButton setTitle:@"暂停" forState:UIControlStateNormal];
  } else {
    skView.scene.paused = YES;
    [self.pauseButton setTitle:@"继续" forState:UIControlStateNormal];
  }
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return UIInterfaceOrientationMaskAllButUpsideDown;
  } else {
    return UIInterfaceOrientationMaskAll;
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

@end
