//
//  CameraViewController.m
//  Tencent_Effect_Byte
//
//  Created by jasonggao on 2025/11/10.
//

#import "CameraViewController.h"
#import <VolcEngineRTC/VolcEngineRTC.h>
#import <TEBeautyKit/TEBeautyKit.h>
#import <TEBeautyKit/TEPanelView.h>
#import <TEBeautyKit/TEUIConfig.h>
#import <XMagic/TEImageTransform.h>
#import <Masonry/Masonry.h>

static NSString *const VolcAppID = @"please set your appID"; // please set your appID
static NSString *const VolcAppKey = @"please set your appKey";

@interface CameraViewController ()<TEPanelViewDelegate, ByteRTCEngineDelegate, ByteRTCVideoProcessorDelegate>
@property (nonatomic, strong) TEBeautyKit *teBeautyKit;
@property (nonatomic, strong) TEPanelView *tePanelView;
@property (nonatomic, strong) TEImageTransform *imageTransform;
@property (nonatomic, strong) ByteRTCEngine *rtcEngine;
@property (nonatomic, strong) ByteRTCRoom *rtcRoom;
@property (nonatomic, assign) BOOL userFrontCamera;
@property (nonatomic, weak) IBOutlet UIButton *backBtn;
@property (nonatomic, weak) IBOutlet UIButton *cameraSwitchBtn;
@property (nonatomic, weak) IBOutlet UIButton *startCaptureBtn;
@property (nonatomic, weak) IBOutlet UIButton *stopCaptureBtn;
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    /// 初始化VolcEngineRTC
    [self initRTC];
    /// 初始化XMagic
    [self initUI];
    /// 配置多语言
    [self configLanguage];
    /// 初始化美颜BeatyKit
    [self initBeatyKit];
    // 初始化 UI 方向
    [self updateInterfaceOrientation];
}

- (void)viewDidLayoutSubviews {
    [self.view bringSubviewToFront:self.backBtn];
    [self.view bringSubviewToFront:self.cameraSwitchBtn];
    [self.view bringSubviewToFront:self.startCaptureBtn];
    [self.view bringSubviewToFront:self.stopCaptureBtn];
    [self.view bringSubviewToFront:self.tePanelView];
}

- (void)initRTC {
    //创建rtcEngine
    ByteRTCEngineConfig *engineConfig = [[ByteRTCEngineConfig alloc] init];
    engineConfig.appID = VolcAppID;
    self.rtcEngine = [ByteRTCEngine createRTCEngine:engineConfig delegate:self];
}

- (IBAction)switchCamera:(UIButton *)sender {
    self.userFrontCamera = !self.userFrontCamera;
    [self.rtcEngine switchCamera:self.userFrontCamera?ByteRTCCameraIDFront:ByteRTCCameraIDBack];
 }

