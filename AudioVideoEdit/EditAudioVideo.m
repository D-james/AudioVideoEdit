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
    
    //    分离素材
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];//视频素材
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];//音频素材
    
    //    编辑视频环境
    AVMutableComposition *composition = [[AVMutableComposition alloc]init];
    
    //    视频素材加入视频轨道
    AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    
    //    音频素材加入音频轨道
    AVMutableCompositionTrack *audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    //    是否加入视频原声
    AVMutableCompositionTrack *originalAudioCompositionTrack = nil;
    if (needOriginalVoice) {
        AVAssetTrack *originalAudioAssetTrack = [[asset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];
        originalAudioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [originalAudioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:originalAudioAssetTrack atTime:kCMTimeZero error:nil];
    }
    
    //    导出素材
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    
//    音量控制
    CMTime duration = videoAssetTrack.timeRange.duration;
    CGFloat videoDuration = duration.value / (float)duration.timescale;
    exporter.audioMix = [self buildAudioMixWithVideoTrack:originalAudioCompositionTrack VideoVolume:videoVolume BGMTrack:audioCompositionTrack BGMVolume:BGMVolume controlVolumeRange:CMTimeMake(0, videoDuration)];
    
    NSURL *outputPath = [self exporterPath];
    exporter.outputURL = [self exporterPath];
    exporter.outputFileType = AVFileTypeMPEG4;
    
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
+ (AVAudioMix *)buildAudioMixWithVideoTrack:(AVCompositionTrack *)videoTrack VideoVolume:(float)videoVolume BGMTrack:(AVCompositionTrack *)BGMTrack BGMVolume:(float)BGMVolume controlVolumeRange:(CMTime)volumeRange {
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    
    AVMutableAudioMixInputParameters *Videoparameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:videoTrack];
    [Videoparameters setVolume:videoVolume atTime:volumeRange];
    
    AVMutableAudioMixInputParameters *BGMparameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:BGMTrack];
    [Videoparameters setVolume:BGMVolume atTime:volumeRange];
    
    audioMix.inputParameters = @[Videoparameters,BGMparameters];
    
    return audioMix;
}

#pragma mark - 音视频剪辑,如果是视频把下面的类型换为AVFileTypeAppleM4V
+ (void)cutAudioVideoResourcePath:(NSURL *)assetURL startTime:(CGFloat)startTime endTime:(CGFloat)endTime complition:(void (^)(NSURL *outputPath,BOOL isSucceed)) completionHandle{
    //    素材
    AVAsset *asset = [AVAsset assetWithURL:assetURL];

    //    导出素材
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]initWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    
    //剪辑
    CMTime start = CMTimeMakeWithSeconds(startTime, asset.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(endTime - startTime,asset.duration.timescale);
    exporter.timeRange = CMTimeRangeMake(start, duration);
    
    NSURL *outputPath = [self exporterPath];
    exporter.outputURL = [self exporterPath];
    exporter.outputFileType = AVFileTypeAppleM4A;
    exporter.shouldOptimizeForNetworkUse= YES;
    
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
