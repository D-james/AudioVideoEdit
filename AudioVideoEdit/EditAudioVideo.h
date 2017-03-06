//
//  EditAudioVideo.h
//  AudioVideoEdit
//
//  Created by cuctv-duan on 17/2/13.
//  Copyright © 2017年 duan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditAudioVideo : NSObject

+ (void)cutAudioVideoResourcePath:(NSURL *)assetURL startTime:(CGFloat)startTime endTime:(CGFloat)endTime complition:(void (^)(NSURL *outputPath,BOOL isSucceed)) completionHandle;


+ (void)editVideoSynthesizeVieoPath:(NSURL *)assetURL BGMPath:(NSURL *)BGMPath  needOriginalVoice:(BOOL)needOriginalVoice videoVolume:(CGFloat)videoVolume BGMVolume:(CGFloat)BGMVolume complition:(void (^)(NSURL *outputPath,BOOL isSucceed)) completionHandle;


@end
