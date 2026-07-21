//
//  TEBeautyTRTCAdapter.m
//  TRTCAdapter
//
//  Created by tao yue on 2024/3/1.
//

#import "TEAgoraAdapter.h"
#import <XMagic/XMagic.h>
#import <XMagic/TEImageTransform.h>


@interface TEAgoraAdapter()<AgoraVideoFrameDelegate>

@property (nonatomic, strong) AgoraRtcEngineKit *agoraEngine;
@property (nonatomic, strong) XMagic *xMagic;
@property (nonatomic, strong) OnCreatedXmagicApi onCreatedXmagicApi;
@property (nonatomic, strong) OnDestroyXmagicApi onDestroyXmagicApi;
@property (nonatomic, assign) UIDeviceOrientation deviceOrientation;
@property (nonatomic, assign) BOOL isFrontCamera;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, assign) EffectMode effectMode;
@property (nonatomic, assign) int lastWidth;
@property (nonatomic, assign) int lastHeight;

@end

@implementation TEAgoraAdapter

- (instancetype)initWithEffectMode:(EffectMode)effectMode {
    self = [super init];
    if (self) {
        _enableBeauty = YES;
        _isFrontCamera = YES;
        _deviceOrientation = UIDeviceOrientationPortrait;
        _effectMode = effectMode;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _enableBeauty = YES;
        _effectMode = EFFECT_MODE_PRO;
        _isFrontCamera = YES;
        _deviceOrientation = UIDeviceOrientationPortrait;
    }
    return self;
}


- (void)bind:(id)pusher onCreatedXmagicApi:(OnCreatedXmagicApi _Nullable)onCreatedXmagicApi onDestroyXmagicApi:(OnDestroyXmagicApi _Nullable)onDestroyXmagicApi {
    self.agoraEngine = pusher;
    self.onCreatedXmagicApi = onCreatedXmagicApi;
    self.onDestroyXmagicApi = onDestroyXmagicApi;
    [self setLocalVideoProcessListener];
}

- (void)unbind {
    [self.agoraEngine setVideoFrameDelegate:nil];
    [self.lock lock];
    [self.xMagic clearListeners];
    [self.xMagic deinit];
    self.xMagic = nil;
    if (self.onDestroyXmagicApi != nil) {
        self.onDestroyXmagicApi();
    }
    [self.lock unlock];
}

- (NSLock *)lock {
    if (!_lock) {
        _lock = [[NSLock alloc] init];
    }
    return _lock;
}

- (void)setLocalVideoProcessListener {
    if(!self.agoraEngine){
        return;
    }
    [self.agoraEngine setVideoFrameDelegate:self];
}

- (void)initXMagic {
    NSString *corePath = self.lightCoreBundlePath ;
    if (corePath == nil) {
        corePath = [[NSBundle mainBundle] bundlePath];
    }
    NSDictionary *assetsDict = @{@"core_name":@"LightCore.bundle",
                                 @"root_path":corePath,
                                 @"effect_mode":@(_effectMode)
    };

    self.xMagic = [[XMagic alloc] initWithRenderSize:CGSizeMake(720, 1280) assetsDict:assetsDict];
    if (self.onCreatedXmagicApi != nil) {
        self.onCreatedXmagicApi(self.xMagic);
    }
}

- (BOOL)onCaptureVideoFrame:(AgoraOutputVideoFrame *)videoFrame sourceType:(AgoraVideoSourceType)sourceType {
    [self.lock lock];
    if (!_xMagic) {
        [self initXMagic];
    }
    int width = (int)CVPixelBufferGetWidth(videoFrame.pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(videoFrame.pixelBuffer);
    if (self.enableBeauty && videoFrame.pixelBuffer) {
        if (self.xMagic && (width != self.lastWidth || height != self.lastHeight)) {
            self.lastWidth = width;
            self.lastHeight = height;
            [self.xMagic setRenderSize:CGSizeMake(width, height)];
        }
        YTProcessInput *input = [[YTProcessInput alloc] init];
        input.pixelData = [[YTImagePixelData alloc] init];
        input.pixelData.data = videoFrame.pixelBuffer;
        input.dataType = kYTImagePixelData;
        YTProcessOutput *output = [self.xMagic process:input withOrigin:YtLightImageOriginTopLeft withOrientation:YtLightCameraRotation0];
        videoFrame.pixelBuffer = output.pixelData.data;
    }
    [self.lock unlock];
    return YES;
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
