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
#import "LFile.h"

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
    NSString *shaStr = [LFile SHA256Encode:url];
    NSString *mainPath = [self mainCategory];
    NSString *fullPath = [mainPath stringByAppendingPathComponent:shaStr];
    return fullPath;
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

+(nullable NSData*)resumeData:(NSString*)url{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [self pathWithUrl:url];
    if ([fileManager fileExistsAtPath:path]){
        return [[NSData alloc]initWithContentsOfURL:[NSURL fileURLWithPath:path]];
    }
    return nil;
}

@end
