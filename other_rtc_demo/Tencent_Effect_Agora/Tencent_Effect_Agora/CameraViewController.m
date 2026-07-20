//
//  CameraViewController.m
//  Tencent_Effect_Agora
//
//  Created by jasonggao on 2026/6/29.
//

#import "CameraViewController.h"
#import <AgoraRtcKit/AgoraRtcKit.h>
#import <Masonry/Masonry.h>
#import <TEBeautyKit/TEUIConfig.h>
#import <TEBeautyKit/TEPanelView.h>
#import "TEAgoraAdapter.h"
#import "BeautyParamConfig.h"

static NSString *const kAgoraAppID = @"please set your agora appid";

@interface CameraViewController ()<AgoraRtcEngineDelegate,AgoraVideoFrameDelegate,TEPanelViewDelegate>
@property (nonatomic, strong) AgoraRtcEngineKit *agoraEngine;
@property (nonatomic, strong) TEAgoraAdapter *agoraAdapter;
@property (nonatomic, strong) TEPanelView *tePanelView;
@property (nonatomic, strong) TEBeautyKit *teBeautyKit;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *switchButton;
@property (nonatomic, assign) BOOL isFrontCamera;

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //初始化AgoraEngine
    [self initializeAgoraEngine];
    [self setupLocalVideo];
    //设置面板
    [self initBeautyJson];
    // 设置语言
    [self configLanguage];
    //ui
    [self initUI];
    
    self.isFrontCamera = YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.view bringSubviewToFront:self.tePanelView];
    [self.view bringSubviewToFront:self.backBtn];
    [self.view bringSubviewToFront:self.switchButton];
    [self.backBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.offset(self.view.safeAreaInsets.top + 15);
    }];
}

- (void)initializeAgoraEngine {
    AgoraRtcEngineConfig *config = [[AgoraRtcEngineConfig alloc] init];
    config.appId = kAgoraAppID;
    self.agoraEngine = [AgoraRtcEngineKit sharedEngineWithConfig:config delegate:self];
    [self.agoraEngine setVideoFrameDelegate:self];
}

- (void)setupLocalVideo {
    [self.agoraEngine enableVideo];
    [self.agoraEngine startPreview];
    AgoraRtcVideoCanvas *videoCanvas = [[AgoraRtcVideoCanvas alloc] init];
    videoCanvas.uid = 123333;
    videoCanvas.renderMode = AgoraVideoRenderModeHidden;
    videoCanvas.view = self.view;
    [self.agoraEngine setupLocalVideo:videoCanvas];
    
    __weak __typeof(self)weakSelf = self;
    [self.agoraAdapter bind:self.agoraEngine onCreatedXmagicApi:^(XMagic * _Nullable xmagicApi) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (xmagicApi) {
            strongSelf.teBeautyKit.xmagicApi = xmagicApi;
            [strongSelf.teBeautyKit setLogLevel:YT_SDK_ERROR_LEVEL];
            strongSelf.tePanelView.teBeautyKit = strongSelf.teBeautyKit;
            [strongSelf.tePanelView setDefaultBeauty];
            //获取上次存储的，然后进行设置
            NSString *str = [[BeautyParamConfig sharedInstance] getLastBeautyParam];
            if (str != nil) {
                [strongSelf setLastBeauty:str];
            }
        } else {
            NSLog(@"XMagic 对象创建失败");
        }
    } onDestroyXmagicApi:^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf.teBeautyKit onDestroy];
        strongSelf.teBeautyKit = nil;
        NSLog(@"XMagic 对象已销毁");
    }];
}

- (void)setLastBeauty:(NSString *)lastParamList{
    NSData *jsonData = [lastParamList dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData == nil) {
        return;
    }
    
    NSError *error;
    NSMutableDictionary *beautyDics = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    NSMutableArray<TESDKParam *>*effectList = [NSMutableArray array];
    for (NSDictionary *dic in beautyDics) {
        TESDKParam *param = [[TESDKParam alloc] init];
        [param setValuesForKeysWithDictionary:dic];
        [effectList addObject:param];
    }
    [self.teBeautyKit setEffectList:effectList];
}

