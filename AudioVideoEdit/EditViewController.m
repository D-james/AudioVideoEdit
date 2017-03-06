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
    
//    添加播放层
    UIView *playView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 400)];
    [self.view addSubview:playView];
    
//    将资源路径添加到AVPlayerItem上
    AVPlayerItem *playItem = [[AVPlayerItem alloc]initWithURL:[self filePathName:@"abc.mp4"]];
    
//    AVPlayer播放需要添加AVPlayerItem
    self.player = [[AVPlayer alloc]initWithPlayerItem:playItem];
    self.player.volume = 0.5;//默认音量设置为0.5，取值范围0-1
    
//    播放视频需要在AVPlayerLayer上进行显示
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = playView.frame;//必须要设置playerLayer的frame
    [playView.layer addSublayer:playerLayer];//将AVPlayerLayer添加到播放层的layer上
    
//    添加一个循环播放的通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(repeatPlay) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    
//    背景音乐剪辑播放
//    计算视频的长度，从而进行相应的音频剪辑
    AVAsset *asset = [AVAsset assetWithURL:[self filePathName:@"abc.mp4"]];
    CMTime duration = asset.duration;
    CGFloat videoDuration = duration.value / (float)duration.timescale;
    NSLog(@"%f",videoDuration);
    
//    音频剪辑
    typeof(self) weakSelf = self;
    [EditAudioVideo cutAudioVideoResourcePath:[self filePathName:@"123.mp3"] startTime:0 endTime:videoDuration complition:^(NSURL *outputPath, BOOL isSucceed) {
        
//        音频剪辑成功后，拿到剪辑后的音频路径
        NSError *error;
        weakSelf.BGMPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:outputPath error:&error];
        
        if (error == nil) {
            weakSelf.BGMPlayer.numberOfLoops = -1;//循环播放
            weakSelf.BGMPlayer.volume = 0.5;
            
            [weakSelf.BGMPlayer prepareToPlay];//预先加载音频到内存，播放更流畅
            
//            播放音频，同时调用视频播放，实现同步播放
            [weakSelf.BGMPlayer play];
            [weakSelf.player play];
        }else{
            NSLog(@"%@",error);
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
