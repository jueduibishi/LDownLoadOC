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
    UIProgressView *pro1;
    UIProgressView *pro2;
    UIButton *bt1;
    UIButton *bt2;
}

@end

@implementation LViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Demo";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    bt1 = [UIButton buttonWithType:UIButtonTypeCustom];
    bt1.frame = CGRectMake(10, 120, 50, 30);
    [bt1 setTitle:@"下载" forState:UIControlStateNormal];
    [bt1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    bt1.tag = 1;
    [bt1 addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    
    bt2 = [UIButton buttonWithType:UIButtonTypeCustom];
    bt2.frame = CGRectMake(10, 170, 50, 30);
    [bt2 setTitle:@"下载" forState:UIControlStateNormal];
    [bt2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    bt2.tag = 2;
    [bt2 addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    
    pro1 = [[UIProgressView alloc]initWithFrame:CGRectMake(bt1.frame.origin.x+bt1.frame.size.width+10, 135, screenWidth-20-bt1.frame.origin.x-bt1.frame.size.width, 10)];
    pro1.progress = [LTaskManager progress:url1];
    pro2 = [[UIProgressView alloc]initWithFrame:CGRectMake(bt2.frame.origin.x+bt2.frame.size.width+10, 185, pro1.frame.size.width, 10)];
    pro2.progress = [LTaskManager progress:url2];
    
    
    UIButton *bt3 = [UIButton buttonWithType:UIButtonTypeCustom];
    bt3.frame = CGRectMake(10, 220, 50, 30);
    [bt3 setTitle:@"取消" forState:UIControlStateNormal];
    [bt3 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    bt3.tag = 3;
    [bt3 addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:pro1];
    [self.view addSubview:pro2];
    [self.view addSubview:bt1];
    [self.view addSubview:bt2];
    [self.view addSubview:bt3];
}

-(void)click:(UIButton*)sender{
    NSInteger tag = sender.tag;
    LTaskManager *ls = LTaskManager.instance;
    if (tag ==1) {
        [ls startDown:url1 toPath:[LFile filePathWithUrl:url1 directory:@"l"] progressBlock:^(int64_t receiveByte, int64_t allByte, CGFloat progress) {
            NSLog(@"%f",progress);
            self->pro1.progress = progress;
        } successBlock:^{
            NSLog(@"下载完成");
            [UNUserNotificationHelper sendUserNotification];
            [ls startDown:url2 toPath:[LFile filePathWithUrl:url2 directory:@"l"] progressBlock:^(int64_t receiveByte, int64_t allByte, CGFloat progress) {
                NSLog(@"%f",progress);
                self->pro2.progress = progress;
            } successBlock:^{
                NSLog(@"下载完成");
                [UNUserNotificationHelper sendUserNotification];
            } failBlock:^{
                
            }];
        } failBlock:^{
            
        }];
        sender.tag = 11;
        [sender setTitle:@"暂停" forState:UIControlStateNormal];
    }
    if (tag == 2) {
        [ls startDown:url2 toPath:[LFile filePathWithUrl:url2 directory:@"l"] progressBlock:^(int64_t receiveByte, int64_t allByte, CGFloat progress) {
            NSLog(@"%f",progress);
            self->pro2.progress = progress;
        } successBlock:^{
            NSLog(@"下载完成");
            [UNUserNotificationHelper sendUserNotification];
        } failBlock:^{
            
        }];
        sender.tag = 22;
        [sender setTitle:@"暂停" forState:UIControlStateNormal];

    }
    if (tag == 11) {
        [ls pauseDown:url1];
        sender.tag = 1;
        [sender setTitle:@"开始" forState:UIControlStateNormal];

    }
    if (tag == 22) {
        [ls pauseDown:url2];
        sender.tag = 2;
        [sender setTitle:@"开始" forState:UIControlStateNormal];

    }
    if (tag == 3) {
        [ls deleteDown:url2 path:[LFile filePathWithUrl:url2 directory:@"l"]];
        pro2.progress = [LTaskManager progress:url2];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
