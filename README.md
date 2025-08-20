# LDownLoadOC

 [![CI Status](https://img.shields.io/travis/jueduibishi/LDownLoadOC.svg?style=flat)](https://travis-ci.org/jueduibishi/LDownLoadOC)
 [![Version](https://img.shields.io/cocoapods/v/LDownLoadOC.svg?style=flat)](https://cocoapods.org/pods/LDownLoadOC)
 [![License](https://img.shields.io/cocoapods/l/LDownLoadOC.svg?style=flat)](https://cocoapods.org/pods/LDownLoadOC)
 [![Platform](https://img.shields.io/cocoapods/p/LDownLoadOC.svg?style=flat)](https://cocoapods.org/pods/LDownLoadOC)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

LDownLoadOC is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'LDownLoadOC'
```
## 使用说明
1、启动时在didFinishLaunchingWithOptions中实现
```
//预设置，防止系统自动下载，保持线程可控
LTaskManager *manager = [LTaskManager instance];
[manager preConfig];
```

2、在AppDelegate中实现以下方法，app进入后台时线程可以被唤醒保持下载
```
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler{
LTaskManager *manager = [LTaskManager instance];
NSArray *sessions = manager.sessionDic.allValues;
for (LSession *session in sessions) {
if ([session.identifier isEqualToString:identifier]) {
session.backgroundCompletionBlock = completionHandler;
}
}
}
```
3、下载管理LTaskManager为单例模式，开始和继续下载合并为一个方法。
```
LTaskManager *ls = LTaskManager.instance;
[ls startDown:url1 toPath:[LFile filePathWithUrl:url1 directory:@"l"] progressBlock:^(int64_t receiveByte, int64_t allByte, CGFloat progress) {
    NSLog(@"%f",progress);
    pro1.progress = progress;
} successBlock:^{
    NSLog(@"下载完成");
    [UNUserNotificationHelper sendUserNotification];
} failBlock:^{

}];
```
暂停下载
```
[ls pauseDown:url1];
```
移除下载：若下载未完成，则移除下载进程，若已完成则移除下载文件，所以要传入下载路径。
```
[ls deleteDown:url1 path:[LFile filePathWithUrl:url1 directory:@"l"]];
```

## License

LDownLoadOC is available under the MIT license. See the LICENSE file for more info.
