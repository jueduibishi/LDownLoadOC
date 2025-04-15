//
//  LSession.h
//  Shiny
//
//  Created by l on 2025/4/2.
//  Copyright © 2025 YYF. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ProgressHandler)(NSString *url,int64_t receiveByte, int64_t allByte,CGFloat progress);
typedef void (^SpeedHandler)(NSString *url,NSString *speed);
typedef void (^SucHandler)(NSString *url);
typedef void (^FailureHandler)(NSString *url);

/// 下载Session
@interface LSession : NSObject

+ (instancetype)instance;

@property (nonatomic, copy) ProgressHandler progressBlock;
@property (nonatomic, copy) SpeedHandler speedBlock;
@property (nonatomic, copy) SucHandler successBlock;
@property (nonatomic, copy) FailureHandler failureBlock;

@property (nonatomic, assign) CGFloat timeout;//超时，默认30秒
@property (nonatomic, copy) NSString* identifier;//用来处理application handleEventsForBackgroundURLSession
@property (nonatomic, copy,nullable) dispatch_block_t backgroundCompletionBlock;//用来处理application handleEventsForBackgroundURLSession




/// 开始下载
/// - Parameters:
///   - urlStr: url
///   - directory: 文件夹名称，若为nil，则默认LdownLoad文件夹
- (void)startDownload:(NSString *)url
            directory:(nullable NSString *)directory;

/// 移除下载
/// - Parameter url: url
- (void)deleteDownload:(NSString *)url;


/// 继续下载
/// - Parameter url: url
- (void)continueDownload:(NSString *)url;


/// 暂停下载
/// - Parameter url: url
- (void)pauseDownload:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
