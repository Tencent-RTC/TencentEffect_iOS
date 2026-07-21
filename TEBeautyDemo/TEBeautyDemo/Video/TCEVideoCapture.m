//
//  TEVideoCapture.m
//  BeautyUI
//
//  Created by jasonggao on 2025/8/1.
//

#import "TCEVideoCapture.h"

@interface TCEVideoCapture ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong, readwrite) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, assign) BOOL isSwitching;

#if TARGET_OS_OSX
// Mac 专用属性
@property (nonatomic, strong, readwrite) NSArray<AVCaptureDevice *> *availableCameras;
@property (nonatomic, strong, readwrite) AVCaptureDevice *currentCamera;
#else
// iOS 专用属性
@property (nonatomic, assign, readwrite) AVCaptureDevicePosition devicePosition;
@property (nonatomic, assign) BOOL frontCameraMirrored; // 记住前置镜像偏好
#endif

@end

@implementation TCEVideoCapture

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.sessionQueue = dispatch_queue_create("com.tencent.beauty.sessionQueue", DISPATCH_QUEUE_SERIAL);
        self.videoDataOutputQueue = dispatch_queue_create("com.tencent.beauty.videoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        self.captureSession = [[AVCaptureSession alloc] init];
        self.pixelFormat = TCEVideoCapturePixelFormat_BGRA; // 默认 BGRA
#if TARGET_OS_OSX
        [self refreshAvailableCameras];
#else
        self.devicePosition = AVCaptureDevicePositionFront;
        _frontCameraMirrored = YES; // 默认前置镜像
#endif
        [self configureAndStartSession];
    }
    return self;
}

#if TARGET_OS_OSX
#pragma mark - Mac Implementation

- (void)refreshAvailableCameras {
    AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
        discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeExternalUnknown]
        mediaType:AVMediaTypeVideo
        position:AVCaptureDevicePositionUnspecified];
    self.availableCameras = discoverySession.devices;
}

- (void)configureAndStartSession {
    dispatch_async(self.sessionQueue, ^{
        [self.captureSession beginConfiguration];
        
        // 获取默认摄像头
        AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (!videoDevice && self.availableCameras.count > 0) {
            videoDevice = self.availableCameras.firstObject;
        }
        if (!videoDevice) {
            [self.captureSession commitConfiguration];
            return;
        }
        self.currentCamera = videoDevice;
        
        NSError *error = nil;
        AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        if (error) {
            NSLog(@"videoInput error: %@", error);
            [self.captureSession commitConfiguration];
            return;
        }
        if ([self.captureSession canAddInput:videoInput]) {
            [self.captureSession addInput:videoInput];
        } else {
            [self.captureSession commitConfiguration];
            return;
        }
        
        // 添加 input 后设置默认分辨率为 720P
        [self setResolutionForDevice:videoDevice width:1280 height:720];
        
        // 设置期望帧率
        [self setFrameRate:30 forDevice:videoDevice];
        
        self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        NSDictionary *settings = @{
            (id)kCVPixelBufferPixelFormatTypeKey: @([self cvPixelFormatType]),
            (id)kCVPixelBufferWidthKey: @(1280),
            (id)kCVPixelBufferHeightKey: @(720)
        };
        self.videoDataOutput.videoSettings = settings;
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
        
        if ([self.captureSession canAddOutput:self.videoDataOutput]) {
            [self.captureSession addOutput:self.videoDataOutput];
        } else {
            [self.captureSession commitConfiguration];
            return;
        }
        
        [self.captureSession commitConfiguration];
    });
}

- (void)switchToCamera:(AVCaptureDevice *)device {
    if (!device || device == self.currentCamera) {
        return;
    }
    
    self.isSwitching = YES;
    dispatch_async(self.sessionQueue, ^{
        AVCaptureInput *currentInput = self.captureSession.inputs.firstObject;
        if (!currentInput) {
            self.isSwitching = NO;
            return;
        }
        
        NSError *error = nil;
        AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        if (error) {
            NSLog(@"switchToCamera error: %@", error);
            self.isSwitching = NO;
            return;
        }
        
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:currentInput];
        if ([self.captureSession canAddInput:newInput]) {
            [self.captureSession addInput:newInput];
            [self setFrameRate:30 forDevice:device];
            self.currentCamera = device;
        } else {
            [self.captureSession addInput:currentInput];
        }
        [self.captureSession commitConfiguration];
        self.isSwitching = NO;
    });
}

