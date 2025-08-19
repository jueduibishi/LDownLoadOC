//
//  LTaskManager.h
//  LDownLoadOC_Example
//
//  Created by l on 2025/8/18.
//  Copyright © 2025 jueduibishi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTaskManager : NSObject
+ (instancetype)instance;

@property (nonatomic, strong) NSMutableDictionary *sessionDic;

/// 预设置，app启动时运行
-(void)preConfig;

/// 开始下载
/// - Parameters:
///   - url: url
///   - path: path
///   - progressBlock: progress
///   - successBlock: suc
///   - failBlock: fail
-(void)startDown:(NSString*)url
          toPath:(NSString*)path
   progressBlock:(ProgressHandler)progressBlock
    successBlock:(SucHandler)successBlock
       failBlock:(FailHandler)failBlock;


/// 暂停下载
/// - Parameter url: url
-(void)pauseDown:(NSString*)url;



/// 移除下载
/// - Parameters:
///   - url: url
///   - path: 储存路径
-(void)deleteDown:(NSString*)url
             path:(NSString*)path;

//是否正在下载
- (BOOL)isDownloading;

@end

NS_ASSUME_NONNULL_END
