//
//  EditViewController.m
//  AudioVideoEdit
//
//  Created by cuctv-duan on 17/2/13.
//  Copyright © 2017年 duan. All rights reserved.
//

#import "EditViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "EditAudioVideo.h"
#import "FinshViewController.h"

@interface EditViewController ()

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVAudioPlayer *BGMPlayer;
@property (strong, nonatomic) IBOutlet UISlider *originalVoiceSlide;
@property (strong, nonatomic) IBOutlet UISlider *BGMVoiceSlider;

@end

@implementation EditViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIView *playView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 400)];
    [self.view addSubview:playView];
    
    AVPlayerItem *playItem = [[AVPlayerItem alloc]initWithURL:[self filePathName:@"abc.mp4"]];
    
    self.player = [[AVPlayer alloc]initWithPlayerItem:playItem];
    self.player.volume = 0.5;
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = playView.frame;
    [playView.layer addSublayer:playerLayer];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(repeatPlay) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
//    背景音乐剪辑播放
    AVAsset *asset = [AVAsset assetWithURL:[self filePathName:@"abc.mp4"]];
    CMTime duration = asset.duration;
    CGFloat videoDuration = duration.value / (float)duration.timescale;
    NSLog(@"%f",videoDuration);
    
    typeof(self) weakSelf = self;
    [EditAudioVideo cutAudioVideoResourcePath:[self filePathName:@"123.mp3"] startTime:0 endTime:videoDuration complition:^(NSURL *outputPath, BOOL isSucceed) {
        
        NSError *error;
        weakSelf.BGMPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:outputPath error:&error];
        
        if (error == nil) {
            weakSelf.BGMPlayer.numberOfLoops = -1;
            weakSelf.BGMPlayer.volume = 0.5;
            [weakSelf.BGMPlayer prepareToPlay];
            [weakSelf.BGMPlayer play];
            [weakSelf.player play];
        }else{
            NSLog(@" %@",error);
        }
        
    }];
    
//    音量调节
    [self.originalVoiceSlide addTarget:self action:@selector(originalVoiceSlideChange:) forControlEvents:UIControlEventValueChanged];
    [self.BGMVoiceSlider addTarget:self action:@selector(BGMVoiceSliderChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)originalVoiceSlideChange:(UISlider *)slider {
    self.player.volume = slider.value;
}

- (void)BGMVoiceSliderChange:(UISlider *)slider {
    self.BGMPlayer.volume = slider.value;
}

//视频播放
- (void)repeatPlay {
    [self.player seekToTime:CMTimeMake(0, 1)];
    [self.player play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.player pause];
    [super viewWillDisappear:animated];
}

- (IBAction)synthesizeClick:(id)sender {
    
    [EditAudioVideo editVideoSynthesizeVieoPath:[self filePathName:@"abc.mp4"] BGMPath:[self filePathName:@"123.mp3"] needOriginalVoice:YES videoVolume:self.originalVoiceSlide.value BGMVolume:self.BGMVoiceSlider.value complition:^(NSURL *outputPath, BOOL isSucceed) {
        
        FinshViewController *finshVC = [FinshViewController new];
        finshVC.playURL = outputPath;
        [self presentViewController:finshVC animated:YES completion:nil];
        
    }];
    
//    [EditAudioVideo cutAudioVideoResourcePath:[self filePathName:@"abc.mp4"] startTime:3 endTime:8 complition:^(NSURL *outputPath, BOOL isSucceed) {
//        
//        FinshViewController *finshVC = [FinshViewController new];
//        finshVC.playURL = outputPath;
//        [self presentViewController:finshVC animated:YES completion:nil];
//        
//    }];
}

- (NSURL *)filePathName:(NSString *)fileName{
    return [NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:fileName ofType:nil]];
}
@end