- (IBAction)back:(UIButton *)sender {
    //停止采集
    [self.rtcEngine stopVideoCapture];
    //销毁beautyKit
    [self.teBeautyKit onDestroy];
    
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
    
    /* 适配多语言示例底代码，每种语言对应一个json文件
     * 如：beauty_zh_hant （繁体中文）
     * 以下面板配置是按照S1-07套餐配置，您可以根据自己的套餐自行删减
     */
    NSString *beautyJsonPath = [self jsonPathWithName:@"beauty"];//美颜
    NSString *beautyTemplateJsonPath = [self jsonPathWithName:@"beauty_template"];//模板
    NSString *beautyShapeJsonPath = [self jsonPathWithName:@"beauty_shape"];//高级美型
    NSString *beautyImageJsonPath = [self jsonPathWithName:@"beauty_image"];//画质调整
    NSString *beautyMakeupJsonPath = [self jsonPathWithName:@"beauty_makeup"];//单点美妆
    NSString *lightMakeupJsonPath = [self jsonPathWithName:@"light_makeup"];//轻美妆
    NSString *lutJsonPath = [self jsonPathWithName:@"lut"];//滤镜
    NSString *beautyBodyJsonPath = [self jsonPathWithName:@"beauty_body"];//美体
    NSString *motion2dJsonPath = [self jsonPathWithName:@"motion_2d"];//2d贴纸
    NSString *motion3dJsonPath = [self jsonPathWithName:@"motion_3d"];//3d贴纸
    NSString *motionHandJsonPath = [self jsonPathWithName:@"motion_gesture"];//手势贴纸
    NSString *makeupJsonPath = [self jsonPathWithName:@"makeup"];//风格整妆
    NSString *segmentationJsonPath = [self jsonPathWithName:@"segmentation"];//虚拟背景
    
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

- (NSString *)jsonPathWithName:(NSString *)name {
    NSString *curLanguage = [self configLanguage];
    NSString *jsonName = [NSString stringWithFormat:@"%@%@", name, curLanguage];
    return [[NSBundle mainBundle] pathForResource:jsonName ofType:@"json"];
}

- (NSString *)configLanguage {
    //适配多语言示例底代码
    NSString *language = [[NSLocale preferredLanguages] firstObject];
    if ([language hasPrefix:@"zh_hant"]) {
        // 繁体中文
        [[TEUIConfig shareInstance] setUseDisplayName:YES];
        return @"_zh_hant";
    }
    return @"";
}

- (void)initBeatyKit {
    __weak typeof(self)weakSelf = self;
    [TEBeautyKit createXMagic:EFFECT_MODE_PRO onInitListener:^(TEBeautyKit * _Nullable beautyKit) {
        __weak typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.teBeautyKit = beautyKit;
        strongSelf.tePanelView.teBeautyKit = strongSelf.teBeautyKit;
        [strongSelf.tePanelView setDefaultBeauty];
    }];
}

#pragma mark - Actions
- (IBAction)onStartCaptureTapped:(id)sender {
    //设置本地画面
    ByteRTCVideoCanvas *canvas = [[ByteRTCVideoCanvas alloc] init];
    canvas.view = self.view;
    canvas.renderMode = ByteRTCRenderModeHidden;
    [self.rtcEngine setLocalVideoCanvas:canvas];
    
    ByteRTCVideoCaptureConfig *videoConfig = [[ByteRTCVideoCaptureConfig alloc] init];
    videoConfig.preference = ByteRTCVideoCapturePreferenceMannal;
    videoConfig.videoSize = CGSizeMake(720, 1280);
    videoConfig.frameRate = 30;
    [self.rtcEngine setVideoCaptureConfig:videoConfig];
    
    //开启摄像头
    [self.rtcEngine startVideoCapture];

    
    //设置本地视频前处理
    ByteRTCVideoPreprocessorConfig *config = [[ByteRTCVideoPreprocessorConfig alloc] init];
    //设置Unknown在iOS上默认输出是nv12
    config.requiredPixelFormat = ByteRTCVideoPixelFormatUnknown;
    [self.rtcEngine registerLocalVideoProcessor:self withConfig:config];
}

- (IBAction)onStopCaptureTapped:(id)sender {
    //清空本地画面
    [self.rtcEngine setLocalVideoCanvas:nil];
    //关闭摄像头
    [self.rtcEngine stopVideoCapture];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // 立即更新方向，让图像旋转尽快响应
    [self updateInterfaceOrientation];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // 更新 tePanelView 的高度约束
        CGFloat panelHeight = 230 + self.view.safeAreaInsets.bottom;
        [self.tePanelView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(panelHeight);
        }];
        [self.view layoutIfNeeded];
    } completion:nil];
}

/// 更新当前 UI 方向
- (void)updateInterfaceOrientation {
    UIInterfaceOrientation newOrientation;
    if (@available(iOS 13.0, *)) {
        UIWindowScene *windowScene = (UIWindowScene *)[UIApplication sharedApplication].connectedScenes.anyObject;
        newOrientation = windowScene.interfaceOrientation;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        newOrientation = [UIApplication sharedApplication].statusBarOrientation;
#pragma clang diagnostic pop
    }
    
    // 如果转到倒立方向，不更新给 SDK 的方向（保持之前的方向）
    if (newOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        return;
    }
    
    self.interfaceOrientation = newOrientation;
}

