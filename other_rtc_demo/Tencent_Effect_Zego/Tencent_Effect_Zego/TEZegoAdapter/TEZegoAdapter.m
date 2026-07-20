//
//  TEZegoAdapter.m
//  Tencent_Effect_Zego
//
//  Created by jasonggao on 2025/11/10.
//

#import "TEZegoAdapter.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>

@interface TEZegoAdapter ()<ZegoCustomVideoProcessHandler>
@property (nonatomic, strong) ZegoExpressEngine *zegoExpressEngine;
@property (nonatomic, strong) XMagic *xMagic;
@property (nonatomic, copy) OnCreatedXMagic onCreatedXMagic;
@property (nonatomic, copy) OnDestroyedXMagic onDestroyedXMagic;
@property (nonatomic, assign) UIDeviceOrientation deviceOrientation;
@property (nonatomic, assign) ImageStartPosition imageStartPosition;
@property (nonatomic, assign) VideoMirrorType mirrorType;
@property (nonatomic, assign) EffectMode effectMode;
@property (nonatomic, assign) BOOL isFrontCamera;
@property (nonatomic, assign) int lastWidth;
@property (nonatomic, assign) int lastHeight;

@end

@implementation TEZegoAdapter

- (void)dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _enableBeauty = YES;
        _isFrontCamera = YES;
        _mirrorType = ENABLE;
        _deviceOrientation = UIDeviceOrientationPortrait;
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

#pragma mark - public
- (instancetype)initWithEffectMode:(EffectMode)effectMode {
    TEZegoAdapter *adapter = [[TEZegoAdapter alloc] init];
    adapter.effectMode = effectMode;
    return adapter;
}

- (void)bind:(id)pusher onCreatedXMagic:(OnCreatedXMagic _Nullable)onCreatedXMagic onDestroyedXMagic:(OnDestroyedXMagic _Nullable)onDestroyedXMagic {
    self.zegoExpressEngine = pusher;
    self.onCreatedXMagic = onCreatedXMagic;
    self.onDestroyedXMagic = onDestroyedXMagic;
    [self initXMagic];
    [self setLocalVideoProcessListener];
}

- (void)unbind {
    [self.zegoExpressEngine setCustomVideoRenderHandler:nil];
    [self.xMagic deinit];
    if (self.onDestroyedXMagic) {
        self.onDestroyedXMagic();
    }
}

- (void)setDeviceOrientation:(UIDeviceOrientation)orientation {
    _deviceOrientation = orientation;
    [self updateZegoVideoOrientation];
    [self updateImageOrientation];
}

#pragma mark - private
- (void)setLocalVideoProcessListener {
    if (!self.zegoExpressEngine){
        return;
    }
    ZegoCustomVideoProcessConfig *processConfig = [[ZegoCustomVideoProcessConfig alloc] init];
    // 选择 CVPixelBuffer 类型视频帧数据
    processConfig.bufferType = ZegoVideoBufferTypeCVPixelBuffer;
    // 开启自定义前处理
    [self.zegoExpressEngine enableCustomVideoProcessing:YES config:processConfig channel:ZegoPublishChannelMain];
    // 将自身作为自定义视频前处理回调对象
    [self.zegoExpressEngine setCustomVideoProcessHandler:self];
}

- (void)initXMagic {
    NSString *corePath = self.lightCoreBundlePath;
    if (corePath == nil) {
        corePath = [[NSBundle mainBundle] bundlePath];
    }
    NSDictionary *assetsDict = @{@"core_name":@"LightCore.bundle",
                                 @"root_path":corePath,
                                 @"effect_mode":@(_effectMode)
    };
    self.xMagic = [[XMagic alloc] initWithRenderSize:CGSizeMake(720, 1280) assetsDict:assetsDict];
    if (self.onCreatedXMagic) {
        self.onCreatedXMagic(self.xMagic);
    }
}

