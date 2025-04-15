//
//  LViewController.m
//  LDownLoadOC
//
//  Created by jueduibishi on 04/15/2025.
//  Copyright (c) 2025 jueduibishi. All rights reserved.
//

#import "LViewController.h"
#import "LSession.h"
#import "UNUserNotificationHelper.h"

#define url1 @"https://baichuan-sdk-bucket.oss-cn-hangzhou.aliyuncs.com/ios/AlibcTradeUltimateSDK_all_package_50018.zip?spm=a3c0d.7629140.0.0.187abe48bai8tp&file=AlibcTradeUltimateSDK_all_package_50018.zip"

#define url2 @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V6.5.2.dmg"

@interface LViewController (){
    UILabel *label1;
    UIProgressView *pro1;
}

@end

@implementation LViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"demo";
    
    label1 = [[UILabel alloc]initWithFrame:CGRectMake(150, 100, 100, 30)];
    pro1 = [[UIProgressView alloc]initWithFrame:CGRectMake(250, 115, 100, 10)];
    
    UIButton *bt1 = [UIButton buttonWithType:UIButtonTypeCustom];
    bt1.frame = CGRectMake(70, 100, 50, 30);
    [bt1 setTitle:@"下载" forState:UIControlStateNormal];
    [bt1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    bt1.tag = 0;
    [bt1 addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *bt2 = [UIButton buttonWithType:UIButtonTypeCustom];
    bt2.frame = CGRectMake(360, 100, 50, 30);
    [bt2 setTitle:@"暂停" forState:UIControlStateNormal];
    [bt2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    bt2.tag = 10;
    [bt2 addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *bt3 = [UIButton buttonWithType:UIButtonTypeCustom];
    bt3.frame = CGRectMake(0, 100, 50, 30);
    [bt3 setTitle:@"取消" forState:UIControlStateNormal];
    [bt3 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    bt3.tag = 20;
    [bt3 addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:label1];
    [self.view addSubview:pro1];
    [self.view addSubview:bt1];
    [self.view addSubview:bt2];
    [self.view addSubview:bt3];
}

-(void)click:(UIButton*)sender{
    NSInteger tag = sender.tag;
    LSession *ls = LSession.instance;
    if (tag ==0) {
        ls.successBlock = ^(NSString * _Nonnull url) {
            NSLog(@"下载完成");
            [UNUserNotificationHelper sendUserNotification];
//            [ls startDownload:url2 directory:@"ls"];
        };
        ls.failureBlock = ^(NSString * _Nonnull url) {
            NSLog(@"下载取消");
        };
        ls.progressBlock = ^(NSString * _Nonnull url, int64_t receiveByte, int64_t allByte, CGFloat progress) {
            if ([url isEqualToString:url1]) {
                pro1.progress = progress;
            }
        };
        ls.speedBlock = ^(NSString * _Nonnull url, NSString * _Nonnull speed) {
            if ([url isEqualToString:url1]) {
                label1.text = speed;
            }
        };
        //最后执行
        [ls startDownload:url1 directory:@"ls"];
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [ls startDownload:url2 directory:@"ls"];
//        });
    }
    if (tag == 10) {
        [ls pauseDownload:url1];
    }
    if (tag == 20) {
        [ls deleteDownload:url1];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
