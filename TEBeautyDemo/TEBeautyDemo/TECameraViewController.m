//
//  TECameraViewController.m
//  TEBeautyDemo
//
//  Created by chavezchen on 2024/4/24.
//

#import "TECameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES3/gl.h>
#import <Masonry/Masonry.h>
#import <TEBeautyKit/TEUIConfig.h>
#import <TEBeautyKit/TEPanelView.h>
#import <TEBeautyKit/TEDownloader.h>
#import "TCEVideoCapture.h"
#import "TEPreviewView.h"
#import "TEPixelBufferRotator.h"

@interface TECameraViewController ()<TCEVideoCaptureDelegate,TEPanelViewDelegate,YTSDKLogListener,YTSDKEventListener>
{
    //OpenGL related
    CVOpenGLESTextureRef bgraTextureRef;
    CVOpenGLESTextureCacheRef textureCache;
    EAGLContext *eaglContext;
    GLuint glFrameBuffer;
    CVPixelBufferRef pixelBufferOuput;
}
@property (nonatomic, strong) TEPreviewView *previewView;
@property (nonatomic, strong) UIButton *exportBtn;
@property (nonatomic, strong) UIButton *mirrorBtn;

@property (nonatomic, strong) TCEVideoCapture *videoCapture;
@property (nonatomic, strong) TEBeautyKit *teBeautyKit;
@property (nonatomic, strong) TEPanelView *tePanelView;
//导出的美颜数据
@property (nonatomic, strong) NSString *exportBeautyString;
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;
@property (nonatomic, assign) BOOL useTextureMode;
@property (nonatomic, assign) BOOL isShowOrigin;
@property (nonatomic, strong) EAGLContext *eaglContext;
@property (nonatomic, strong) TEPixelBufferRotator *pixelBufferRotator;

@end

@implementation TECameraViewController

- (void)dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    if (bgraTextureRef) {
        CFRelease(bgraTextureRef);
        bgraTextureRef = NULL;
    }
    if (textureCache) {
        CVOpenGLESTextureCacheFlush(textureCache, 0);
        CFRelease(textureCache);
        textureCache = NULL;
    }
    if (glFrameBuffer) {
        glDeleteFramebuffers(1, &glFrameBuffer);
        glFrameBuffer = 0;
    }
    if (pixelBufferOuput) {
        CVPixelBufferRelease(pixelBufferOuput);
        pixelBufferOuput = NULL;
    }
    if (eaglContext) {
        [EAGLContext setCurrentContext:nil];
        eaglContext = nil;
    }
    if (self.teBeautyKit) {
        [self.teBeautyKit onDestroy];
    }
    [self.pixelBufferRotator cleanup];
    self.pixelBufferRotator = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.useTextureMode = YES;
    
    // 配置面板
    [self initBeautyJson];
    // 设置语言
    [self configLanguage];
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
    // 初始化 UI 方向
    [self updateInterfaceOrientation];
}

- (void)initBeautyJson {
    self.exportBeautyString = [[NSUserDefaults standardUserDefaults] objectForKey:kExportEffectData];
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
    
    [self.view addSubview:self.exportBtn];
    [self.exportBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.tePanelView.mas_top).offset(-20);
        make.right.offset(0);
        make.width.mas_equalTo(50);
        make.height.mas_equalTo(30);
    }];
    
    [self.view addSubview:self.mirrorBtn];
    [self.mirrorBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.exportBtn.mas_top).offset(-10);
        make.right.offset(0);
        make.width.mas_equalTo(50);
        make.height.mas_equalTo(30);
    }];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"切换" style:UIBarButtonItemStylePlain target:self action:@selector(switchCamera)];
    
    // 添加点击手势，用于隐藏/显示底部面板
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePanelVisibility)];
    [self.previewView addGestureRecognizer:tapGesture];
}

- (void)initSDK {
    /// 如果LightCore是动态下载，需要先调用下面的接口设置本地路径
//    [[TEUIConfig shareInstance] setLightCoreBundlePath:@"LightCore.bundle路径"];
    /// 如果素材xxxRes.bundle是整体打包动态下载，需要先调用setResourcesBundlePath设置本地路径
    /// 如果素材是单个分开下载，则只需修改json文件中的resourceUri即可：如resourceUri : @"https://x.x.x/xxx.zip"
//    [[TEUIConfig shareInstance] setResourcesBundlePath:@"xxxRes.bundle路径"];
    __weak __typeof(self)weakSelf = self;
    [TEBeautyKit createXMagic:EFFECT_MODE_PRO onInitListener:^(TEBeautyKit * _Nullable beautyKit) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.teBeautyKit = beautyKit;
        strongSelf.tePanelView.teBeautyKit = strongSelf.teBeautyKit;
        [strongSelf.tePanelView setDefaultBeauty];
        [strongSelf.teBeautyKit registerSDKLogListener:strongSelf level:YT_SDK_INFO_LEVEL];
        [strongSelf.teBeautyKit registerSDKEventListener:strongSelf];
        if (strongSelf.exportBeautyString) {
            [strongSelf.tePanelView setExportParamList:strongSelf.exportBeautyString];
        }
        if (self.useTextureMode) {
            [self setupGlEnv];
        }
    }];
}

