//
//  LAppDelegate.m
//  LDownLoadOC
//
//  Created by jueduibishi on 04/15/2025.
//  Copyright (c) 2025 jueduibishi. All rights reserved.
//

#import "LAppDelegate.h"
#import "LTaskManager.h"
#import "UNUserNotificationHelper.h"
@implementation LAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    LTaskManager *manager = [LTaskManager instance];
    //预设置，防止系统自动下载
    [manager preConfig];
    [UNUserNotificationHelper registerUserNotification];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler{
    LTaskManager *manager = [LTaskManager instance];
    NSArray *sessions = manager.sessionDic.allValues;
    for (LSession *session in sessions) {
        if ([session.identifier isEqualToString:identifier]) {
            session.backgroundCompletionBlock = completionHandler;
        }
    }
}

@end
