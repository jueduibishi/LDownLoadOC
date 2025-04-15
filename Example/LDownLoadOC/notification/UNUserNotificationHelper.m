//
//  UNUserNotificationHelper.m
//  BackgroundDownloadDemo
//
//  Created by l on 2025/4/2.
//  Copyright © 2025 hkhust. All rights reserved.
//

#import "UNUserNotificationHelper.h"
@implementation UNUserNotificationHelper

+ (instancetype)instance{
    static UNUserNotificationHelper *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[UNUserNotificationHelper alloc] init];
    });
    return instance;
}
/// 注册本地通知
+(void)registerUserNotification{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert|UNAuthorizationOptionSound|UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        
    }];
    center.delegate = [UNUserNotificationHelper instance];
}

/// 发送本地通知
+(void)sendUserNotification{
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.title = @"下载完成";
    content.subtitle = @"副标题";
    content.body  = @"这是一条下载完成的通知";
    content.badge = @1;
    content.categoryIdentifier = @"download";
    
    UNNotificationAction *action = [UNNotificationAction actionWithIdentifier:@"enterApp"
                                                                        title:@"打开app"
                                                                      options:UNNotificationActionOptionForeground];
    UNNotificationAction *clearAction = [UNNotificationAction actionWithIdentifier:@"destructive"
                                                                             title:@"忽略"
                                                                           options:UNNotificationActionOptionDestructive];
    UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:@"categoryIdentifier"
                                                                              actions:@[action,clearAction]
                                                                    intentIdentifiers:@[@"download"]
                                                                              options:UNNotificationCategoryOptionNone];
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    [center setNotificationCategories:[NSSet setWithObject:category]];
    
    UNTimeIntervalNotificationTrigger *timeTrigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1 repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"download" content:content trigger:timeTrigger];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) { }];
}
#pragma mark -
#pragma mark - 通知
//iOS10新增：处理前台收到通知的代理方法
- (void)userNotificationCenter:(UNUserNotificationCenter*)center willPresentNotification:(UNNotification*)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    if (@available(iOS 17, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] setBadgeCount:0 withCompletionHandler:^(NSError * _Nullable error) {
                
        }];
    } else {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
    
    NSLog(@"前台收到本地通知");
}

//iOS10新增：处理后台点击通知的代理方法-从通知中心进才有效
- (void)userNotificationCenter:(UNUserNotificationCenter*)center didReceiveNotificationResponse:(UNNotificationResponse*)response withCompletionHandler:(void (^)(void))completionHandler{
    
    if (@available(iOS 17, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] setBadgeCount:0 withCompletionHandler:^(NSError * _Nullable error) {
                
        }];
    } else {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
    NSLog(@"后台收到本地通知");
    completionHandler();
}
@end
