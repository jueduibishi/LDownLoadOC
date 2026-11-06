//
//  LDownloadMeta.m
//  LDownLoadOC_Example
//
//  Created by l on 2026/11/6.
//  Copyright © 2026 jueduibishi. All rights reserved.
//

#import "LDownloadMeta.h"
#import "LFile.h"

@implementation LDownloadMeta

// 必须声明支持 secure coding
+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.url forKey:@"url"];
    [coder encodeObject:self.urlSHA256 forKey:@"urlSHA256"];
    [coder encodeInt64:self.totalBytesWritten forKey:@"totalBytesWritten"];
    [coder encodeInt64:self.totalBytesExpected forKey:@"totalBytesExpected"];
    [coder encodeInteger:self.status forKey:@"status"];
    [coder encodeObject:self.tempFileName forKey:@"tempFileName"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _url = [coder decodeObjectOfClass:[NSString class] forKey:@"url"];
        _urlSHA256 = [coder decodeObjectOfClass:[NSString class] forKey:@"urlSHA256"];
        _totalBytesWritten = [coder decodeInt64ForKey:@"totalBytesWritten"];
        _totalBytesExpected = [coder decodeInt64ForKey:@"totalBytesExpected"];
        _status = [coder decodeIntegerForKey:@"status"];
        _tempFileName = [coder decodeObjectOfClass:[NSString class] forKey:@"tempFileName"];
    }
    return self;
}


+ (NSString *)downloadMetaDir {
    NSString *dir = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
                     stringByAppendingPathComponent:@"DownloadMeta"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    //关闭iCloud备份
    [[NSURL fileURLWithPath:dir] setResourceValue:[NSNumber numberWithBool:YES]
                                  forKey:NSURLIsExcludedFromBackupKey
                                   error:nil];
    return dir;
}

+ (NSString *)downloadTmpBackupDir {
    NSString *dir = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
                     stringByAppendingPathComponent:@"DownloadMetaTmp"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    //关闭iCloud备份
    [[NSURL fileURLWithPath:dir] setResourceValue:[NSNumber numberWithBool:YES]
                                  forKey:NSURLIsExcludedFromBackupKey
                                   error:nil];
    return dir;
}

+ (void)saveDownloadMeta:(LDownloadMeta *)meta {
    if (!meta.urlSHA256) meta.urlSHA256 = [LFile SHA256Encode:meta.url];
    NSString *path = [[self downloadMetaDir] stringByAppendingPathComponent:
                      [NSString stringWithFormat:@"%@.plist", meta.urlSHA256]];
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    
    NSError *archiveError = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:meta
                                         requiringSecureCoding:YES
                                                         error:&archiveError];
    if (archiveError || !data) {
        NSLog(@"----l---- archive meta 失败: %@", archiveError);
        return;
    }
    
    NSError *writeError = nil;
    BOOL success = [data writeToURL:fileURL
                            options:NSDataWritingAtomic
                              error:&writeError];
    if (!success || writeError) {
        NSLog(@"----l---- 写 meta 文件失败: %@", writeError);
    }
}

+ (nullable LDownloadMeta *)readDownloadMeta:(NSString *)url {
    NSString *key = [LFile SHA256Encode:url];
    NSString *path = [[self downloadMetaDir] stringByAppendingPathComponent:
                      [NSString stringWithFormat:@"%@.plist", key]];
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    // 从文件读 NSData
    NSError *readError = nil;
    NSData *data = [NSData dataWithContentsOfURL:fileURL
                                         options:NSDataReadingMappedIfSafe
                                           error:&readError];
    if (!data || readError) {
        NSLog(@"----l---- 读 meta 文件失败: %@", readError);
        return nil;
    }
    NSError *unarchiveError = nil;
    LDownloadMeta *meta = [NSKeyedUnarchiver unarchivedObjectOfClass:[LDownloadMeta class]
                                                            fromData:data
                                                               error:&unarchiveError];
    if (unarchiveError) {
        NSLog(@"----l---- 读 meta 文件解档失败: %@", unarchiveError);
        return nil;
    }
    
    return meta;
}

+ (void)deleteDownloadMeta:(NSString *)url {
    NSString *key = [LFile SHA256Encode:url];
    NSString *path = [[self downloadMetaDir] stringByAppendingPathComponent:
                      [NSString stringWithFormat:@"%@.plist", key]];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}


+ (float)cachedProgress:(NSString *)url{
    LDownloadMeta *meta = [LDownloadMeta readDownloadMeta:url];
    if (meta && meta.totalBytesExpected > 0) {
        return (float)meta.totalBytesWritten / meta.totalBytesExpected;
    }
    return 0;
}
@end
