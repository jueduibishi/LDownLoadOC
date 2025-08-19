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

#define downLoadDirectory @"downLoadDirectory" //默认下载目录
#define LdownLoadPlist @"LdownLoadPlist" //保存每个文件的下载位置
@implementation LFile


/// 下载目录
/// - Parameter dir: document+"name"  name默认=downLoadDirectory
+ (NSString *)mainDownCategory:(nullable NSString *)dir{
    NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [doc stringByAppendingPathComponent:dir?dir:downLoadDirectory];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    //关闭iCloud备份
    [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:path]];
    return path;
}

+ (nullable NSString *)filePathWithUrl:(NSString *)url
                             directory:(NSString*)directory{
    //防止名称重复，url sha256加密+文件名=最终文件名
    NSString *shaStr = [self SHA256Encode:url];
    NSString *fileName = [NSString stringWithFormat:@"%@.%@",shaStr,[NSURL fileURLWithPath:url].lastPathComponent];
    NSString *mainPath = [self mainDownCategory:directory];
    NSString *fullPath = [mainPath stringByAppendingPathComponent:fileName];
#if DEBUG
    NSLog(@"文件路径:%@",fullPath);
#endif
    return fullPath;
}

+ (BOOL)deleteFileWithPath:(NSString*)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        BOOL result = [fileManager removeItemAtPath:path error:nil];
        return result;
    }
    return NO;
}

+ (BOOL)isExistFileWithPath:(NSString *)fullPath{
    return [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
}
#pragma mark -
#pragma mark - 下载信息

+(void)saveDownLoad:(NSString*)url
               path:(NSString*)path{
    NSMutableDictionary *dic = [self plistdatawithFilename:LdownLoadPlist];
    if (!dic) {
        dic = [NSMutableDictionary dictionary];
    }
    dic[[self SHA256Encode:url]]=path;
    [self saveToplist:dic filename:LdownLoadPlist];
}


/// 获取下载列表
+(nullable NSMutableDictionary*)downLoadList{
    return [self plistdatawithFilename:LdownLoadPlist];
}
+(void)deleteDownLoadSession:(NSString *)url{
    NSMutableDictionary *dic = [self plistdatawithFilename:LdownLoadPlist];
    if (dic) {
        [dic removeObjectForKey:[self SHA256Encode:url]];
        [self saveToplist:dic filename:LdownLoadPlist];
    }
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
+(nullable NSMutableDictionary*)plistdatawithFilename:(NSString*)filename
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
    }
    return nil;
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
