//
//  TEBeautyLiveAdapter.h
//  TELiveAdapter
//
//  Created by tao yue on 2024/4/21.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <XMagic/TEDefine.h>
#import <AgoraRtcKit/AgoraRtcKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TEBeautyKit;
@class XMagic;

typedef void (^OnCreatedXmagicApi)(XMagic * _Nullable xmagicApi);
typedef void (^OnDestroyXmagicApi)(void);


@interface TEAgoraAdapter : NSObject
/// lightCore本地路径
@property (nonatomic, copy) NSString *lightCoreBundlePath;
/// 是否开启美颜，默认YES
@property (nonatomic, assign) BOOL enableBeauty;

/// 初始化
/// @param effectMode 是否开启高性能模式
- (instancetype)initWithEffectMode:(EffectMode)effectMode;

/// 将美颜与agoraEngine进行绑定
/// @param pusher agoraEngine
/// @param onCreatedXmagicApi 绑定成功之后的回调，会返回美颜对象
/// @param onDestroyXmagicApi 解除绑定之后的回调
- (void)bind:(id _Nonnull)pusher onCreatedXmagicApi:(OnCreatedXmagicApi _Nullable)onCreatedXmagicApi onDestroyXmagicApi:(OnDestroyXmagicApi _Nullable)onDestroyXmagicApi;

/// 解除绑定
- (void)unbind;

/// 本地摄像头采集回调
/// @param videoFrame 视频帧
/// @param sourceType 采集类型
- (BOOL)onCaptureVideoFrame:(AgoraOutputVideoFrame *)videoFrame sourceType:(AgoraVideoSourceType)sourceType;

@end

NS_ASSUME_NONNULL_END
