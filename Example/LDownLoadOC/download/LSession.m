//
//  LSession.m
//  Shiny
//
//  Created by l on 2025/4/2.
//  Copyright © 2025 YYF. All rights reserved.
//

#import "LSession.h"
#import <CommonCrypto/CommonCrypto.h>
#import <sys/xattr.h>
#import "ResumedataFile.h"
#import "LDownloadMeta.h"

#define directoryPlist @"directoryPlist" //保存每个文件的下载位置

#define kProgressSaveThreshold (512 * 1024) // 每 512KB 落盘一次，手动杀时丢的更少

@interface LSession () <NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSURLSession *downLoadSession;
@property (nonatomic, strong) NSURLSessionDownloadTask *downLoadTask;
@property (nonatomic, copy) NSString *url;//下载链接
@property (nonatomic, copy) NSString *path;//下载目录
@property (nonatomic, copy) NSString *urlSHA256;
@property (nonatomic, strong) NSMutableDictionary *recevTimeDic;//接受数据的时间点，用来计算速度 //[String:NSTimeInterval]
@property (nonatomic, strong) NSMutableDictionary *recevDataLengthDic;//接受数据的大小，用来计算速度 //[String:long long]
@property (nonatomic, assign) int64_t lastSavedBytes;//上次保存的数据，用来控制缓存进度的频率


@end
@implementation LSession

/// 初始化，默认30秒超时
/// - Parameters:
///   - downLoadUrl: 下载地址
///   - finalPath: 文件目录
- (instancetype)initWithUrl:(NSString*)downLoadUrl
                     toPath:(NSString*)finalPath{
    return [self initWithUrl:downLoadUrl toPath:finalPath timeout:30];
}
/// 初始化
/// - Parameters:
///   - downLoadUrl: 下载地址
///   - finalPath: 文件目录
///   - timeout: 超时
- (instancetype)initWithUrl:(NSString*)downLoadUrl
                     toPath:(NSString*)finalPath
                    timeout:(NSTimeInterval)timeout
{
    self = [super init];
    if (self) {
        self.url = downLoadUrl;
        self.path = finalPath;
        self.urlSHA256 = [LFile SHA256Encode:downLoadUrl];
        //bundleid+url256编码作为sessionID
        self.identifier = [[NSString alloc]initWithFormat:@"%@%@",[NSBundle mainBundle].bundleIdentifier,self.urlSHA256];
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.identifier];
        sessionConfig.allowsCellularAccess = YES;//是否允许蜂窝网络
        sessionConfig.sessionSendsLaunchEvents = YES;//允许中后台唤醒
        sessionConfig.timeoutIntervalForRequest = timeout;
        self.downLoadSession = [NSURLSession sessionWithConfiguration:sessionConfig
                                                             delegate:self
                                                        delegateQueue:[NSOperationQueue mainQueue]];
        // 监听 App 终止
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(appWillTerminate:)
                                                             name:UIApplicationWillTerminateNotification
                                                           object:nil];
        //启动时获取下载任务——因为didCompleteWithError有时候不会执行
        [self.downLoadSession getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
            for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
                //不自动下载
                [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    
                }];
            }
            NSLog(@"----l----已存在%ld个未下载完成的任务",downloadTasks.count);
        }];
    }
    return self;
}

#pragma mark -
#pragma mark - data

-(NSMutableDictionary *)recevTimeDic{
    if (!_recevTimeDic) {
        _recevTimeDic = [NSMutableDictionary dictionary];
    }
    return _recevTimeDic;
}
-(NSMutableDictionary *)recevDataLengthDic{
    if (!_recevDataLengthDic) {
        _recevDataLengthDic = [NSMutableDictionary dictionary];
    }
    return _recevDataLengthDic;
}

#pragma mark -
#pragma mark - 下载