- (void)initUI {
    self.backBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [self.backBtn addTarget:self action:@selector(backBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backBtn];
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(15);
        make.top.offset(self.view.safeAreaInsets.top + 15);
        make.width.height.mas_equalTo(40);
    }];

    self.switchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.switchButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.switchButton setTitle:@"切换" forState:UIControlStateNormal];
    [self.switchButton addTarget:self action:@selector(switchButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.switchButton];
    [self.switchButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backBtn);
        make.right.equalTo(self.view).offset(-15);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(32);
    }];
    
    //美颜选项界面
    [self.view addSubview:self.tePanelView];
    [self.tePanelView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(self.view);
        make.height.mas_equalTo(230);
    }];
    self.tePanelView.hidden = NO;
}

- (void)initBeautyJson {
    // 套餐文件清单
    // S1_07 : beauty, beauty_image, beauty_shape, beauty_makeup, lut,  motion_2d, motion_3d, makeup, light_makeup, motion_gesture, segmentation, beauty_body
    // S1_04 : beauty, beauty_image, beauty_shape, beauty_makeup, lut,  motion_2d, motion_3d, makeup, light_makeup, motion_gesture, segmentation
    // S1_03 : beauty, beauty_image, beauty_shape, beauty_makeup, lut,  motion_2d, motion_3d, makeup, light_makeup, segmentation
    // S1_02 : beauty, beauty_image, beauty_shape, beauty_makeup, lut,  motion_2d, motion_3d, makeup, light_makeup, motion_gesture
    // S1_01 : beauty, beauty_image, beauty_shape, beauty_makeup, lut,  motion_2d, motion_3d, makeup, light_makeup
    // S1_00 : beauty, beauty_image, beauty_shape, beauty_makeup, lut
    // A1_06 : beauty, beauty_image, beauty_base_shape, lut, motion_2d, makeup
    // A1_05 : beauty, beauty_image, beauty_base_shape, lut, motion_2d, segmentation
    // A1_04 : beauty, beauty_image, beauty_general_shape, lut
    // A1_03 : beauty, beauty_image, beauty_general_shape, lut, motion_2d
    // A1_02 : beauty, beauty_image, beauty_base_shape, lut, motion_2d
    // A1_01 : beauty, beauty_image, beauty_base_shape, lut
    // A1_00 : beauty, lut
    
    // 配置面板UI，以S1_07为例，beauty_template_ios是自定义模板，不包含在套餐内
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *beautyJsonPath = [bundle pathForResource:@"beauty" ofType:@"json"];//美颜
    /* 适配多语言示例底代码，每种语言对应一个json文件
     * 如：beauty_ja(日语)  beauty_ko(韩语)
     * 以下面板配置是按照S1-07套餐配置，您可以根据自己的套餐自行删减
     */
    if ([self configLanguage]) {
        NSString *beautyName = [NSString stringWithFormat:@"beauty_%@",[self configLanguage]];
        beautyJsonPath = [bundle pathForResource:beautyName ofType:@"json"];
    }
    NSString *beautyTemplateJsonPath = [bundle pathForResource:@"beauty_template" ofType:@"json"];//模板
    NSString *beautyShapeJsonPath = [bundle pathForResource:@"beauty_shape" ofType:@"json"];//高级美型
    NSString *beautyImageJsonPath = [bundle pathForResource:@"beauty_image" ofType:@"json"];//画质调整
    NSString *beautyMakeupJsonPath = [bundle pathForResource:@"beauty_makeup" ofType:@"json"];//单点美妆
    NSString *lightMakeupJsonPath = [bundle pathForResource:@"light_makeup" ofType:@"json"];//轻美妆
    NSString *lutJsonPath = [bundle pathForResource:@"lut" ofType:@"json"];//滤镜
    NSString *beautyBodyJsonPath = [bundle pathForResource:@"beauty_body" ofType:@"json"];//美体
    NSString *motion2dJsonPath = [bundle pathForResource:@"motion_2d" ofType:@"json"];//2d贴纸
    NSString *motion3dJsonPath = [bundle pathForResource:@"motion_3d" ofType:@"json"];//3d贴纸
    NSString *motionHandJsonPath = [bundle pathForResource:@"motion_gesture" ofType:@"json"];//手势贴纸
    NSString *makeupJsonPath = [bundle pathForResource:@"makeup" ofType:@"json"];//风格整妆
    NSString *segmentationJsonPath = [bundle pathForResource:@"segmentation" ofType:@"json"];//虚拟背景
    
    NSMutableArray *resArray = [[NSMutableArray alloc] init];
    [resArray addObject:@{TEUI_BEAUTY_TEMPLATE : beautyTemplateJsonPath}];
    [resArray addObject:@{TEUI_BEAUTY : beautyJsonPath}];
    [resArray addObject:@{TEUI_BEAUTY_SHAPE : beautyShapeJsonPath}];
    [resArray addObject:@{TEUI_BEAUTY_IMAGE : beautyImageJsonPath}];
    [resArray addObject:@{TEUI_BEAUTY_MAKEUP : beautyMakeupJsonPath}];
    [resArray addObject:@{TEUI_LIGHT_MAKEUP : lightMakeupJsonPath}];
    [resArray addObject:@{TEUI_LUT : lutJsonPath}];
    [resArray addObject:@{TEUI_BEAUTY_BODY : beautyBodyJsonPath}];
    [resArray addObject:@{TEUI_MOTION_2D : motion2dJsonPath}];
    [resArray addObject:@{TEUI_MOTION_3D : motion3dJsonPath}];
    [resArray addObject:@{TEUI_MOTION_GESTURE : motionHandJsonPath}];
    [resArray addObject:@{TEUI_MAKEUP : makeupJsonPath}];
    [resArray addObject:@{TEUI_SEGMENTATION : segmentationJsonPath}];
    
    [[TEUIConfig shareInstance] setTEPanelViewResources:resArray];
}

