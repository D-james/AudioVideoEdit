//
//  EditAudioVideo.m
//  AudioVideoEdit
//
//  Created by cuctv-duan on 17/2/13.
//  Copyright © 2017年 duan. All rights reserved.
//

#import "EditAudioVideo.h"
#import <AVFoundation/AVFoundation.h>

@implementation EditAudioVideo
+ (void)editVideoSynthesizeVieoPath:(NSURL *)assetURL BGMPath:(NSURL *)BGMPath  needOriginalVoice:(BOOL)needOriginalVoice videoVolume:(CGFloat)videoVolume BGMVolume:(CGFloat)BGMVolume complition:(void (^)(NSURL *outputPath,BOOL isSucceed)) completionHandle{
    //    素材
    AVAsset *asset = [AVAsset assetWithURL:assetURL];
    AVAsset *audioAsset = [AVAsset assetWithURL:BGMPath];

    CMTime duration = asset.duration;
    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero, duration);

    //    分离素材
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];//视频素材
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];// 背景音乐音频素材
    
    //    创建编辑环境
    AVMutableComposition *composition = [[AVMutableComposition alloc]init];
    
    //    视频素材加入视频轨道
    AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoCompositionTrack insertTimeRange:video_timeRange ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    
    //    音频素材加入音频轨道
    AVMutableCompositionTrack *audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioCompositionTrack insertTimeRange:video_timeRange ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
//    audioCompositionTrack.preferredVolume = 0;
    
    //    是否加入视频原声
    AVMutableCompositionTrack *originalAudioCompositionTrack = nil;
    if (needOriginalVoice) {
        AVAssetTrack *originalAudioAssetTrack = [[asset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];
        originalAudioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [originalAudioCompositionTrack insertTimeRange:video_timeRange ofTrack:originalAudioAssetTrack atTime:kCMTimeZero error:nil];
    }
    
    //    创建导出素材类
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];

    
//    设置输出路径
    NSURL *outputPath = [self exporterPath];
    exporter.outputURL = outputPath;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;//指定输出格式
    exporter.shouldOptimizeForNetworkUse= YES;
    
    //    音量控制
    exporter.audioMix = [self buildAudioMixWithVideoTrack:originalAudioCompositionTrack VideoVolume:videoVolume BGMTrack:audioCompositionTrack BGMVolume:BGMVolume atTime:kCMTimeZero];
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        switch ([exporter status]) {
            case AVAssetExportSessionStatusFailed: {
                NSLog(@"合成失败：%@",[[exporter error] description]);
                completionHandle(outputPath,NO);
            } break;
            case AVAssetExportSessionStatusCancelled: {
                completionHandle(outputPath,NO);
            } break;
            case AVAssetExportSessionStatusCompleted: {
                completionHandle(outputPath,YES);
            } break;
            default: {
                completionHandle(outputPath,NO);
            } break;
        }
    }];
}

#pragma mark - 调节合成的音量
+ (AVAudioMix *)buildAudioMixWithVideoTrack:(AVCompositionTrack *)videoTrack VideoVolume:(float)videoVolume BGMTrack:(AVCompositionTrack *)BGMTrack BGMVolume:(float)BGMVolume atTime:(CMTime)volumeRange {
    
//    创建音频混合类
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    
//    拿到视频声音轨道设置音量
    AVMutableAudioMixInputParameters *Videoparameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:videoTrack];
    [Videoparameters setVolume:videoVolume atTime:volumeRange];
    
//    设置背景音乐音量
    AVMutableAudioMixInputParameters *BGMparameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:BGMTrack];
    [BGMparameters setVolume:BGMVolume atTime:volumeRange];
    
//    加入混合数组
    audioMix.inputParameters = @[Videoparameters,BGMparameters];
    
    return audioMix;
}

#pragma mark - 音视频剪辑,如果是视频把下面的类型换为AVFileTypeAppleM4V
+ (void)cutAudioVideoResourcePath:(NSURL *)assetURL startTime:(CGFloat)startTime endTime:(CGFloat)endTime complition:(void (^)(NSURL *outputPath,BOOL isSucceed)) completionHandle{
    //    素材
    AVAsset *asset = [AVAsset assetWithURL:assetURL];

    //    导出素材
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]initWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    
    //剪辑(设置导出的时间段)
    CMTime start = CMTimeMakeWithSeconds(startTime, asset.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(endTime - startTime,asset.duration.timescale);
    exporter.timeRange = CMTimeRangeMake(start, duration);
    
//    输出路径
    NSURL *outputPath = [self exporterPath];
    exporter.outputURL = [self exporterPath];
    
//    输出格式
    exporter.outputFileType = AVFileTypeAppleM4A;
    
    exporter.shouldOptimizeForNetworkUse= YES;
    
//    合成后的回调
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        switch ([exporter status]) {
            case AVAssetExportSessionStatusFailed: {
                NSLog(@"合成失败：%@",[[exporter error] description]);
                completionHandle(outputPath,NO);
            } break;
            case AVAssetExportSessionStatusCancelled: {
                completionHandle(outputPath,NO);
            } break;
            case AVAssetExportSessionStatusCompleted: {
                completionHandle(outputPath,YES);
            } break;
            default: {
                completionHandle(outputPath,NO);
            } break;
        }
    }];
}


#pragma mark - 输出路径
+ (NSURL *)exporterPath {
    
    NSInteger nowInter = (long)[[NSDate date] timeIntervalSince1970];
    NSString *fileName = [NSString stringWithFormat:@"output%ld.mp4",(long)nowInter];
    
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
   
    NSString *outputFilePath =[documentsDirectory stringByAppendingPathComponent:fileName];
    
    if([[NSFileManager defaultManager]fileExistsAtPath:outputFilePath]){
        
        [[NSFileManager defaultManager]removeItemAtPath:outputFilePath error:nil];
    }
    
    return [NSURL fileURLWithPath:outputFilePath];
}
@end
