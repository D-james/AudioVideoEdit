//
//  AppDelegate.h
//  AudioVideoEdit
//
//  Created by cuctv-duan on 17/2/13.
//  Copyright © 2017年 duan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

