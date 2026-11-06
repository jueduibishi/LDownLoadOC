//
//  LDownloadMeta.h
//  LDownLoadOC_Example
//
//  Created by l on 2026/11/6.
//  Copyright © 2026 jueduibishi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LDownloadStatus) {
    LDownloadStatusNone = 0,
    LDownloadStatusDownloading,
    LDownloadStatusPaused,
    LDownloadStatusFinished,
    LDownloadStatusFailed,
};

/// 下载元数据-用于保存下载进度，避免关闭app时丢失数据
@interface LDownloadMeta : NSObject<NSSecureCoding>
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *urlSHA256;
@property (nonatomic, assign) int64_t totalBytesWritten;
@property (nonatomic, assign) int64_t totalBytesExpected;
@property (nonatomic, assign) LDownloadStatus status;
@property (nonatomic, copy) NSString *tempFileName; // 备份的 tmp 文件名


/// 储存下载数据
/// - Parameter meta: meta
+ (void)saveDownloadMeta:(LDownloadMeta *)meta;

/// 读取下载数据
/// - Parameter url: url
+ (nullable LDownloadMeta *)readDownloadMeta:(NSString *)url;

/// 删除下载数据
/// - Parameter url: url
+ (void)deleteDownloadMeta:(NSString *)url;


/// 下载缓存
/// - Parameter url: url
+ (float)cachedProgress:(NSString *)url;
@end

NS_ASSUME_NONNULL_END
