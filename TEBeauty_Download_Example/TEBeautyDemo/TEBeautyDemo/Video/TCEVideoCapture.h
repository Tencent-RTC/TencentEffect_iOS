//
//  TEVideoCapture.h
//  BeautyUI
//
//  Created by jasonggao on 2025/8/1.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TCEVideoCaptureResolution) {
    TCEVideoCaptureResolution_540P,
    TCEVideoCaptureResolution_720P,
    TCEVideoCaptureResolution_1080P,
};

typedef NS_ENUM(NSUInteger, TCEVideoCapturePixelFormat) {
    TCEVideoCapturePixelFormat_BGRA,            // kCVPixelFormatType_32BGRA（默认）
    TCEVideoCapturePixelFormat_NV12_FullRange,  // kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    TCEVideoCapturePixelFormat_NV12_VideoRange, // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
};

@protocol TCEVideoCaptureDelegate <NSObject>
@optional
- (void)videoCaptureDidOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

@interface TCEVideoCapture : NSObject
@property (nonatomic, weak) id<TCEVideoCaptureDelegate> delegate;
@property (nonatomic, assign) TCEVideoCaptureResolution resolution;
@property (nonatomic, assign) TCEVideoCapturePixelFormat pixelFormat;
@property (nonatomic, strong, readonly) dispatch_queue_t videoDataOutputQueue;

/// 开启摄像头
- (void)startRunning;
/// 关闭摄像头
- (void)stopRunning;
/// 获取分辨率对应的size
- (CGSize)getReolutionSize:(TCEVideoCaptureResolution)resolution;

#if TARGET_OS_OSX
/// Mac: 可用摄像头列表
@property (nonatomic, strong, readonly) NSArray<AVCaptureDevice *> *availableCameras;
/// Mac: 当前摄像头
@property (nonatomic, strong, readonly) AVCaptureDevice *currentCamera;
/// Mac: 切换到指定摄像头
- (void)switchToCamera:(AVCaptureDevice *)device;
/// Mac: 刷新可用摄像头列表
- (void)refreshAvailableCameras;
#else
@property (nonatomic, assign, readonly) AVCaptureDevicePosition devicePosition;
/// iOS: 是否镜像（仅前置摄像头有效，默认 YES）
@property (nonatomic, assign) BOOL mirrored;
/// iOS: 切换前后摄像头
- (void)switchCamera;
#endif

@end

NS_ASSUME_NONNULL_END
