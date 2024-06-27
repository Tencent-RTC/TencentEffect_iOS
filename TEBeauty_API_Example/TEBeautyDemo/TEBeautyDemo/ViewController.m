//
//  ViewController.m
//  TEBeautyDemo
//
//  Created by chavezchen on 2024/4/24.
//

#import "ViewController.h"
#import "TECameraViewController.h"
#import "YTCommonXMagic/TELicenseCheck.h"
#import "RadioButton.h"
#import "Masonry/Masonry.h"

@interface ViewController ()<RadioButtonDelegate>

@property (nonatomic, weak) IBOutlet UIButton *openCamera;
@property (nonatomic, strong) RadioButton *defeaultBtn;
@property (nonatomic, strong) RadioButton *highPerformanceBtn;
@property (nonatomic, assign) BOOL highPerformance;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
    
}

-(void)initUI{
    [self.view addSubview:self.defeaultBtn];
    [self.defeaultBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(_openCamera.mas_left);
        make.top.mas_equalTo(_openCamera.mas_bottom).mas_offset(20);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(30);
    }];
    [self.view addSubview:self.highPerformanceBtn];
    [self.highPerformanceBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(_openCamera.mas_left);
        make.top.mas_equalTo(_defeaultBtn.mas_bottom).mas_offset(5);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(30);
    }];
    
    [RadioButton addObserver:self forGroupId:@"model"];
}

-(RadioButton *)defeaultBtn{
    if (!_defeaultBtn) {
        _defeaultBtn = [[RadioButton alloc] initWithFrame:CGRectMake(20, 20, 160, 25) groupId:@"model" index:0];
        _defeaultBtn.backgroundColor = [UIColor grayColor];
        [_defeaultBtn setText:@"普通模式"];
        [_defeaultBtn setSelected:YES];
        [_defeaultBtn setFont:[UIFont systemFontOfSize:18]];
        [_defeaultBtn setTextColor:[UIColor whiteColor]];
    }
    return _defeaultBtn;
}

-(RadioButton *)highPerformanceBtn{
    if (!_highPerformanceBtn) {
        _highPerformanceBtn = [[RadioButton alloc] initWithFrame:CGRectMake(20, 20, 160, 25) groupId:@"model" index:1];
        _highPerformanceBtn.backgroundColor = [UIColor grayColor];
        [_highPerformanceBtn setText:@"高性能模式"];
        [_highPerformanceBtn setFont:[UIFont systemFontOfSize:18]];
        [_highPerformanceBtn setTextColor:[UIColor whiteColor]];
    }
    return _highPerformanceBtn;
}


- (void)radioButtonSelected:(RadioButton *)sender {
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[RadioButton class]] && subview.tag != sender.tag) {
            [(RadioButton *)subview setSelected:NO];
        }
    }
    [sender setSelected:YES];
}


- (IBAction)authAndPush:(UIButton *)sender {
    [TELicenseCheck setTELicense:<#license url#> key:<#license key#> completion:^(NSInteger authresult, NSString * _Nullable errorMsg) {
        if (authresult == 0) {
            TECameraViewController *cameraVC = [[TECameraViewController alloc] init];
            cameraVC.isEnableHighPerformance = self->_highPerformance;
            [self.navigationController pushViewController:cameraVC animated:YES];
        }
    }];
    
}

#pragma mark - RadioButtonDelegate

- (void)ir_RadioButtonSelectedAtIndex:(NSUInteger)index inGroup:(NSString *)groupId{
    if (index == 0) {
        _highPerformance = NO;
    }else{
        _highPerformance = YES;
    }
}


@end
