//
//  LViewController.m
//  LDownLoadOC
//
//  Created by jueduibishi on 04/15/2025.
//  Copyright (c) 2025 jueduibishi. All rights reserved.
//

#import "LViewController.h"
#import "LTaskManager.h"
#import "UNUserNotificationHelper.h"

#define url1 @"https://baichuan-sdk-bucket.oss-cn-hangzhou.aliyuncs.com/ios/AlibcTradeUltimateSDK_all_package_50018.zip?spm=a3c0d.7629140.0.0.187abe48bai8tp&file=AlibcTradeUltimateSDK_all_package_50018.zip"

#define url2 @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V6.5.2.dmg"

@interface LViewController (){
    UILabel *label1;
    UIProgressView *pro1;
    UIProgressView *pro2;
}

@end

@implementation LViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"demo";
    
    label1 = [[UILabel alloc]initWithFrame:CGRectMake(150, 100, 100, 30)];
    pro1 = [[UIProgressView alloc]initWithFrame:CGRectMake(250, 115, 100, 10)];
    pro2 = [[UIProgressView alloc]initWithFrame:CGRectMake(250, 165, 100, 10)];

    
    UIButton *bt1 = [UIButton buttonWithType:UIButtonTypeCustom];
    bt1.frame = CGRectMake(70, 100, 50, 30);
    [bt1 setTitle:@"下载" forState:UIControlStateNormal];
    [bt1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    bt1.tag = 1;
    [bt1 addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *bt11 = [UIButton buttonWithType:UIButtonTypeCustom];
    bt11.frame = CGRectMake(70, 150, 50, 30);
    [bt11 setTitle:@"下载" forState:UIControlStateNormal];
    [bt11 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    bt11.tag = 11;
    [bt11 addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *bt2 = [UIButton buttonWithType:UIButtonTypeCustom];
    bt2.frame = CGRectMake(360, 100, 50, 30);
    [bt2 setTitle:@"暂停" forState:UIControlStateNormal];
    [bt2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    bt2.tag = 2;
    [bt2 addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *bt22 = [UIButton buttonWithType:UIButtonTypeCustom];
    bt22.frame = CGRectMake(360, 150, 50, 30);
    [bt22 setTitle:@"暂停" forState:UIControlStateNormal];
    [bt22 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    bt22.tag = 22;
    [bt22 addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *bt3 = [UIButton buttonWithType:UIButtonTypeCustom];
    bt3.frame = CGRectMake(0, 100, 50, 30);
    [bt3 setTitle:@"取消" forState:UIControlStateNormal];
    [bt3 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    bt3.tag = 3;
    [bt3 addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:label1];
    [self.view addSubview:pro1];
    [self.view addSubview:pro2];
    [self.view addSubview:bt1];
    [self.view addSubview:bt2];
    [self.view addSubview:bt11];
    [self.view addSubview:bt22];
    [self.view addSubview:bt3];
}

-(void)click:(UIButton*)sender{
    NSInteger tag = sender.tag;
    LTaskManager *ls = LTaskManager.instance;
    if (tag ==1) {
        [ls startDown:url1 toPath:[LFile filePathWithUrl:url1 directory:@"l"] progressBlock:^(int64_t receiveByte, int64_t allByte, CGFloat progress) {
            NSLog(@"%f",progress);
            pro1.progress = progress;
        } successBlock:^{
            NSLog(@"下载完成");
            [UNUserNotificationHelper sendUserNotification];
            [ls startDown:url2 toPath:[LFile filePathWithUrl:url2 directory:@"l"] progressBlock:^(int64_t receiveByte, int64_t allByte, CGFloat progress) {
                NSLog(@"%f",progress);
                pro2.progress = progress;
            } successBlock:^{
                NSLog(@"下载完成");
                [UNUserNotificationHelper sendUserNotification];
            } failBlock:^{
                
            }];
        } failBlock:^{
            
        }];
        
    }
    if (tag == 11) {
        [ls startDown:url2 toPath:[LFile filePathWithUrl:url2 directory:@"l"] progressBlock:^(int64_t receiveByte, int64_t allByte, CGFloat progress) {
            NSLog(@"%f",progress);
            pro2.progress = progress;
        } successBlock:^{
            NSLog(@"下载完成");
            [UNUserNotificationHelper sendUserNotification];
        } failBlock:^{
            
        }];
    }
    if (tag == 2) {
        [ls pauseDown:url1];
        
    }
    if (tag == 22) {
        [ls pauseDown:url2];
        
    }
    if (tag == 3) {
        [ls deleteDown:url1 path:[LFile filePathWithUrl:url1 directory:@"l"]];
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