- (void)startTask{
    if ([LFile isExistFileWithPath:self.path]) {
        //文件已存在 → 完成
        LDownloadMeta *meta = [LDownloadMeta readDownloadMeta:self.url] ?: [[LDownloadMeta alloc] init];
        meta.url = self.url;
        meta.status = LDownloadStatusFinished;
        [LDownloadMeta saveDownloadMeta:meta];
        if (self.successBlock) self.successBlock();
        return;
    }else{
        //文件不存在
        LDownloadMeta *meta = [LDownloadMeta readDownloadMeta:self.url];
        
        if (!meta || meta.status == LDownloadStatusNone) {
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
            self.downLoadTask = [self.downLoadSession downloadTaskWithRequest:request];
            meta = [[LDownloadMeta alloc] init];
            meta.url = self.url;
            meta.urlSHA256 = self.urlSHA256;
            meta.status = LDownloadStatusDownloading;
            [LDownloadMeta saveDownloadMeta:meta];
            [self.downLoadTask resume];
            NSLog(@"----l----开始全新下载");
            return;
        }
        
        // 3. 已暂停 / 之前正在下载（被杀）
        else if (meta.status == LDownloadStatusPaused ||
                 meta.status == LDownloadStatusDownloading) {
            
            
            // 尝试用 resumeData 续传
            NSData *resumeData = [ResumedataFile resumeData:self.url];
            if (resumeData) {
                self.downLoadTask = [self.downLoadSession downloadTaskWithResumeData:resumeData];
                meta.status = LDownloadStatusDownloading;
                [LDownloadMeta saveDownloadMeta:meta];
                [self.downLoadTask resume];
                NSLog(@"----l----从断点恢复下载");
            } else {
                // resumeData 无效（手动杀 App 没存上 / tmp 被系统清理）→ 重新下载
                NSLog(@"----l----resumeData 不可用，重新下载");
                [ResumedataFile deleteResumeDataWithUrl:self.url];
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
                self.downLoadTask = [self.downLoadSession downloadTaskWithRequest:request];
                meta.status = LDownloadStatusDownloading;
                meta.totalBytesWritten = 0; // 重置进度
                [LDownloadMeta saveDownloadMeta:meta];
                [self.downLoadTask resume];
            }
            return;
        }
        
        // 4. 之前失败 → 重新下载
        else  if (meta.status == LDownloadStatusFailed) {
            [ResumedataFile deleteResumeDataWithUrl:self.url];
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
            self.downLoadTask = [self.downLoadSession downloadTaskWithRequest:request];
            meta.status = LDownloadStatusDownloading;
            [LDownloadMeta saveDownloadMeta:meta];
            [self.downLoadTask resume];
            NSLog(@"----l----重新下载（上次失败）");
            return;
        }
        
        // 5. 标记完成但文件不存在 → 重新下载
        else  if (meta.status == LDownloadStatusFinished) {
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
            self.downLoadTask = [self.downLoadSession downloadTaskWithRequest:request];
            meta.status = LDownloadStatusDownloading;
            [LDownloadMeta saveDownloadMeta:meta];
            [self.downLoadTask resume];
            NSLog(@"----l----文件丢失，重新下载");
            return;
        }
    }
    
}

- (void)deleteTask{
    if (self.downLoadTask) {
        //移除任务
        [self.downLoadTask cancel];
        self.downLoadTask = nil;
    }
    //删除resumeData
    [ResumedataFile deleteResumeDataWithUrl:self.url];
    NSString *resumeName = [LFile SHA256Encode:self.url];
    //移除下载进度
    [self.recevTimeDic removeObjectForKey:resumeName];
    [self.recevDataLengthDic removeObjectForKey:resumeName];
    //移除下载记录
    [LFile deleteDownLoadSession:self.url];
    //移除文件
    [LFile deleteFileWithPath:self.path];
    //移除下载数据
    [LDownloadMeta deleteDownloadMeta:self.url];
}