- (int)covertSDKOrientation {
    int degrees = 0;
    
    if (self.userFrontCamera) {
        BOOL isMirrored = NO;
        switch (self.interfaceOrientation) {
            case UIInterfaceOrientationPortrait:
            {
                if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown) {
                    degrees = isMirrored ? 270 : 90;
                } else {
                    degrees = isMirrored ? 90 : 270;
                }
            }
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                degrees = isMirrored ? 270 : 90;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                //摄像头朝右
                degrees = 0;
                break;
            case UIInterfaceOrientationLandscapeRight:
                //摄像头朝左
                degrees = 180;
                break;
            default:
                break;
        }
    } else {
        // 后置摄像头
        switch (self.interfaceOrientation) {
            case UIInterfaceOrientationPortrait:
            {
                if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown) {
                    degrees = 270;
                } else {
                    degrees = 90;
                }
            }
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                degrees = 90;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                //摄像头朝右
                degrees = 0;
                break;
            case UIInterfaceOrientationLandscapeRight:
                //摄像头朝左
                degrees = 180;
                break;
            default:
                break;
        }
    }
    return degrees;
}

- (YtLightDeviceCameraOrientation)orientationFromDegrees:(int)degrees {
    switch (degrees) {
        case 90:  return YtLightCameraRotation90;
        case 180: return YtLightCameraRotation180;
        case 270: return YtLightCameraRotation270;
        default:  return YtLightCameraRotation0;
    }
}

#pragma mark - Lazy
- (TEPanelView *)panelView {
    if (!_tePanelView) {
        _tePanelView = [[TEPanelView alloc] init];
        _tePanelView.delegate = self;
    }
    return _tePanelView;
}


#pragma mark - TEPanelViewDelegate
- (void)showBeautyChanged:(BOOL)open {
//    self.adapter.enableBeauty = open;
}

#pragma mark - ByteRTCVideoProcessorDelegate
- (id<ByteRTCVideoFrame> _Nullable)processVideoFrame:(id<ByteRTCVideoFrame> _Nonnull)srcFrame {
    [srcFrame addRef];

    CVPixelBufferRef pixelBuf = srcFrame.cvpixelbuffer;
    int width = (int)CVPixelBufferGetWidth(pixelBuf);
    int height = (int)CVPixelBufferGetHeight(pixelBuf);

    int degrees = [self covertSDKOrientation];
    YtLightDeviceCameraOrientation orientation = [self orientationFromDegrees:degrees];
    [self.teBeautyKit setImageOrientation:YtLightCameraRotation0];
    YTProcessOutput *output = [self.teBeautyKit processPixelData:pixelBuf pixelDataWidth:width pixelDataHeight:height withOrigin:YtLightImageOriginTopLeft withOrientation:orientation];
    if (output.pixelData.data) {
        if (!self.imageTransform) {
            EAGLContext *glContext = [self.teBeautyKit getCurrentGlContext];
            self.imageTransform = [[TEImageTransform alloc] initWithEAGLContext:glContext];
        }
        // 把 BGRA output 旋转回原始方向
        CVPixelBufferRef bgraBuffer = output.pixelData.data;
        if (degrees != 0) {
            int reverseDegrees = (360 - degrees) % 360;
            YtLightDeviceCameraOrientation reverseOrientation = [self orientationFromDegrees:reverseDegrees];
            bgraBuffer = [self.imageTransform convertBuffer:bgraBuffer
                                                     width:width
                                                    height:height
                                                   rotaion:reverseOrientation
                                                      flip:TEFlipTypeNo];
        }
        //  将 BGRA 转回 NV12 写入 srcFrame
        [self.imageTransform transformCVPixelBufferToOutBuffer:bgraBuffer
                                                 outputFormat:TE_NV12V
                                               outPixelBuffer:pixelBuf];
    }

    return srcFrame;
}

@end