/// Mac: 设置设备的分辨率（通过 activeFormat）
- (void)setResolutionForDevice:(AVCaptureDevice *)device width:(int)width height:(int)height {
    if (!device) {
        return;
    }
    
    AVCaptureDeviceFormat *bestFormat = nil;
    for (AVCaptureDeviceFormat *format in device.formats) {
        CMVideoDimensions dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        // 查找匹配的分辨率
        if (dims.width == width && dims.height == height) {
            bestFormat = format;
            break;
        }
    }
    
    if (bestFormat) {
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            device.activeFormat = bestFormat;
            [device unlockForConfiguration];
            NSLog(@"Set device format to %dx%d", width, height);
        } else {
            NSLog(@"Failed to lock device for configuration: %@", error);
        }
    } else {
        NSLog(@"No format found for %dx%d", width, height);
    }
}

#else
#pragma mark - iOS Implementation

- (void)configureAndStartSession {
    dispatch_async(self.sessionQueue, ^{
        [self.captureSession beginConfiguration];
        AVCaptureDevice *videoDevice = [self cameraWithPosition:self.devicePosition];
        if (!videoDevice) {
            [self.captureSession commitConfiguration];
            return;
        }
        //设置期望帧率
        [self setFrameRate:30 forDevice:videoDevice];
        
        NSError *error = nil;
        AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        if (error) {
            NSLog(@"videoInput: %@", error);
            [self.captureSession commitConfiguration];
            return;
        }
        if ([self.captureSession canAddInput:videoInput]) {
            [self.captureSession addInput:videoInput];
        } else {
            [self.captureSession commitConfiguration];
            return;
        }
        
        
        self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        NSDictionary *settings = @{(id) kCVPixelBufferPixelFormatTypeKey: @([self cvPixelFormatType])};
        self.videoDataOutput.videoSettings = settings;
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
        
        self.captureSession.usesApplicationAudioSession = YES;
        self.captureSession.automaticallyConfiguresApplicationAudioSession = YES;
        if ([self.captureSession canAddOutput:self.videoDataOutput]) {
            [self.captureSession addOutput:self.videoDataOutput];
        } else {
            [self.captureSession commitConfiguration];
            return;
        }
        [self changeOutputOrientation];
        [self.captureSession commitConfiguration];
    });
}

- (void)switchCamera {
    self.isSwitching = YES;
    dispatch_async(self.sessionQueue, ^{
        // 获取当前输入
        AVCaptureInput *currentInput = self.captureSession.inputs.firstObject;
        if (!currentInput) {
            self.isSwitching = NO;
            return;
        }
        
        AVCaptureDevicePosition currentPosition = AVCaptureDevicePositionUnspecified;
        if ([currentInput isKindOfClass:[AVCaptureDeviceInput class]]) {
            currentPosition = ((AVCaptureDeviceInput *)currentInput).device.position;
        }
        
        AVCaptureDevicePosition newPosition = (currentPosition == AVCaptureDevicePositionBack) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
        
        AVCaptureDevice *newDevice = [self cameraWithPosition:newPosition];
        if (!newDevice) {
            self.isSwitching = NO;
            return;
        }
        
        NSError *error = nil;
        AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:newDevice error:&error];
        if (error) {
            NSLog(@"newInput: %@", error);
            self.isSwitching = NO;
            return;
        }
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:currentInput];
        if ([self.captureSession canAddInput:newInput]) {
            [self.captureSession addInput:newInput];
            [self setFrameRate:30 forDevice:newDevice];
        } else {
            [self.captureSession addInput:currentInput];
            [self.captureSession commitConfiguration];
            self.isSwitching = NO;
            return;
        }
        [self.captureSession commitConfiguration];
        self.devicePosition = newPosition;
        [self changeOutputOrientation];
        self.isSwitching = NO;
    });
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
    NSArray<AVCaptureDevice *> *devices = discoverySession.devices;
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

- (void)changeOutputOrientation {
    for (AVCaptureOutput *output in self.captureSession.outputs) {
        for (AVCaptureConnection *connection in output.connections) {
            if (connection.isVideoMirroringSupported) {
                // 仅前置摄像头支持镜像
                connection.videoMirrored = (self.devicePosition == AVCaptureDevicePositionFront) && self.frontCameraMirrored;
            }
        }
    }
}

- (void)setMirrored:(BOOL)mirrored {
    // 仅前置摄像头时才设置
    if (self.devicePosition != AVCaptureDevicePositionFront) {
        return;
    }
    dispatch_async(self.sessionQueue, ^{
        if (self.frontCameraMirrored == mirrored) {
            return;
        }
        self.isSwitching = YES;
        self.frontCameraMirrored = mirrored;
        [self changeOutputOrientation];
        self.isSwitching = NO;
    });
}

- (BOOL)mirrored {
    // 后置始终返回 NO，前置返回偏好值
    if (self.devicePosition != AVCaptureDevicePositionFront) {
        return NO;
    }
    return _frontCameraMirrored;
}

#endif

#pragma mark - Common Methods

- (OSType)cvPixelFormatType {
    switch (self.pixelFormat) {
        case TCEVideoCapturePixelFormat_NV12_FullRange:
            return kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        case TCEVideoCapturePixelFormat_NV12_VideoRange:
            return kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
        case TCEVideoCapturePixelFormat_BGRA:
        default:
            return kCVPixelFormatType_32BGRA;
    }
}