- (void)pauseTask{
    if (!self.downLoadTask) {
        LDownloadMeta *meta = [LDownloadMeta readDownloadMeta:self.url] ?: [[LDownloadMeta alloc] init];
        meta.url = self.url;
        meta.status = LDownloadStatusPaused;
        [LDownloadMeta saveDownloadMeta:meta];
        return;
    }
    
    //暂停，会触发NSURLSessionDownloadDelegate
    [self.downLoadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        LDownloadMeta *meta = [LDownloadMeta readDownloadMeta:self.url] ?: [[LDownloadMeta alloc] init];
        meta.url = self.url;
        meta.status = LDownloadStatusPaused;
        [LDownloadMeta saveDownloadMeta:meta];
    }];
}
#pragma mark -
#pragma mark - app终止监听
- (void)appWillTerminate:(NSNotification *)notification {
    // 只处理正在下载的任务
    if (self.downLoadTask && self.downLoadTask.state == NSURLSessionTaskStateRunning) {
        NSLog(@"----l----willTerminate，紧急保存");
        [self emergencyPauseWithCompletion:nil];
    }
}

#pragma mark -
#pragma mark -app被杀时保存进度

/// 被杀时紧急保存（AppDelegate 的 applicationWillTerminate 调用）
- (void)emergencyPauseWithCompletion:(dispatch_block_t)completion {
    if (!self.downLoadTask) {
        LDownloadMeta *meta = [LDownloadMeta readDownloadMeta:self.url];
        if (meta) {
            meta.status = LDownloadStatusPaused;
            [LDownloadMeta saveDownloadMeta:meta];
        }
        if (completion) completion();
        return;
    }
    
    [self.downLoadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        if (resumeData) {
            [ResumedataFile saveResumeData:resumeData withUrl:self.url];
        }
        LDownloadMeta *meta = [LDownloadMeta readDownloadMeta:self.url] ?: [[LDownloadMeta alloc] init];
        meta.url = self.url;
        meta.urlSHA256 = self.urlSHA256;
        meta.status = LDownloadStatusPaused;
        [LDownloadMeta saveDownloadMeta:meta];
        if (completion) completion();
    }];
}

#pragma mark -
#pragma mark - NSURLSessionDownloadDelegate

///完成下载
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    NSString *locationPath = [location path];
    NSError *error;
    //移动文件到下载文件夹
    [[NSFileManager defaultManager] moveItemAtPath:locationPath toPath:self.path error:&error];
    
    LDownloadMeta *meta = [LDownloadMeta readDownloadMeta:self.url] ?: [[LDownloadMeta alloc] init];
    meta.url = self.url;
    meta.urlSHA256 = self.urlSHA256;
    
    if (error == nil) {
        meta.status = LDownloadStatusFinished;
        meta.totalBytesWritten = meta.totalBytesExpected;
        [LDownloadMeta saveDownloadMeta:meta];
        [ResumedataFile deleteResumeDataWithUrl:self.url];
        //关闭iCloud备份
        [[NSURL fileURLWithPath:self.path] setResourceValue:[NSNumber numberWithBool:YES]
                                                     forKey:NSURLIsExcludedFromBackupKey
                                                      error:nil];
        if (self.successBlock){
            self.successBlock();
        }
    } else {
        meta.status = LDownloadStatusFailed;
        [LDownloadMeta saveDownloadMeta:meta];
        if (self.failBlock){
            self.failBlock();
        }
    }
    
    
    
}

