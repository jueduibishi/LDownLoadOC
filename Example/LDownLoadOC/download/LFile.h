//
//  LFile.h
//  LDownLoadOC
//
//  Created by l on 2025/4/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 文件路径管理
@interface LFile : NSObject

/// 根据url获取文件路径
/// - Parameters:
///   - url: 下载url
+ (NSString *)filePathWithUrl:(NSString *)url;


/// 删除文件
/// - Parameters:
///   - url: 下载url
+ (BOOL)deleteFileWithUrl:(NSString *)url;



/// 是否存在文件
/// - Parameters:
///   - url: 下载url
+ (BOOL)isExistFileWithUrl:(NSString *)url;
#pragma mark -
#pragma mark - 下载目录统一管理


/// 设置下载的目录
/// - Parameters:
///   - dir: 名称，nil则为LdownLoad
///   - url: url
+(void)setDirectory:(nullable NSString*)dir
          url:(NSString *)url;

/// 删除下载目录条目
/// - Parameter url: url
+(void)deleteDirectory:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