- (NSString *)configLanguage {
    //适配多语言示例底代码
    NSString *language = [[NSLocale preferredLanguages] firstObject];
    if ([language hasPrefix:@"ja"]) {
        // 日语
//        [[TEUIConfig shareInstance] setUseDisplayName:YES];
        return @"ja";
    } else if ([language hasPrefix:@"ko"]) {
        // 韩语
//        [[TEUIConfig shareInstance] setUseDisplayName:YES];
        return @"ko";
    } else {
        // 其他语言，默认使用 displayName
//        [[TEUIConfig shareInstance] setUseDisplayName:YES];
        return nil;
    }
}

// 切换摄像头
- (void)switchButtonClick {
    [self.agoraEngine switchCamera];
    self.isFrontCamera = !self.isFrontCamera;
}

- (void)backBtnClick {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    //获取使用的美颜属性，并保存在BeautyParamConfig 中
    NSString *last = [self.teBeautyKit exportInUseSDKParam];
    if(last != nil) {
        [[BeautyParamConfig sharedInstance] setLastBeautyParam:last];
    }
    if (self.teBeautyKit) {
        [self.teBeautyKit onDestroy];
    }
    [self.agoraEngine stopPreview];
    [self.agoraEngine stopAudioRecording];
}

#pragma mark - Lazy
- (TEPanelView *)tePanelView {
    if (!_tePanelView) {
        _tePanelView = [[TEPanelView alloc] init];
        _tePanelView.delegate = self;
    }
    return _tePanelView;
}

- (TEBeautyKit *)teBeautyKit {
    if (!_teBeautyKit) {
        _teBeautyKit= [[TEBeautyKit alloc] init];
    }
    return _teBeautyKit;
}

- (TEAgoraAdapter *)agoraAdapter {
    if (!_agoraAdapter) {
        _agoraAdapter = [[TEAgoraAdapter alloc] init];
    }
    return  _agoraAdapter;
}

#pragma mark TEPanelViewDelegate
- (void)showBeautyChanged:(BOOL)open {
    self.agoraAdapter.enableBeauty = open;
}

#pragma mark - AgoraVideoFrameDelegate
- (BOOL)onCaptureVideoFrame:(AgoraOutputVideoFrame * _Nonnull)videoFrame sourceType:(AgoraVideoSourceType)sourceType {
    return [self.agoraAdapter onCaptureVideoFrame:videoFrame sourceType:sourceType];
}

- (AgoraVideoFrameProcessMode)getVideoFrameProcessMode {
    return AgoraVideoFrameProcessModeReadWrite;
}

- (AgoraVideoFormat)getVideoFormatPreference {
    return AgoraVideoFormatCVPixelBGRA;
}

- (AgoraVideoFramePosition)getObservedFramePosition {
    return AgoraVideoFramePositionPostCapture;
}

@end

