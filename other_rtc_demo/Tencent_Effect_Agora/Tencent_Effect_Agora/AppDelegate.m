//
//  AppDelegate.m
//  AgoraBeautyDemo
//
//  Created by tao yue on 2025/3/13.
//

#import "AppDelegate.h"
#import <TEBeautyKit.h>

static NSString *const kTELicenseURL = @"please set your license url";
static NSString *const kTELicenseKey = @"please set your license key";

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [TEBeautyKit setTELicense:kTELicenseURL key:kTELicenseKey completion:^(NSInteger authresult, NSString * _Nullable errorMsg) {
        NSLog(@"打印鉴权结果  %ld ",authresult);
    }];

    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
