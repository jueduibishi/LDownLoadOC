//
//  UNUserNotificationHelper.h
//  BackgroundDownloadDemo
//
//  Created by l on 2025/4/2.
//  Copyright © 2025 hkhust. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

NS_ASSUME_NONNULL_BEGIN

@interface UNUserNotificationHelper : NSObject<UNUserNotificationCenterDelegate>
+(instancetype)instance;

/// 注册本地通知
+(void)registerUserNotification;

/// 发送本地通知
+(void)sendUserNotification;
@end

NS_ASSUME_NONNULL_END
