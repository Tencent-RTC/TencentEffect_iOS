//
//  TECameraViewController.m
//  TEBeautyDemo
//
//  Created by chavezchen on 2024/4/24.
//

#import "TECameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "Masonry.h"
#import "TEBeautyKit.h"
#import "TEUIConfig.h"
#import "TEPanelView.h"
#import "TCEVideoCapture.h"
#import "TEPreviewView.h"

@interface TECameraViewController () <TCEVideoCaptureDelegate, TEPanelViewDelegate>

@property (nonatomic, strong) TEPreviewView *previewView;
@property (nonatomic, strong) TCEVideoCapture *videoCapture;
@property (nonatomic, strong) TEBeautyKit *teBeautyKit;
@property (nonatomic, strong) TEPanelView *tePanelView;
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

@end

@implementation TECameraViewController

- (void)dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    if (self.teBeautyKit) {
        [self.teBeautyKit onDestroy];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // 配置面板
    [self initBeautyJson];
    // UI
    [self buildUI];
    // 初始化SDK
    [self initSDK];

    // 请求摄像头权限
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            [self.videoCapture startRunning];
        }
    }];

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [self updateInterfaceOrientation];
}

- (void)initBeautyJson {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *beautyTemplateJsonPath = [bundle pathForResource:@"beauty_template_ios" ofType:@"json"];
    NSString *beautyJsonPath = [bundle pathForResource:@"beauty" ofType:@"json"];
    NSString *beautyShapeJsonPath = [bundle pathForResource:@"beauty_shape" ofType:@"json"];
    NSString *beautyImageJsonPath = [bundle pathForResource:@"beauty_image" ofType:@"json"];
    NSString *beautyMakeupJsonPath = [bundle pathForResource:@"beauty_makeup" ofType:@"json"];
    NSString *lightMakeupJsonPath = [bundle pathForResource:@"light_makeup" ofType:@"json"];
    NSString *lutJsonPath = [bundle pathForResource:@"lut" ofType:@"json"];
    NSString *beautyBodyJsonPath = [bundle pathForResource:@"beauty_body" ofType:@"json"];
    NSString *motion2dJsonPath = [bundle pathForResource:@"motion_2d" ofType:@"json"];
    NSString *motion3dJsonPath = [bundle pathForResource:@"motion_3d" ofType:@"json"];
    NSString *motionHandJsonPath = [bundle pathForResource:@"motion_gesture" ofType:@"json"];
    NSString *makeupJsonPath = [bundle pathForResource:@"makeup" ofType:@"json"];
    NSString *segmentationJsonPath = [bundle pathForResource:@"segmentation" ofType:@"json"];

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

- (void)buildUI {
    self.view.backgroundColor = [UIColor blackColor];

    self.previewView = [[TEPreviewView alloc] init];
    self.previewView.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view addSubview:self.previewView];
    [self.previewView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.view addSubview:self.tePanelView];
    [self.tePanelView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(self.view);
        make.height.mas_equalTo(230);
    }];
}

- (void)initSDK {
    // 如果LightCore是动态下载，需要先设置本地路径
//    [[TEUIConfig shareInstance] setLightCoreBundlePath:@"LightCore.bundle所在目录"];
    __weak __typeof(self)weakSelf = self;
    [TEBeautyKit createXMagic:EFFECT_MODE_PRO onInitListener:^(TEBeautyKit * _Nullable beautyKit) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.teBeautyKit = beautyKit;
        strongSelf.tePanelView.teBeautyKit = strongSelf.teBeautyKit;
        [strongSelf.tePanelView setDefaultBeauty];
    }];
}

- (TEPanelView *)tePanelView {
    if (!_tePanelView) {
        _tePanelView = [[TEPanelView alloc] init];
        _tePanelView.delegate = self;
    }
    return _tePanelView;
}

- (TCEVideoCapture *)videoCapture {
    if (!_videoCapture) {
        _videoCapture = [[TCEVideoCapture alloc] init];
        _videoCapture.delegate = self;
        _videoCapture.resolution = TCEVideoCaptureResolution_720P;
        _videoCapture.mirrored = YES;
    }
    return _videoCapture;
}

