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
///   - directory: 文件夹名称-内部自动拼接全路径-放在document下
+ (nullable NSString *)filePathWithUrl:(NSString *)url
                             directory:(NSString*)directory;


/// 删除文件
/// - Parameters:
///   - path: 文件全路径
+ (BOOL)deleteFileWithPath:(NSString*)path;



/// 是否存在文件
/// - Parameters:
///   - fullPath: 文件路径
+ (BOOL)isExistFileWithPath:(NSString *)fullPath;
#pragma mark -
#pragma mark - 下载信息


/// 保存下载信息
/// - Parameters:
///   - url: url
///   - - path: 文件全路径
+(void)saveDownLoad:(NSString*)url
               path:(NSString*)path;


/// 获取下载列表
+(nullable NSMutableDictionary*)downLoadList;


/// 删除下载目录条目
/// - Parameter url: url
+(void)deleteDownLoadSession:(NSString *)url;

#pragma mark -
#pragma mark - 加密

/// sha256加密
/// - Parameter string: string
+ (NSString *)SHA256Encode:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
