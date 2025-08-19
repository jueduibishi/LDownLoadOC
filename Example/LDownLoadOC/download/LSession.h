//
//  LSession.h
//  Shiny
//
//  Created by l on 2025/4/2.
//  Copyright © 2025 YYF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LFile.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ProgressHandler)(int64_t receiveByte, int64_t allByte,CGFloat progress);
typedef void (^SpeedHandler)(NSString *speed);
typedef void (^SucHandler)();
typedef void (^FailHandler)();

/// 下载Session
@interface LSession : NSObject

@property (nonatomic, copy) ProgressHandler progressBlock;
@property (nonatomic, copy) SpeedHandler speedBlock;
@property (nonatomic, copy) SucHandler successBlock;
@property (nonatomic, copy) FailHandler failBlock;

@property (nonatomic, copy) NSString* identifier;//用来处理application handleEventsForBackgroundURLSession
@property (nonatomic, copy,nullable) dispatch_block_t backgroundCompletionBlock;//用来处理application handleEventsForBackgroundURLSession


/// 初始化，默认30秒超时
/// - Parameters:
///   - downLoadUrl: 下载地址
///   - finalPath: 文件目录
- (instancetype)initWithUrl:(NSString*)downLoadUrl
                     toPath:(NSString*)finalPath;
/// 初始化
/// - Parameters:
///   - downLoadUrl: 下载地址
///   - finalPath: 文件目录
///   - timeout: 超时
- (instancetype)initWithUrl:(NSString*)downLoadUrl
                     toPath:(NSString*)finalPath
                    timeout:(NSTimeInterval)timeout;

/// 开始下载
- (void)startTask;


/// 暂停下载
- (void)pauseTask;

/// 删除下载任务
- (void)deleteTask;

@end

NS_ASSUME_NONNULL_END