- (void)updateZegoVideoOrientation {
    ZegoVideoConfig *videoConfig = [[ZegoExpressEngine sharedEngine] getVideoConfig];
    UIInterfaceOrientation orientation = [self currentInterfaceOrientation];
    if ([self currentInterfaceOrientation] == UIInterfaceOrientationPortrait) {
        videoConfig.encodeResolution = CGSizeMake(720, 1280);
    } else {
        videoConfig.encodeResolution = CGSizeMake(1280, 720);
    }
    [self.zegoExpressEngine setVideoConfig:videoConfig];
    [self.zegoExpressEngine setAppOrientation:orientation];
}

- (void)updateImageOrientation {
    /// 当前设备方向 deviceOrientation
    /// 当前屏幕方向 interfaceOrientation
    UIInterfaceOrientation interfaceOrientation = [self currentInterfaceOrientation];
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        if (self.deviceOrientation == UIDeviceOrientationPortraitUpsideDown) {
            //手机倒置
            [self.xMagic setImageOrientation:YtLightCameraRotation180];
        } else {
            [self.xMagic setImageOrientation:YtLightCameraRotation0];
        }
    } else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        if (self.deviceOrientation == UIDeviceOrientationPortraitUpsideDown) {
            //手机倒置
            [self.xMagic setImageOrientation:YtLightCameraRotation270];
        } else {
            [self.xMagic setImageOrientation:YtLightCameraRotation0];
        }
    } else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        if (self.deviceOrientation == UIDeviceOrientationPortraitUpsideDown) {
            //手机倒置
            [self.xMagic setImageOrientation:YtLightCameraRotation90];
        } else {
            [self.xMagic setImageOrientation:YtLightCameraRotation0];
        }
    }
}

- (UIInterfaceOrientation)deviceOrientationToInterfaceOrientation:(UIDeviceOrientation)orientation {
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            return UIInterfaceOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            return UIInterfaceOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            return UIInterfaceOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            return UIInterfaceOrientationLandscapeLeft;
            break;
        default:
            break;
    }
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientation)currentInterfaceOrientation {
    UIInterfaceOrientation interfaceOrientation = UIInterfaceOrientationPortrait;
    for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
        if (windowScene.activationState == UISceneActivationStateForegroundActive &&
            [windowScene isKindOfClass:[UIWindowScene class]]) {
            interfaceOrientation = windowScene.interfaceOrientation;
            break;
        }
    }
    return interfaceOrientation;
}

#pragma mark - 屏幕旋转
- (void)orientationDidChange:(NSNotification *)notification {
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    [self setDeviceOrientation:deviceOrientation];
    [self updateImageOrientation];
}

#pragma mark - ZegoCustomVideoProcessHandler
- (void)onCapturedUnprocessedCVPixelBuffer:(CVPixelBufferRef)buffer timestamp:(CMTime)timestamp channel:(ZegoPublishChannel)channel {
    int width = (int)CVPixelBufferGetWidth(buffer);
    int height = (int)CVPixelBufferGetHeight(buffer);
    
    if (!self.enableBeauty) {
        [[ZegoExpressEngine sharedEngine] sendCustomVideoProcessedCVPixelBuffer:buffer timestamp:timestamp];
    } else {
        if (self.xMagic && (width != self.lastWidth || height != self.lastHeight)){
            self.lastWidth = width;
            self.lastHeight = height;
            [self.xMagic setRenderSize:CGSizeMake(width, height)];
        }
        YTProcessInput *input = [[YTProcessInput alloc] init];
        input.pixelData = [[YTImagePixelData alloc] init];
        input.pixelData.data = buffer;
        input.dataType = kYTImagePixelData;
        YTProcessOutput * output = [self.xMagic process:input withOrigin:YtLightImageOriginTopLeft withOrientation:YtLightCameraRotation0];
        if (output.pixelData.data) {
            [[ZegoExpressEngine sharedEngine] sendCustomVideoProcessedCVPixelBuffer:output.pixelData.data timestamp:timestamp];
        }
    }
}

@end
