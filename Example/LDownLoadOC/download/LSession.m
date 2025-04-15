//
//  LSession.m
//  Shiny
//
//  Created by l on 2025/4/2.
//  Copyright © 2025 YYF. All rights reserved.
//

#import "LSession.h"
#import "ResumedataFile.h"
#import "LFile.h"

@interface LSession () <NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSURLSession *downLoadSession;
@property (nonatomic, strong) NSMutableDictionary *codeUrlDic;//文件名加密 //[String:String]

@property (nonatomic, strong) NSMutableDictionary *taskDic; //[String:NSURLSessionDownloadTask]
@property (nonatomic, strong) NSMutableDictionary *recevTimeDic;//接受数据的时间点，用来计算速度 //[String:NSTimeInterval]
@property (nonatomic, strong) NSMutableDictionary *recevDataLengthDic;//接受数据的大小，用来计算速度 //[String:long long]



@end
@implementation LSession

+ (instancetype)instance{
    static LSession *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LSession alloc] init];
    });
    return instance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *identifier = [NSBundle mainBundle].bundleIdentifier;
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        self.identifier = identifier;
        sessionConfig.allowsCellularAccess = YES;//是否允许蜂窝网络
        sessionConfig.sessionSendsLaunchEvents = YES;//允许中后台唤醒
        sessionConfig.timeoutIntervalForRequest = 30;
        self.downLoadSession = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
        //启动时获取下载任务——因为didCompleteWithError有时候不会执行
        [self.downLoadSession getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
            for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
                [self saveLownloadTask:downloadTask];
                //不自动下载
                [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                                    
                }];
            }
            NSLog(@"----l----当前有%ld个任务",downloadTasks.count);
        }];
    }
    return self;
}
#pragma mark -
#pragma mark - data

/// 设置超时
/// - Parameter timeout: 超时
-(void)setTimeout:(CGFloat)timeout{
    _timeout = timeout;
    if (self.downLoadSession) {
        self.downLoadSession.configuration.timeoutIntervalForRequest = timeout;
    }
}

/// 读取本地未完成的resumeData组成taskDic
-(NSMutableDictionary *)taskDic{
    if (!_taskDic) {
        _taskDic = [NSMutableDictionary dictionary];
    }
    return _taskDic;
}
-(NSMutableDictionary *)codeUrlDic{
    if (!_codeUrlDic) {
        _codeUrlDic = [NSMutableDictionary dictionary];
    }
    return _codeUrlDic;
}
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
#pragma mark -数据处理

/// sha256加密
/// - Parameter url: url
-(NSString*)codeUrl:(NSString*)url{
    NSString *urlCode = self.codeUrlDic[url];
    if (!urlCode) {
        urlCode = [ResumedataFile fileName:url];
        self.codeUrlDic[url] = urlCode;
    }
    return urlCode;
}

/// 保存下载任务
/// - Parameter task: task
-(void)saveLownloadTask:(NSURLSessionDownloadTask*)task{
    NSString *url = task.originalRequest.URL.absoluteString;
    NSString *codeUrl = [self codeUrl:url];
    self.taskDic[codeUrl] = task;
}
#pragma mark -
#pragma mark - 下载等

- (void)startDownload:(NSString *)url
            directory:(nullable NSString *)directory{
    if ([LFile isExistFileWithUrl:url]) {
        if (self.successBlock) {
            //已下载
            self.successBlock(url);
        }
    }else{
        //url加密的string
        NSString *resumeName = [self codeUrl:url];
        //保存下载目录
        [LFile setDirectory:directory url:url];
        NSURLSessionDownloadTask *task = self.taskDic[resumeName];
        if (task) {
            //已存在，继续下载
            NSLog(@"-----l-----继续下载");
            [task resume];
        }else{
            //新增下载
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
            NSURLSessionDownloadTask *task = [self.downLoadSession downloadTaskWithRequest:request];
            self.taskDic[resumeName] = task;
            [task resume];
            NSLog(@"-----l-----开始下载");
        }
    }
    
    
}
- (void)continueDownload:(NSString *)url{
    NSString *resumeName = [self codeUrl:url];
    NSURLSessionDownloadTask *task = self.taskDic[resumeName];
    if (task) {
        //继续下载
        [task resume];
    }
}

- (void)deleteDownload:(NSString *)url{
    NSString *resumeName = [self codeUrl:url];
    NSURLSessionDownloadTask *task = self.taskDic[resumeName];
    if (task) {
        //移除任务
        [task cancel];
        task = nil;
    }
    //删除resumeData
    [ResumedataFile deleteResumeDataWithUrl:url];
    //移除列表
    [self.taskDic removeObjectForKey:resumeName];
    //删除已保存的路径
    [LFile deleteDirectory:url];
    //移除下载进度
    [self.recevTimeDic removeObjectForKey:resumeName];
    [self.recevDataLengthDic removeObjectForKey:resumeName];
}

- (void)pauseDownload:(NSString *)url{
    NSString *resumeName = [self codeUrl:url];
    NSURLSessionDownloadTask *task = self.taskDic[resumeName];
    if (task) {
        //暂停，会触发NSURLSessionDownloadDelegate
        [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    
        }];
    }
}
#pragma mark -
#pragma mark - NSURLSessionDownloadDelegate

///完成下载
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    NSString *locationPath = [location path];
    //获取当前下载的url
    NSString *url = downloadTask.currentRequest.URL.absoluteString;
    NSString *finalPath = [LFile filePathWithUrl:url];
    NSError *error;
    //移动文件到下载文件夹
    [[NSFileManager defaultManager] moveItemAtPath:locationPath toPath:finalPath error:&error];
    NSLog(@"-----l-----下载完成%@",finalPath);
    
    if (self.successBlock) {
        self.successBlock(url);
    }
    
}
//断点续传，从fileOffset开始
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    
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
        self.progressBlock(url, totalBytesWritten, totalBytesExpectedToWrite,progress);
    }
    if (self.speedBlock) {
        //url加密
        NSString *resumeName = [self codeUrl:url];
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
            self.speedBlock(url, speedStr);
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
            NSString *resumeName = [self codeUrl:url];
            //暂停，时间清空
            self.recevTimeDic[resumeName]=0;
            
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
            if (resumeData) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    [ResumedataFile saveResumeData:resumeData withUrl:url];
                    NSURLSessionDownloadTask *downLoadTask = [self.downLoadSession downloadTaskWithResumeData:resumeData];
                    [self saveLownloadTask:downLoadTask];
                    if (self.failureBlock) {
                        //下载失败或者任务取消
                        NSLog(@"-----l-----任务暂停");
                        self.failureBlock(url);
                    }
                });
            }
        }
    } else {
        //下载完成
        NSString *url = task.originalRequest.URL.absoluteString;
        NSString *resumeName = [self codeUrl:url];
        [self.recevTimeDic removeObjectForKey:resumeName];
        [self.recevDataLengthDic removeObjectForKey:resumeName];
        [self.taskDic removeObjectForKey:resumeName];
        [ResumedataFile deleteResumeDataWithUrl:task.originalRequest.URL.absoluteString];
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
    [self.downLoadSession invalidateAndCancel];
    self.downLoadSession = nil;
    [self.taskDic removeAllObjects];
}
@end
