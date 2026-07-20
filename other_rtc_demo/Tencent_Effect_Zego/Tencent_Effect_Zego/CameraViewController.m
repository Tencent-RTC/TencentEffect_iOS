//
//  CameraViewController.m
//  Tencent_Effect_Zego
//
//  Created by jasonggao on 2025/11/10.
//

#import "CameraViewController.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>
#import <TEBeautyKit/TEBeautyKit.h>
#import <TEBeautyKit/TEPanelView.h>
#import <TEBeautyKit/TEUIConfig.h>
#import <Masonry/Masonry.h>
#import "TEZegoAdapter.h"

static int ZegoAppID = 0; // please set your appID
static NSString *const ZegoAppSign = @"please set your appSign";
static NSString *const RoomId_1 = @"test_room_1";
static NSString *const UserId_1 = @"test_user_1";
static NSString *const UserId_2 = @"test_user_2";
static NSString *const Stream_ID = @"test_stream";

@interface CameraViewController ()<ZegoEventHandler, TEPanelViewDelegate>
@property (nonatomic, strong) TEBeautyKit *beautyKit;
@property (nonatomic, strong) TEPanelView *panelView;
@property (nonatomic, strong) TEZegoAdapter *adapter;
@property (nonatomic, assign) BOOL userFrontCamera;
@end

@implementation CameraViewController

- (void)dealloc
{
    [ZegoExpressEngine destroyEngine:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    /// 初始化zego
    [self initZego];
    /// 登入房间
    [self loginRoom];
    /// 初始化XMagic
    [self initUI];
    [self configLanguage];
    [self initXMagic];
    /// 开始推流
    [self startPush];
}

- (void)initZego {
    ZegoEngineProfile *profile = [[ZegoEngineProfile alloc] init];
    profile.appID = ZegoAppID;
    profile.appSign = ZegoAppSign;
    profile.scenario = ZegoScenarioDefault;
    [ZegoExpressEngine createEngineWithProfile:profile eventHandler:self];
    
    self.userFrontCamera = YES;
    [[ZegoExpressEngine sharedEngine] useFrontCamera:self.userFrontCamera];
    
    ZegoVideoConfig *videoConfig = [ZegoVideoConfig configWithPreset:ZegoVideoConfigPreset720P];
    [[ZegoExpressEngine sharedEngine] setVideoConfig:videoConfig];
    [[ZegoExpressEngine sharedEngine] setAppOrientation:UIInterfaceOrientationPortrait];
}

- (void)loginRoom {
    NSString *userId = UserId_1;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        userId = UserId_2;
    }
    ZegoUser *user = [ZegoUser userWithUserID:userId];
    ZegoRoomConfig *roomConfig = [[ZegoRoomConfig alloc] init];
    roomConfig.isUserStatusNotify = YES;
    // 登录房间
    [[ZegoExpressEngine sharedEngine] loginRoom:RoomId_1 user:user config:roomConfig callback:^(int errorCode, NSDictionary * _Nullable extendedData) {
        // (可选回调) 登录房间结果，如果仅关注登录结果，关注此回调即可
        if (errorCode == 0) {
            NSLog(@"房间登录成功");
        } else {
            // 登录失败，请参考 errorCode 说明 /real-time-video-ios-oc/client-sdk/error-code
            NSLog(@"房间登录失败");
        }
    }];
}

- (void)startPush {
    ZegoCanvas *canvas = [[ZegoCanvas alloc] initWithView:self.view];
    /// 这里模拟iPad拉流，另一个端推流
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [[ZegoExpressEngine sharedEngine] startPlayingStream:Stream_ID canvas:canvas];
    } else {
        [[ZegoExpressEngine sharedEngine] startPreview:canvas];
        [[ZegoExpressEngine sharedEngine] startPublishingStream:Stream_ID];
    }
}

- (IBAction)switchCamera:(UIButton *)sender {
    self.userFrontCamera = !self.userFrontCamera;
    [[ZegoExpressEngine sharedEngine] useFrontCamera:self.userFrontCamera];
}

- (IBAction)back:(UIButton *)sender {
    [[ZegoExpressEngine sharedEngine] stopPreview];
    [[ZegoExpressEngine sharedEngine] logoutRoom:RoomId_1];
    [self.adapter unbind];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)initUI {
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
    
    [self.view addSubview:self.panelView];
    [self.panelView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.offset(0);
        make.height.mas_equalTo(230 + self.view.safeAreaInsets.bottom);
    }];
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

- (void)initXMagic {
    __weak typeof(self)weakSelf = self;
    OnCreatedXMagic createBlcok = ^(XMagic *xMagic) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.beautyKit = [[TEBeautyKit alloc] init];
        [strongSelf.beautyKit setXMagicApi:xMagic];
        strongSelf.panelView.teBeautyKit = strongSelf.beautyKit;
        [strongSelf.panelView setDefaultBeauty];
    };
    /// 绑定zego
    [self.adapter bind:[ZegoExpressEngine sharedEngine] onCreatedXMagic:createBlcok onDestroyedXMagic:nil];
}

#pragma mark - Lazy
- (TEPanelView *)panelView {
    if (!_panelView) {
        _panelView = [[TEPanelView alloc] init];
        _panelView.delegate = self;
    }
    return _panelView;
}

- (TEZegoAdapter *)adapter {
    if (!_adapter) {
        _adapter = [[TEZegoAdapter alloc] initWithEffectMode:EFFECT_MODE_NORMAL];
    }
    return _adapter;
}

#pragma mark - TEPanelViewDelegate
- (void)showBeautyChanged:(BOOL)open {
    self.adapter.enableBeauty = open;
}

#pragma mark - ZegoEventHandler
- (void)onEngineStateUpdate:(ZegoEngineState)state {
    NSLog(@"引擎状态 state = %ld", state);
}

- (void)onRoomStateChanged:(ZegoRoomStateChangedReason)reason errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData roomID:(NSString *)roomID {
    NSLog(@"房间状态 reason = %ld, errorCode = %d, extendedData = %@, roomID = %@", reason, errorCode, extendedData, roomID);
}

@end
