//
//  ResumedataFile.m
//  LDownLoadOC
//
//  Created by l on 2025/4/3.
//

#import "ResumedataFile.h"
#import <CommonCrypto/CommonCrypto.h>
#import <UIKit/UIKit.h>
#import <sys/xattr.h>

#define resumePathName @"LResumedata"
@implementation ResumedataFile

/// 主目录
+ (NSString *)mainCategory {
    NSString *doc = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [doc stringByAppendingPathComponent:resumePathName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
#if DEBUG
    NSLog(@"Resumedata文件路径:%@",path);
#endif
    return path;
}

/// 文件路径
/// - Parameter url: url
+(NSString*)pathWithUrl:(NSString*)url{
    //url sha256加密
    NSString *shaStr = [self fileName:url];
    NSString *mainPath = [self mainCategory];
    NSString *fullPath = [mainPath stringByAppendingPathComponent:shaStr];
    return fullPath;
}
/// 获取加密后的文件名
/// - Parameter url: url
+(NSString*)fileName:(NSString *)url{
    return [self SHA256Encode:url];
}


/// 删除resumeData
/// - Parameter url: url
+ (BOOL)deleteResumeDataWithUrl:(NSString *)url{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [self pathWithUrl:url];
    if ([fileManager fileExistsAtPath:path]) {
        return [fileManager removeItemAtPath:path error:nil];
    }
    return NO;
}

/// 保存url的resumeData
/// - Parameters:
///   - resumeData: data
///   - url: url
+ (void)saveResumeData:(NSData *)resumeData withUrl:(NSString *)url{
    [resumeData writeToFile:[self pathWithUrl:url] atomically:YES];
}

#pragma mark -
#pragma mark -加密
+ (NSString *)SHA256Encode:(NSString *)string;
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return string; // 编码失败
    }
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, hash);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", hash[i]];
    }
    return [output copy];
}

@end
