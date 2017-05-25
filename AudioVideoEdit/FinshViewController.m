//
//  FinshViewController.m
//  AudioVideoEdit
//
//  Created by cuctv-duan on 17/2/13.
//  Copyright © 2017年 duan. All rights reserved.
//

#import "FinshViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface FinshViewController ()

@property (strong, nonatomic) AVPlayer *player;

@end

@implementation FinshViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIView *playView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 400)];
    [self.view addSubview:playView];
//    playView.backgroundColor = [UIColor redColor];

    AVPlayerItem *playItem = [[AVPlayerItem alloc]initWithURL:self.playURL];
    
    self.player = [[AVPlayer alloc]initWithPlayerItem:playItem];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = playView.frame;
    [playView.layer addSublayer:playerLayer];
    
    [self.player play];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(repeatPlay) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
}

- (void)repeatPlay {
    [self.player seekToTime:CMTimeMake(0, 1)];
    [self.player play];
}

@end
