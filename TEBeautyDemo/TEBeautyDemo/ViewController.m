//
//  ViewController.m
//  TEBeautyDemo
//
//  Created by chavezchen on 2024/4/24.
//

#import "ViewController.h"
#import "TEBeautyKit.h"
#import "TECameraViewController.h"

static NSString *const kTELicenseURL = @"please set your license url";
static NSString *const kTELicenseKey = @"please set your license key";

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
        dispatch_async(dispatch_get_main_queue(), ^{
            if (authresult == 0) {
                TECameraViewController *cameraVC = [[TECameraViewController alloc] init];
                cameraVC.modalPresentationStyle = UIModalPresentationFullScreen;
                [self presentViewController:cameraVC animated:YES completion:nil];
            }
        });
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