- (void)setupGlEnv {
    //gl上下文使用beautyKit的
    eaglContext = [self.teBeautyKit getCurrentGlContext];
    [EAGLContext setCurrentContext:eaglContext];
    CVReturn res = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, eaglContext, NULL, &textureCache);
    if (res != kCVReturnSuccess) {
        NSLog(@"Create textureCache failed");
        return ;
    }
    //framebuffer 创建
    glGenFramebuffers(1, &glFrameBuffer);
    pixelBufferOuput = NULL;
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

- (TEPanelView *)tePanelView {
    if (!_tePanelView) {
        _tePanelView = [[TEPanelView alloc] init];
        _tePanelView.delegate = self;
    }
    return _tePanelView;
}

- (UIButton *)exportBtn {
    if (!_exportBtn) {
        _exportBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_exportBtn setTitle:@"导出" forState:UIControlStateNormal];
        [_exportBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _exportBtn.titleLabel.font = [UIFont systemFontOfSize:17];
        _exportBtn.titleLabel.shadowColor = [UIColor blackColor];
        _exportBtn.titleLabel.shadowOffset = CGSizeMake(5, 5);
        [_exportBtn addTarget:self action:@selector(exportEffectData) forControlEvents:UIControlEventTouchUpInside];
    }
    return _exportBtn;
}

- (UIButton *)mirrorBtn {
    if (!_mirrorBtn) {
        _mirrorBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_mirrorBtn setTitle:@"镜像" forState:UIControlStateNormal];
        [_mirrorBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _mirrorBtn.titleLabel.font = [UIFont systemFontOfSize:17];
        _mirrorBtn.titleLabel.shadowColor = [UIColor blackColor];
        _mirrorBtn.titleLabel.shadowOffset = CGSizeMake(5, 5);
        [_mirrorBtn addTarget:self action:@selector(toggleMirror) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mirrorBtn;
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

#pragma mark - export
- (void)exportEffectData {
    self.exportBeautyString = [self.teBeautyKit exportInUseSDKParam];
    NSLog(@"%@",self.exportBeautyString);
    [[NSUserDefaults standardUserDefaults] setObject:self.exportBeautyString forKey:kExportEffectData];
}

#pragma mark - Camera
- (void)switchCamera {
    [self.videoCapture switchCamera];
}

- (void)toggleMirror {
    self.videoCapture.mirrored = !self.videoCapture.mirrored;
}

- (void)togglePanelVisibility {
    BOOL isHidden = self.tePanelView.alpha == 0;
    [UIView animateWithDuration:0.25 animations:^{
        self.tePanelView.alpha = isHidden ? 1.0 : 0.0;
        self.exportBtn.alpha = isHidden ? 1.0 : 0.0;
        self.mirrorBtn.alpha = isHidden ? 1.0 : 0.0;
    }];
}

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
                //摄像头朝右
                orientation = YtLightCameraRotation0;
                break;
            case UIInterfaceOrientationLandscapeRight:
                //摄像头朝左
                orientation = YtLightCameraRotation180;
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
                //摄像头朝右
                orientation = YtLightCameraRotation180;
                break;
            case UIInterfaceOrientationLandscapeRight:
                //摄像头朝左
                orientation = YtLightCameraRotation0;
                break;
            default:
                break;
        }
    }
    return orientation;
}

- (TEPixelBufferRotator *)pixelBufferRotator {
    if (!_pixelBufferRotator) {
        _pixelBufferRotator = [[TEPixelBufferRotator alloc] initWithEngineType:TERotationEngineTypeVImage];
    }
    return _pixelBufferRotator;
}

- (TERotationDirection)rotationDirectionFromSDKOrientation:(YtLightDeviceCameraOrientation)orientation {
    switch (orientation) {
        case YtLightCameraRotation90:
            return TERotationDirectionCounterClock90;
        case YtLightCameraRotation180:
            return TERotationDirectionCounterClock180;
        case YtLightCameraRotation270:
            return TERotationDirectionCounterClock270;
        case YtLightCameraRotation0:
        default:
            return TERotationDirectionNone;
    }
}

#pragma mark - TCEVideoCaptureDelegate
- (void)videoCaptureDidOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!sampleBuffer) {
        return;
    }
    YtLightDeviceCameraOrientation orientation = [self covertSDKOrientation];
    if (self.isShowOrigin) {
        CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        if (!pixelBuffer) {
            return;
        }
        TERotationDirection direction = [self rotationDirectionFromSDKOrientation:orientation];
        CVPixelBufferRef rotatedPixelBuffer = [self.pixelBufferRotator rotatePixelBuffer:(CVPixelBufferRef)pixelBuffer
                                                                               direction:direction];
        if (!rotatedPixelBuffer) {
            CFRetain(sampleBuffer);
            [self enqueueSampleBufferOnMainThread:sampleBuffer releaseAfterEnqueue:YES];
            return;
        }
        CMSampleBufferRef rotatedSampleBuffer = [self sampleBufferFromPixelBuffer:rotatedPixelBuffer];
        CVPixelBufferRelease(rotatedPixelBuffer);
        if (!rotatedSampleBuffer) {
            return;
        }
        [self enqueueSampleBufferOnMainThread:rotatedSampleBuffer releaseAfterEnqueue:YES];
        return;
    }

    [self.teBeautyKit setImageOrientation:YtLightCameraRotation0];
    [self myCaptureOutputSampleBuffer:sampleBuffer orientation:orientation];
}

