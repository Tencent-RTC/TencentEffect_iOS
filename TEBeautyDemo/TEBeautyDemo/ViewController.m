//
//  ViewController.m
//  TEBeautyDemo
//
//  Created by chavezchen on 2024/4/24.
//

#import "ViewController.h"
#import "TEBeautyKit.h"
#import "TECameraViewController.h"

static NSString *const kTELicenseURL = @"";
static NSString *const kTELicenseKey = @"";

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kExportEffectData];
    
}


- (IBAction)authAndPush:(UIButton *)sender {
    
    [TEBeautyKit setTELicense:kTELicenseURL key:kTELicenseKey completion:^(NSInteger authresult, NSString * _Nullable errorMsg) {
        if (authresult == 0) {
            TECameraViewController *cameraVC = [[TECameraViewController alloc] init];
            [self.navigationController pushViewController:cameraVC animated:YES];
        }
    }];
    
}

#pragma mark - Rotation
- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
