//
//  ViewController.m
//  TEBeautyDemo
//
//  Created by chavezchen on 2024/4/24.
//

#import "ViewController.h"
#import "TEBeautyKit.h"
#import "TECameraViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}


- (IBAction)authAndPush:(UIButton *)sender {
    
    [TEBeautyKit setTELicense:<#license url#> key:<#license key#> completion:^(NSInteger authresult, NSString * _Nullable errorMsg) {
        if (authresult == 0) {
            TECameraViewController *cameraVC = [[TECameraViewController alloc] init];
            [self.navigationController pushViewController:cameraVC animated:YES];
        }
    }];
    
}

@end
