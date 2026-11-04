//
//  SceneDelegate.m
//  LDownLoadOC_Example
//
//  Created by l on 2026/11/4.
//  Copyright © 2026 jueduibishi. All rights reserved.
//

#import "SceneDelegate.h"
#import "LViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {

    if (![scene isKindOfClass:[UIWindowScene class]]) return;

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.frame = windowScene.coordinateSpace.bounds;

    // 纯代码 UI：在这里建根控制器
    self.window.rootViewController = [[UINavigationController alloc]initWithRootViewController:[[LViewController alloc] init]];


    [self.window makeKeyAndVisible];

    // 处理冷启动带过来的 URL / Universal Link
    for (UIOpenURLContext *ctx in connectionOptions.URLContexts) {
        [self handleIncomingURL:ctx.URL];
    }
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    // 原来 applicationDidBecomeActive 里的 UI 逻辑搬过来
}

- (void)sceneWillResignActive:(UIScene *)scene {
    // 原来 applicationWillResignActive 搬过来
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    // 原来 applicationDidEnterBackground 搬过来
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
    // 原来 applicationWillEnterForeground 搬过来
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    for (UIOpenURLContext *ctx in URLContexts) {
        [self handleIncomingURL:ctx.URL];
    }
}

- (void)handleIncomingURL:(NSURL *)url {
    // 你的深链处理
}
@end
