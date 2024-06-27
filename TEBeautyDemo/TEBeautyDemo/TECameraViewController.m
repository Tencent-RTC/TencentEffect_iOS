//
//  TECameraViewController.m
//  TEBeautyDemo
//
//  Created by chavezchen on 2024/4/24.
//

#import "TECameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "Masonry.h"
#import "TEUIConfig.h"
#import "TEBeautyKit.h"
#import "TEPanelView.h"
#import "TEDownloader.h"


typedef NS_ENUM(NSUInteger, PreviewResolution) {
    PreviewResolution540P = 0,
    PreviewResolution720P = 1,
    PreviewResolution1080P = 2
};

@interface TECameraViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,TEPanelViewDelegate,YTSDKEventListener>

@property(nonatomic, assign) PreviewResolution currentPreviewResolution;
// Camera related
@property (nonatomic, strong) AVCaptureDevice *cameraDevice;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic,strong) AVSampleBufferDisplayLayer *previewLayer;

@property (nonatomic, strong) XMagic *xMagicKit;
@property (nonatomic, strong) TEBeautyKit *teBeautyKit;
@property (nonatomic, strong) TEPanelView *tePanelView;

@end

@implementation TECameraViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initBeautyJson];
    [self buildUI];
    [self initXMagic];
    [self buildCamra];
}

- (void)buildUI
{
    self.view.backgroundColor = [UIColor blackColor];
    self.currentPreviewResolution = PreviewResolution720P;
    
    self.previewLayer = [AVSampleBufferDisplayLayer layer];
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    self.previewLayer.frame = self.view.bounds;
    
    [self.view addSubview:self.tePanelView];
    [self.tePanelView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.view);
        make.centerX.mas_equalTo(self.view);
        make.height.mas_equalTo(250);
        make.bottom.mas_equalTo(self.view.mas_bottom);
    }];
}

- (TEPanelView *)tePanelView {
    if (!_tePanelView) {
        _tePanelView = [[TEPanelView alloc] init:nil comboType:nil];
        _tePanelView.delegate = self;
    }
    return _tePanelView;
}

- (void)initBeautyJson {
    [[TEUIConfig shareInstance] setPanelLevel:S1_07];
    NSString *corePath = [[TEDownloader shardManager].basicPath stringByAppendingPathComponent:@"ModelRes"];
    //设置美颜模型下载到沙盒中的路径给TEUIConfig
    [[TEUIConfig shareInstance] setLightCoreBundlePath:corePath];
}

- (void)initXMagic {
    __weak __typeof(self)weakSelf = self;
    [TEBeautyKit create:^(XMagic * _Nullable api) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.xMagicKit = api;
        [strongSelf.teBeautyKit setXMagicApi:api];
        strongSelf.tePanelView.teBeautyKit = strongSelf.teBeautyKit;
        [strongSelf.teBeautyKit setTePanelView:strongSelf.tePanelView];
        [strongSelf.teBeautyKit setLogLevel:YT_SDK_ERROR_LEVEL];
        strongSelf.tePanelView.beautyKitApi = api;
        [strongSelf.xMagicKit registerSDKEventListener:strongSelf];
    }];
}

- (TEBeautyKit *)teBeautyKit {
    if (!_teBeautyKit) {
        _teBeautyKit= [[TEBeautyKit alloc] init];
    }
    return _teBeautyKit;
}

#pragma mark - cramera
- (void)buildCamra
{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                           error:nil];
    [self buildCamera:AVCaptureDevicePositionFront];
}

