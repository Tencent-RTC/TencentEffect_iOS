//
//  ViewController.m
//  Tencent_Effect_Zego
//
//  Created by jasonggao on 2025/11/6.
//

#import "ViewController.h"
#import <YTCommonXMagic/TELicenseCheck.h>

static NSString *const kTELicenseURL = @"please set your license url";
static NSString *const kTELicenseKey = @"please set your license key";

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [TELicenseCheck setTELicense:kTELicenseURL key:kTELicenseKey completion:^(NSInteger authresult, NSString * _Nullable errorMsg) {
        NSLog(@"打印鉴权结果  %ld ",authresult);
    }];
}


@end