#pragma mark - Orientation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self updateInterfaceOrientation];
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

    // 倒立方向不更新给 SDK
    if (newOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        return;
    }
    self.interfaceOrientation = newOrientation;
}

/// 根据摄像头位置、镜像与 UI 方向计算 SDK 需要的旋转角度
- (YtLightDeviceCameraOrientation)covertSDKOrientation {
    YtLightDeviceCameraOrientation orientation = YtLightCameraRotation0;
    BOOL isFront = (self.videoCapture.devicePosition == AVCaptureDevicePositionFront);

    if (isFront) {
        BOOL isMirrored = self.videoCapture.mirrored;
        switch (self.interfaceOrientation) {
            case UIInterfaceOrientationPortrait:
            {
                if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown) {
                    orientation = isMirrored ? YtLightCameraRotation270 : YtLightCameraRotation90;
                } else {
                    orientation = isMirrored ? YtLightCameraRotation90 : YtLightCameraRotation270;
                }
            }
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                orientation = isMirrored ? YtLightCameraRotation270 : YtLightCameraRotation90;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                orientation = YtLightCameraRotation0;
                break;
            case UIInterfaceOrientationLandscapeRight:
                orientation = YtLightCameraRotation180;
                break;
            default:
                break;
        }
    } else {
        switch (self.interfaceOrientation) {
            case UIInterfaceOrientationPortrait:
            {
                if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown) {
                    orientation = YtLightCameraRotation90;
                } else {
                    orientation = YtLightCameraRotation270;
                }
            }
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                orientation = YtLightCameraRotation90;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                orientation = YtLightCameraRotation180;
                break;
            case UIInterfaceOrientationLandscapeRight:
                orientation = YtLightCameraRotation0;
                break;
            default:
                break;
        }
    }
    return orientation;
}

#pragma mark - TCEVideoCaptureDelegate

- (void)videoCaptureDidOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!sampleBuffer) {
        return;
    }
    [self.teBeautyKit setImageOrientation:YtLightCameraRotation0];
    [self processSampleBuffer:sampleBuffer orientation:[self covertSDKOrientation]];
}

#pragma mark - 美颜处理

- (void)processSampleBuffer:(CMSampleBufferRef)inputSampleBuffer orientation:(YtLightDeviceCameraOrientation)orientation {
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(inputSampleBuffer);
    if (!pixelBuffer) {
        return;
    }
    YTProcessOutput *output = [self.teBeautyKit processPixelData:pixelBuffer
                                                  pixelDataWidth:(int)CVPixelBufferGetWidth(pixelBuffer)
                                                 pixelDataHeight:(int)CVPixelBufferGetHeight(pixelBuffer)
                                                      withOrigin:YtLightImageOriginTopLeft
                                                 withOrientation:orientation];
    if (!output || !output.pixelData || !output.pixelData.data) {
        return;
    }
    CVPixelBufferRef outputPixelBuffer = CVPixelBufferRetain(output.pixelData.data);
    CMSampleBufferRef outputSampleBuffer = [self sampleBufferFromPixelBuffer:outputPixelBuffer];
    CVPixelBufferRelease(outputPixelBuffer);
    if (outputSampleBuffer == NULL) {
        return;
    }
    [self enqueueSampleBufferOnMainThread:outputSampleBuffer];
}

- (void)enqueueSampleBufferOnMainThread:(CMSampleBufferRef)sampleBuffer {
    if (!sampleBuffer) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        // 处理进入后台后layer失效问题
        if (self.previewView.previewLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            [self.previewView.previewLayer flush];
        }
        [self.previewView.previewLayer enqueueSampleBuffer:sampleBuffer];
        CFRelease(sampleBuffer);
    });
}

- (CMSampleBufferRef)sampleBufferFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CMSampleBufferRef outputSampleBuffer = NULL;
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    CMVideoFormatDescriptionRef videoInfo = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timing, &outputSampleBuffer);

    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(outputSampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);

    CFRelease(videoInfo);
    return outputSampleBuffer;
}

#pragma mark - TEPanelViewDelegate

- (void)showBeautyChanged:(BOOL)open {
    [self.teBeautyKit enableBeauty:open];
}

#pragma mark - Rotation Support

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