- (BOOL)checkCameraAuthorization {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:@"Tencent Effect想访问您的相机"
                                                               message:nil
                                                              delegate:self
                                                     cancelButtonTitle:@"不允许"
                                                     otherButtonTitles:@"好", nil];
            [alerView show];
        });
        return NO;
    }
    return YES;
}
- (void)buildCamera:(AVCaptureDevicePosition)cameraPosition {
    if (![self checkCameraAuthorization]) {
        return;
    }
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            // 设置摄像头翻转
            NSArray *cameraDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
            for (AVCaptureDevice *cameraDevice in cameraDevices) {
                self.cameraDevice = cameraDevice;
                if (cameraDevice.position == cameraPosition) {
                    break;
                }
            }
            AVCaptureSession *cameraCaptureSession = [[AVCaptureSession alloc] init];
            cameraCaptureSession.sessionPreset = AVCaptureSessionPresetHigh;
            [cameraCaptureSession beginConfiguration];
            
            if(self->_currentPreviewResolution == PreviewResolution540P){
                cameraCaptureSession.sessionPreset = AVCaptureSessionPresetiFrame960x540;
            } else if(self->_currentPreviewResolution == PreviewResolution1080P){
                cameraCaptureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
            } else {
                cameraCaptureSession.sessionPreset = AVCaptureSessionPreset1280x720;
            }
            
            AVCaptureDeviceInput *cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:self.cameraDevice error:nil];
            if ([cameraCaptureSession canAddInput:cameraInput]) {
                [cameraCaptureSession addInput:cameraInput];
            }
            // VideoDataOutput
            dispatch_queue_t videoDataQueue = dispatch_queue_create("com.tencent.youtu.videodata", NULL);
            self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
            self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
            self.videoDataOutput.videoSettings = @{(id) kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
            [self.videoDataOutput setSampleBufferDelegate:self queue:videoDataQueue];
            
            //设置帧率到30FPS
            int desiredFrameRate = 30;
            AVCaptureDeviceFormat *desiredFormat = nil;
            for ( AVCaptureDeviceFormat *format in [self.cameraDevice formats] ) {
              for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
                  if ( self.cameraDevice.activeFormat == format && range.maxFrameRate >= desiredFrameRate && range.minFrameRate <= desiredFrameRate ) {
                      desiredFormat = format;
                      break;
                  }
              }
              if (desiredFormat != nil) {
                  break;
              }
            }
            if ( desiredFormat ) {
              if ( [self.cameraDevice lockForConfiguration:NULL] == YES ) {
                  self.cameraDevice.activeVideoMinFrameDuration = CMTimeMake ( 1, desiredFrameRate );
                  self.cameraDevice.activeVideoMaxFrameDuration = CMTimeMake ( 1, desiredFrameRate );
                  [self.cameraDevice unlockForConfiguration];
              }
            }
            if ([cameraCaptureSession canAddOutput:self.videoDataOutput]) {
                [cameraCaptureSession addOutput:self.videoDataOutput];
            }
            cameraCaptureSession.usesApplicationAudioSession = YES;
            cameraCaptureSession.automaticallyConfiguresApplicationAudioSession = NO;
            [cameraCaptureSession commitConfiguration];
            for (AVCaptureOutput *output in cameraCaptureSession.outputs) {
                for (AVCaptureConnection *connection in output.connections) {
                    if (connection.isVideoOrientationSupported) {
                        connection.videoOrientation = AVCaptureVideoOrientationPortrait;
                    }
                    if (connection.isVideoMirroringSupported) {
                        connection.videoMirrored = cameraPosition == AVCaptureDevicePositionFront;
                    }
                }
            }
            if (cameraCaptureSession.inputs.count > 0 && cameraCaptureSession.outputs.count > 0) {
                [cameraCaptureSession startRunning];
            }
            self.captureSession = cameraCaptureSession;
        }
    }];
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (captureOutput == self.videoDataOutput) {
        [self mycaptureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection originImageProcess:YES];
    }
}

- (void)mycaptureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)inputSampleBuffer fromConnection:(AVCaptureConnection *)connection originImageProcess:(BOOL)originImageProcess
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(inputSampleBuffer);
    YTProcessOutput *output = [self.teBeautyKit processPixelData:pixelBuffer  withOrigin:YtLightImageOriginTopLeft withOrientation:YtLightCameraRotation0];
    if (output.pixelData.data != nil) {
        CVPixelBufferRef outPixelBuffer = output.pixelData.data;
        CMSampleBufferRef outSampleBuffer = [self sampleBufferFromPixelBuffer:output.pixelData.data];
        // 这里是处理进入后台后layer失效问题
        if (self.previewLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            [self.previewLayer flush];
        }
        if (outSampleBuffer != NULL) {
            [self.previewLayer enqueueSampleBuffer:outSampleBuffer];
            CFRelease(outSampleBuffer);
        }
    }
    
    if (output != nil) {
        output.pixelData = nil;
        output = nil;
    }
}

- (CMSampleBufferRef)sampleBufferFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CFRetain(pixelBuffer);
    CMSampleBufferRef outputSampleBuffer = NULL;
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timing, &outputSampleBuffer);

    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(outputSampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    
    CFRelease(videoInfo);
    CFRelease(pixelBuffer);
    return outputSampleBuffer;
}

@end
