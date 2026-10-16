//
//  ViewController.m
//  TEBeautyDemo
//
//  Created by chavezchen on 2024/4/24.
//

#import "ViewController.h"
#import "TECameraViewController.h"
#import "Masonry.h"
#import "TEBeautyKit.h"
#import "TEUIConfig.h"
#import "TEDownloader.h"

static NSString *const kTELiceseUrl = @"please set your license url";
static NSString *const kTELiceseKey = @"please set your license key";

/// 资源包下载地址（测试），zip 内可包含多个 bundle，或者分开下载都可以，最终存放在同一个目录下即可
static NSString * const kModelResZipURL = @"https://xxxx.zip";
/// 资源目录名，可自行决定
static NSString * const kModelResDirName = @"ModelRes";

@interface ViewController ()

@property (nonatomic, strong) UILabel *statusLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildUI];
}

#pragma mark - UI

- (void)buildUI {
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"TEBeautyKit 动态下载 Demo";

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"资源未下载";
    self.statusLabel.textColor = [UIColor darkGrayColor];
    self.statusLabel.font = [UIFont systemFontOfSize:14];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    [self.view addSubview:self.statusLabel];

    UIButton *downloadButton = [self buttonWithTitle:@"下载美颜资源" action:@selector(onDownloadClick)];
    UIButton *cameraButton = [self buttonWithTitle:@"鉴权并进入美颜" action:@selector(onAuthAndOpenCameraClick)];
    [self.view addSubview:downloadButton];
    [self.view addSubview:cameraButton];

    [downloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).offset(-30);
        make.left.equalTo(self.view).offset(30);
        make.right.equalTo(self.view).offset(-30);
        make.height.mas_equalTo(44);
    }];
    [cameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(downloadButton);
        make.top.equalTo(downloadButton.mas_bottom).offset(20);
        make.height.mas_equalTo(44);
    }];
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(30);
        make.right.equalTo(self.view).offset(-30);
        make.bottom.equalTo(downloadButton.mas_top).offset(-40);
    }];
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    button.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    button.layer.cornerRadius = 8;
    button.layer.masksToBounds = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)updateStatus:(NSString *)status {
    self.statusLabel.text = status;
    NSLog(@"[TEBeautyDemo] %@", status);
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 资源路径

/// 本 demo 选择的资源根目录
- (NSString *)tencentEffectDirectory {
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [documents stringByAppendingPathComponent:@"TencentEffect"];
}

- (NSString *)modelResDirectory {
    return [[self tencentEffectDirectory] stringByAppendingPathComponent:kModelResDirName];
}

/// 资源是否已就绪
- (BOOL)isResourceReady {
    NSArray<NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self modelResDirectory] error:nil];
    return contents.count > 0;
}

/// 把资源目录告知 SDK
- (void)applyLightCoreBundlePath {
    [[TEUIConfig shareInstance] setLightCoreBundlePath:[self modelResDirectory]];
}

#pragma mark - 下载资源

/// 内置下载工具下载并解压资源；也可自行下载，放到任意目录后调用 setLightCoreBundlePath: 指向该目录
- (void)onDownloadClick {
    [self updateStatus:@"下载中…"];
    __weak typeof(self) weakSelf = self;
    [[TEDownloader shardManager] download:kModelResZipURL destinationURL:kModelResDirName progressBlock:^(CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateStatus:[NSString stringWithFormat:@"下载中 %.0f%%", progress * 100]];
        });
    } successBlock:^(BOOL success, NSString *downloadFileLocalPath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [weakSelf applyLightCoreBundlePath];
                [weakSelf updateStatus:@"下载完成，资源已就绪"];
            } else {
                [weakSelf updateStatus:@"下载失败"];
            }
        });
    }];
}

#pragma mark - 鉴权并进入美颜

- (void)onAuthAndOpenCameraClick {
    if (![self isResourceReady]) {
        [self showAlert:@"请先完成资源下载"];
        return;
    }
    [self applyLightCoreBundlePath];

    __weak typeof(self) weakSelf = self;
    [TEBeautyKit setTELicense:kTELiceseUrl key:kTELiceseKey completion:^(NSInteger authresult, NSString * _Nullable errorMsg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (authresult == 0) {
                TECameraViewController *cameraViewController = [[TECameraViewController alloc] init];
                [weakSelf.navigationController pushViewController:cameraViewController animated:YES];
            } else {
                [weakSelf updateStatus:[NSString stringWithFormat:@"鉴权失败(%ld)：%@", (long)authresult, errorMsg ?: @""]];
                [weakSelf showAlert:[NSString stringWithFormat:@"鉴权失败(%ld)：%@", (long)authresult, errorMsg ?: @"请检查 license 配置"]];
            }
        });
    }];
}

@end
