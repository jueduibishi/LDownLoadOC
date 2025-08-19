//
//  LTaskManager.m
//  LDownLoadOC_Example
//
//  Created by l on 2025/8/18.
//  Copyright © 2025 jueduibishi. All rights reserved.
//

#import "LTaskManager.h"

@interface LTaskManager ()
@end

@implementation LTaskManager

+ (instancetype)instance{
    static LTaskManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LTaskManager alloc] init];
    });
    return instance;
}
-(NSMutableDictionary*)sessionDic{
    if (!_sessionDic) {
        _sessionDic = [NSMutableDictionary dictionary];
    }
    return _sessionDic;
}
-(void)preConfig{
    NSMutableDictionary *downloadDic = [LFile downLoadList];
    if (downloadDic) {
        NSArray *urlArray = downloadDic.allKeys;
        for (NSString *url in urlArray) {
            LSession *session = [[LSession alloc]initWithUrl:url toPath:@"l"];
            self.sessionDic[url] = session;
        NSMutableDictionary *downloadDic = [LFile downLoadList];
        if (downloadDic) {
            NSArray *urlArray = downloadDic.allKeys;
            for (NSString *url in urlArray) {
                LSession *session = [[LSession alloc]initWithUrl:url toPath:@"l"];
                self.sessionDic[url] = session;
            }
        }
    }
}
#pragma mark -
#pragma mark -下载

-(void)startDown:(NSString*)url
          toPath:(NSString*)path
   progressBlock:(ProgressHandler)progressBlock
    successBlock:(SucHandler)successBlock
       failBlock:(FailHandler)failBlock{
    
    LSession *session = self.sessionDic[url];
    
    if (!session) {
        session = [[LSession alloc]initWithUrl:url toPath:path];
        self.sessionDic[url]=session;
    }
    session.progressBlock = ^(int64_t receiveByte, int64_t allByte, CGFloat progress) {
        progressBlock(receiveByte,allByte,progress);
    };
    session.successBlock = ^{
        successBlock();
    };
    session.failBlock = ^{
        failBlock();
    };
    [session startTask];
}


/// 暂停下载
/// - Parameter url: url
-(void)pauseDown:(NSString*)url{
    LSession *session = self.sessionDic[url];
    if (session) {
        [session pauseTask];
    }
}

-(void)deleteDown:(NSString *)url
             path:(NSString *)path{
    LSession *session = self.sessionDic[url];
    if (session) {
        [session deleteTask];
        [self.sessionDic removeObjectForKey:url];
    }else{
        //已下载，只移除文件
        [LFile deleteFileWithPath:path];
    }
}

//是否正在下载
- (BOOL)isDownloading{
    return self.sessionDic.count>0;
}
@end
