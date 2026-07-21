//
//  ViewController.m
//  AgoraBeautyDemo
//
//  Created by tao yue on 2025/3/13.
//

#import "ViewController.h"
#import "CameraViewController.h"
#import <Masonry/Masonry.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *cameraBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [cameraBtn setTitle:@"enter Agora" forState:UIControlStateNormal];
    [cameraBtn addTarget:self action:@selector(enterAgoraClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraBtn];
    [cameraBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
}

- (void)enterAgoraClick {
    CameraViewController *cameraVC = [[CameraViewController alloc] init];
    cameraVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:cameraVC animated:YES completion:nil];
}

@end