- (void)setPixelFormat:(TCEVideoCapturePixelFormat)pixelFormat {
    _pixelFormat = pixelFormat;
    dispatch_async(self.sessionQueue, ^{
        if (!self.videoDataOutput) {
            return;
        }
        [self.captureSession beginConfiguration];
#if TARGET_OS_OSX
        CGSize size = [self getReolutionSize:self.resolution];
        int width = (int)size.width;
        int height = (int)size.height;
        NSDictionary *settings = @{
            (id)kCVPixelBufferPixelFormatTypeKey: @([self cvPixelFormatType]),
            (id)kCVPixelBufferWidthKey: @(width),
            (id)kCVPixelBufferHeightKey: @(height)
        };
#else
        NSDictionary *settings = @{(id)kCVPixelBufferPixelFormatTypeKey: @([self cvPixelFormatType])};
#endif
        self.videoDataOutput.videoSettings = settings;
        [self.captureSession commitConfiguration];
    });
}

- (void)setResolution:(TCEVideoCaptureResolution)resolution {
    dispatch_async(self.sessionQueue, ^{
        self->_resolution = resolution;
        
        [self.captureSession beginConfiguration];
#if TARGET_OS_OSX
        // Mac: 通过 activeFormat 设置分辨率
        int width = 1280, height = 720;
        if (resolution == TCEVideoCaptureResolution_540P) {
            width = 960; height = 540;
        } else if (resolution == TCEVideoCaptureResolution_1080P) {
            width = 1920; height = 1080;
        }
        
        [self setResolutionForDevice:self.currentCamera width:width height:height];
        // 更新 output 的 videoSettings
        NSDictionary *settings = @{
            (id)kCVPixelBufferPixelFormatTypeKey: @([self cvPixelFormatType]),
            (id)kCVPixelBufferWidthKey: @(width),
            (id)kCVPixelBufferHeightKey: @(height)
        };
        self.videoDataOutput.videoSettings = settings;
#else
        // iOS: 通过 sessionPreset 设置分辨率
        if (resolution == TCEVideoCaptureResolution_540P) {
            self.captureSession.sessionPreset = AVCaptureSessionPresetiFrame960x540;
        } else if (resolution == TCEVideoCaptureResolution_1080P) {
            self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
        } else {
            self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        }
#endif
        [self.captureSession commitConfiguration];
    });
}

- (CGSize)getReolutionSize:(TCEVideoCaptureResolution)resolution {
    CGSize result = CGSizeZero;
    switch (resolution) {
#if TARGET_OS_OSX
        // Mac: 横向分辨率 (width > height)
        case TCEVideoCaptureResolution_540P: result = CGSizeMake(960, 540); break;
        case TCEVideoCaptureResolution_720P: result = CGSizeMake(1280, 720); break;
        case TCEVideoCaptureResolution_1080P: result = CGSizeMake(1920, 1080); break;
#else
        // iOS: 竖向分辨率 (height > width)
        case TCEVideoCaptureResolution_540P: result = CGSizeMake(540, 960); break;
        case TCEVideoCaptureResolution_720P: result = CGSizeMake(720, 1280); break;
        case TCEVideoCaptureResolution_1080P: result = CGSizeMake(1080, 1920); break;
#endif
        default: break;
    }
    return result;
}

- (void)setFrameRate:(int)fps forDevice:(AVCaptureDevice *)device {
    if (!device) {
        return;
    }
    AVCaptureDeviceFormat *desiredFormat = nil;
    for ( AVCaptureDeviceFormat *format in [device formats] ) {
        for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
            if (device.activeFormat == format && range.maxFrameRate >= fps && range.minFrameRate <= fps ) {
                desiredFormat = format;
                break;
            }
        }
        if (desiredFormat != nil) {
            break;
        }
    }
    if (desiredFormat) {
        if ([device lockForConfiguration:nil]) {
            // 设置最小和最大帧率
            device.activeVideoMinFrameDuration = CMTimeMake(1, fps);
            device.activeVideoMaxFrameDuration = CMTimeMake(1, fps);
            
            [device unlockForConfiguration];
        }
    }
}

- (void)startRunning {
    if (self.captureSession.isRunning) {
        return;
    }
    dispatch_async(self.sessionQueue, ^{
        [self.captureSession startRunning];
    });
}

- (void)stopRunning {
    if (self.captureSession.isRunning) {
        dispatch_async(self.sessionQueue, ^{
            [self.captureSession stopRunning];
        });
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (self.isSwitching) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(videoCaptureDidOutputSampleBuffer:)]) {
        [self.delegate videoCaptureDidOutputSampleBuffer:sampleBuffer];
    }
}

@end