/// 进度等
/// - Parameters:
///   - session: 当前会话
///   - downloadTask: 下载任务
///   - bytesWritten: 每次收到的数据
///   - totalBytesWritten: 已收到的总数据
///   - totalBytesExpectedToWrite: 文件大小
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    NSString *url = downloadTask.originalRequest.URL.absoluteString;
    if (self.progressBlock && totalBytesExpectedToWrite != 0) {
        CGFloat progress = (CGFloat)totalBytesWritten / (CGFloat) totalBytesExpectedToWrite;
        self.progressBlock(totalBytesWritten, totalBytesExpectedToWrite,progress);
    }
    // 节流落盘（每 512KB）
    if (totalBytesExpectedToWrite > 0 &&
        (totalBytesWritten - self.lastSavedBytes >= kProgressSaveThreshold ||
         totalBytesWritten == totalBytesExpectedToWrite)) {
        
        LDownloadMeta *meta = [LDownloadMeta readDownloadMeta:self.url] ?: [[LDownloadMeta alloc] init];
        meta.url = self.url;
        meta.urlSHA256 = self.urlSHA256;
        meta.totalBytesWritten = totalBytesWritten;
        meta.totalBytesExpected = totalBytesExpectedToWrite;
        meta.status = LDownloadStatusDownloading;
        [LDownloadMeta saveDownloadMeta:meta];
        self.lastSavedBytes = totalBytesWritten;
    }
    if (self.speedBlock) {
        //url加密
        NSString *resumeName = [LFile SHA256Encode:url];
        if ([self.recevTimeDic[resumeName] doubleValue] == 0) {
            self.recevTimeDic[resumeName] = [[NSString alloc]initWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];;
            self.recevDataLengthDic[resumeName] = [[NSString alloc]initWithFormat:@"%lld", totalBytesWritten];
        }
        NSTimeInterval time = ([[NSDate date] timeIntervalSince1970] - [self.recevTimeDic[resumeName]doubleValue])*1000;
        if ([self.recevTimeDic[resumeName] doubleValue] != 0 && (time >= 1000)) {
            int64_t lastReveDataLen = [self.recevDataLengthDic[resumeName] longLongValue];
            int64_t datasended = totalBytesWritten - lastReveDataLen;
            double speed = (datasended*1000/(1024*1024)) / time;
            NSString * speedStr = [[NSString alloc]initWithFormat:@"%.2fM/s",speed];
            if (speed<1) {
                speedStr = [NSString stringWithFormat:@"%.2fK/S",(datasended*1000/1024.0) / time];
            }
            self.speedBlock(speedStr);
            self.recevTimeDic[resumeName] = [[NSString alloc]initWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
            self.recevDataLengthDic[resumeName] = [[NSString alloc]initWithFormat:@"%lld", totalBytesWritten];
        }
    }
    
}

/*
 * 注意：crash或者被系统关闭时本方法不会执行！！！！！
 * 该方法下载成功和失败都会回调，只是失败的是error是有值的，
 * 在下载失败时，error的userinfo属性可以通过NSURLSessionDownloadTaskResumeData
 * 这个key来取到resumeData(和上面的resumeData是一样的)，再通过resumeData恢复下载
 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    
    if (error) {
        // check if resume data are available
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
            
            NSString *url = task.originalRequest.URL.absoluteString;
            NSString *resumeName = [LFile SHA256Encode:url];
            //暂停，时间清空
            self.recevTimeDic[resumeName]=0;
            LDownloadMeta *meta = [LDownloadMeta readDownloadMeta:self.url] ?: [[LDownloadMeta alloc] init];
            meta.url = self.url;
            meta.urlSHA256 = self.urlSHA256;
            meta.status = LDownloadStatusPaused;
            [LDownloadMeta saveDownloadMeta:meta];
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
            if (resumeData) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [ResumedataFile saveResumeData:resumeData withUrl:url];
                    if (self.failBlock) {
                        //下载失败或者任务取消
                        NSLog(@"-----l-----任务暂停");
                        self.failBlock();
                    }
                });
            }
        }
    } else {
        //下载完成
        NSString *url = task.originalRequest.URL.absoluteString;
        NSString *codeName = [LFile SHA256Encode:url];
        [self.recevTimeDic removeObjectForKey:codeName];
        [self.recevDataLengthDic removeObjectForKey:codeName];
        [ResumedataFile deleteResumeDataWithUrl:task.originalRequest.URL.absoluteString];
        LDownloadMeta *meta = [LDownloadMeta readDownloadMeta:self.url];
        if (meta) {
            meta.status = LDownloadStatusFinished;
            [LDownloadMeta saveDownloadMeta:meta];
        }
    }
}
///与appdelegate的 handleEventsForBackgroundURLSession联动，必须在主线程中调用
///必须在主线程中调用
///必须在主线程中调用
///必须在主线程中调用
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    if (self.backgroundCompletionBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.backgroundCompletionBlock();
            self.backgroundCompletionBlock = nil;
        });
    }
    
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.downLoadSession) {
        [self.downLoadSession invalidateAndCancel];
        self.downLoadSession = nil;
    }
    
}

@end
