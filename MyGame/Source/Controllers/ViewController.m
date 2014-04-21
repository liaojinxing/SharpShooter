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
@property (nonatomic) AVAudioPlayer * backgroundMusicPlayer;
@end

@implementation ViewController

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
  
  NSError *error;
  NSURL * backgroundMusicURL = [[NSBundle mainBundle] URLForResource:kSoundBackground withExtension:@"caf"];
  self.backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:&error];
  self.backgroundMusicPlayer.numberOfLoops = -1;
  [self.backgroundMusicPlayer prepareToPlay];
  [self.backgroundMusicPlayer play];
  
  // Configure the view.
  SKView * skView = (SKView *)self.view;
  if (!skView.scene) {
    skView.showsFPS = NO;
    skView.showsNodeCount = NO;
    
    // Create and configure the scene.
    SKScene * scene = [MainScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
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
