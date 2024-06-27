//
//  ViewController.m
//  TEBeautyDemo
//
//  Created by chavezchen on 2024/4/24.
//

#import "ViewController.h"
#import "TEBeautyKit.h"
#import "TECameraViewController.h"
#import "TEBeautyKit/TEDownloader.h"

@interface ViewController ()

@property (nonatomic, strong)UILabel *toastView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.toastView];
    // Do any additional setup after loading the view.
    
}

-(UILabel *)toastView{
    if (!_toastView) {
        _toastView = [[UILabel alloc] init];
        _toastView.frame = CGRectMake(0, 200, self.view.frame.size.width, 20);
        _toastView.textColor = [UIColor blackColor];
        _toastView.textAlignment = NSTextAlignmentCenter;
        _toastView.font = [UIFont systemFontOfSize:14];
    }
    _toastView.hidden = YES;
    return _toastView;
}


- (IBAction)downloadBeautyModelRes:(id)sender {
    
    NSArray *arrays = @[
        @"https://host/LightCore.bundle.zip",
        @"https://host/Light3DPlugin.bundle.zip",
        @"https://host/LightBodyPlugin.bundle.zip",
        @"https://host/LightHandPlugin.bundle.zip",
        @"https://host/LightSegmentPlugin.bundle.zip"
    ];
    __block int count = 0;
    NSUInteger length = arrays.count;
    for (int i = 0; i < length; i++) {
        [[TEDownloader shardManager] download:arrays[i] destinationURL:@"ModelRes" progressBlock:^(CGFloat progress) {
            NSLog(@"下载中");
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_toastView.text = @"下载中";
                self->_toastView.hidden = NO;
            });
        } successBlock:^(BOOL success, NSString *downloadFileLocalPath) {
            dispatch_async(dispatch_get_main_queue(), ^{
                count ++;
                if(count == length){
                    self->_toastView.hidden = YES;
                }
            });
        }];
    }
    
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