- (YTProcessOutput *)processDataWithCpuFuc:(CMSampleBufferRef)inputSampleBuffer orientation:(YtLightDeviceCameraOrientation)orientation {
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(inputSampleBuffer);
    if (!pixelBuffer) {
        return nil;
    }
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    return [self.teBeautyKit processPixelData:pixelBuffer
                               pixelDataWidth:bufferWidth
                              pixelDataHeight:bufferHeight
                                   withOrigin:YtLightImageOriginTopLeft
                              withOrientation:orientation];
}

- (YTProcessOutput *)processDataWithGpuFuc:(CMSampleBufferRef)inputSampleBuffer orientation:(YtLightDeviceCameraOrientation)orientation {
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(inputSampleBuffer);
    if (!pixelBuffer) {
        return nil;
    }
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    [EAGLContext setCurrentContext:eaglContext];
    
    // BGRA 格式处理
    if (bgraTextureRef) {
        CFRelease(bgraTextureRef);
        bgraTextureRef = NULL;
    }
    CVReturn res = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                textureCache,
                                                                pixelBuffer,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA,
                                                                bufferWidth,
                                                                bufferHeight,
                                                                GL_BGRA,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &bgraTextureRef);
    if (res) {
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage error at %d", res);
        return nil;
    }
    
    GLuint bgraTex = CVOpenGLESTextureGetName(bgraTextureRef);
    glBindTexture(GL_TEXTURE_2D, bgraTex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    if (bgraTex == 0) {
        return nil;
    }
    
    return [self.teBeautyKit processTexture:bgraTex
                               textureWidth:bufferWidth
                              textureHeight:bufferHeight
                                 withOrigin:YtLightImageOriginTopLeft
                            withOrientation:orientation];
}

- (void)myCaptureOutputSampleBuffer:(CMSampleBufferRef)inputSampleBuffer orientation:(YtLightDeviceCameraOrientation)orientation {
    YTProcessOutput *output = nil;
    if (self.useTextureMode) {
        output = [self processDataWithGpuFuc:inputSampleBuffer orientation:orientation];
    } else {
        output = [self processDataWithCpuFuc:inputSampleBuffer orientation:orientation];
    }
    if (!output || !output.pixelData || !output.pixelData.data) {
        return;
    }
    
    // 处理输出结果
    CVPixelBufferRef outputPixelBuffer = CVPixelBufferRetain(output.pixelData.data);
    if (outputPixelBuffer != nil) {
        CMSampleBufferRef outputSampleBuffer = [self sampleBufferFromPixelBuffer:outputPixelBuffer];
        if (outputSampleBuffer != NULL) {
            [self enqueueSampleBufferOnMainThread:outputSampleBuffer releaseAfterEnqueue:YES];
            CVPixelBufferRelease(outputPixelBuffer);
        } else {
            CVPixelBufferRelease(outputPixelBuffer);
        }
    }
}

#pragma mark - Texture Conversion

- (void)enqueueSampleBufferOnMainThread:(CMSampleBufferRef)sampleBuffer releaseAfterEnqueue:(BOOL)releaseAfterEnqueue {
    if (!sampleBuffer) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.previewView.previewLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            [self.previewView.previewLayer flush];
        }
        [self.previewView.previewLayer enqueueSampleBuffer:sampleBuffer];
        if (releaseAfterEnqueue) {
            CFRelease(sampleBuffer);
        }
    });
}

- (CMSampleBufferRef)sampleBufferFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CMSampleBufferRef outputSampleBuffer = NULL;
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timing, &outputSampleBuffer);
    
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(outputSampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    
    CFRelease(videoInfo);
    return outputSampleBuffer;
}

#pragma mark TEPanelViewDelegate
- (void)showBeautyChanged:(BOOL)open {
    self.isShowOrigin = !open;
    [self.teBeautyKit enableBeauty:open];
}

#pragma mark YTSDKLogListener
- (void)onLog:(YtSDKLoggerLevel)loggerLevel withInfo:(NSString *)logInfo {
    NSLog(@"1111 - >[%ld]-%@", (long)loggerLevel, logInfo);
}

#pragma mark YTSDKEventListener
- (void)onAIEvent:(id _Nonnull)event {
//    NSLog(@"onAIEvent - %@", event);
}

- (void)onTipsEvent:(id _Nonnull)event {
//    NSLog(@"onTipsEvent - %@", event);
}

- (void)onAssetEvent:(id _Nonnull)event {
//    NSLog(@"onAssetEvent - %@", event);
}

#pragma mark - Rotation Support
- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
