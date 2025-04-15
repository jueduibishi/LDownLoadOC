//
//  LFile.m
//  LDownLoadOC
//
//  Created by l on 2025/4/3.
//

#import "LFile.h"
#import <CommonCrypto/CommonCrypto.h>
#import <UIKit/UIKit.h>
#import <sys/xattr.h>

#define mainPathName @"LdownLoad" //默认下载目录
#define directoryPlist @"directoryPlist" //保存每个文件的下载位置
@implementation LFile


+ (NSString *)mainCategory:(nullable NSString *)dir{
    NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [doc stringByAppendingPathComponent:dir?dir:mainPathName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    //关闭iCloud备份
    [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:path]];
    return path;
}

+ (NSString *)filePathWithUrl:(NSString *)url{
    //防止名称重复，url sha256加密+文件名=最终文件名
    NSString *shaStr = [self SHA256Encode:url];
    NSString *fileName = [NSString stringWithFormat:@"%@.%@",shaStr,[NSURL fileURLWithPath:url].lastPathComponent];
    NSString *dir = [self directory:url];
    NSString *mainPath = [self mainCategory:dir];
    NSString *fullPath = [mainPath stringByAppendingPathComponent:fileName];
#if DEBUG
    NSLog(@"文件路径:%@",fullPath);
#endif
    return fullPath;
}

+ (BOOL)deleteFileWithUrl:(NSString *)url{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [self filePathWithUrl:url];
    if ([fileManager fileExistsAtPath:path]) {
        BOOL result = [fileManager removeItemAtPath:path error:nil];
        if (result) {
            [self deleteDirectory:url];
        }
        return result;
    }
    return NO;
}


+ (BOOL)isExistFileWithUrl:(NSString *)url{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self filePathWithUrl:url]];
}
#pragma mark -
#pragma mark - 下载目录统一管理

/// 获取下载的目录
/// - Parameter url: url
+(NSString*)directory:(NSString*)url{
    NSMutableDictionary *dic = [self plistdatawithFilename:directoryPlist];
    NSString *dir = dic [[self SHA256Encode:url]];
    if (dir) {
        return dir;
    }
    return mainPathName;
}

/// 设置下载的目录
/// - Parameters:
///   - dir: 名称，nil则为LdownLoad
///   - url: url
+(void)setDirectory:(nullable NSString*)dir
                url:(NSString *)url{
    NSMutableDictionary *dic = [self plistdatawithFilename:directoryPlist];
    if (!dir) {
        dir = mainPathName;
    }
    if (!dic) {
        dic = [NSMutableDictionary dictionary];
    }
    dic[[self SHA256Encode:url]]=dir;
    [self saveToplist:dic filename:directoryPlist];
}
+(void)deleteDirectory:(NSString *)url{
    NSMutableDictionary *dic = [self plistdatawithFilename:directoryPlist];
    [dic removeObjectForKey:[self SHA256Encode:url]];
    [self saveToplist:dic filename:directoryPlist];
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
//排除icloud备份
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL*)URL
{
    double version = [[UIDevice currentDevice].systemVersion doubleValue]; //判定系统版本。
    if (version >= 5.1f) {
        NSError* error = nil;

        BOOL success = [URL setResourceValue:[NSNumber numberWithBool:YES]

                                      forKey:NSURLIsExcludedFromBackupKey
                                       error:&error];

        if (!success) {
        }
        return success;
    }

    const char* filePath = [[URL path] fileSystemRepresentation];
    const char* attrName = "com.apple.MobileBackup";

    u_int8_t attrValue = 1;
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);

    return result == 0;
}
//读取
+ (NSMutableDictionary*)plistdatawithFilename:(NSString*)filename
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    //    NSError *error;
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    //    NSString *plistName=filename;
    NSString* full_name = [NSString stringWithFormat:@"%@.plist", filename];
    NSString* t_str = [documentsDirectory stringByAppendingPathComponent:full_name];
    NSString* appFile = [[NSString alloc] initWithString:t_str];
    if ([fileManager fileExistsAtPath:appFile]) {
        //注意，原写法是 return [[NSMutableDictionary alloc] initWithContentsOfFile:appFile];
        //当key=nil时，NSMutableDictionary会被判定成NSDictionaryer导致闪退 避免闪退需要pod 'NSDictionary-NilSafe'
        //所以先读取NSDictionary，再套上NSMutableDictionary,如下：
        
        NSDictionary *dic=[NSDictionary dictionaryWithContentsOfFile:appFile];
        return [[NSMutableDictionary alloc]initWithDictionary:dic];
    }else{
        return nil;
    }
}
//保存
+ (BOOL)saveToplist:(NSMutableDictionary*)t_dic
           filename:(NSString*)t_file
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    //    NSError *error;
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* full_name = [NSString stringWithFormat:@"%@.plist", t_file];
    NSString* appFile = [documentsDirectory stringByAppendingPathComponent:full_name];
    if ([fileManager fileExistsAtPath:appFile] == NO) {
        [fileManager createFileAtPath:appFile contents:nil attributes:nil];
    }
    return [t_dic writeToFile:appFile atomically:NO];
}
@end
