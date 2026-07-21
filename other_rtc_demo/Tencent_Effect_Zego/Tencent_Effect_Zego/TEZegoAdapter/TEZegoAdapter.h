//
//  TEZegoAdapter.h
//  Tencent_Effect_Zego
//
//  Created by jasonggao on 2025/11/10.
//

#import <UIKit/UIKit.h>
#import <XMagic/XMagic.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^OnCreatedXMagic)(XMagic *_Nullable xmagic);
typedef void (^OnDestroyedXMagic)(void);

typedef NS_ENUM(NSUInteger, ImageStartPosition) {
    TOP,        /// 图像开始方向在上
    RIGHT,      /// 图像开始方向在右
    BOTTOM,     /// 图像开始方向在下
    LEFT,       /// 图像开始方向在左
};

typedef NS_ENUM(NSUInteger, VideoMirrorType) {
    AUTO,      /// 自动模式：如果正使用前置摄像头则开启镜像，如果是后置摄像头则不开启镜像（仅适用于移动设备）
    ENABLE,    /// 强制开启镜像，不论当前使用的是前置摄像头还是后置摄像头
    DISABLE    /// 强制关闭镜像，不论当前使用的是前置摄像头还是后置摄像头
};

@interface TEZegoAdapter : NSObject
/// lightCore本地路径
@property(nonatomic, copy) NSString *lightCoreBundlePath;
/// 是否开启美颜，默认YES
@property (nonatomic, assign) BOOL enableBeauty;

/// 初始化
/// @param effectMode 是否开启高性能模式
- (instancetype)initWithEffectMode:(EffectMode)effectMode;

/// 将美颜与Zego绑定
/// pusher  zego
/// @param onCreatedXMagic 绑定成功之后的回调，会返回美颜对象
/// @param onDestroyedXMagic 解除绑定之后的回调
- (void)bind:(id)pusher onCreatedXMagic:(OnCreatedXMagic _Nullable)onCreatedXMagic onDestroyedXMagic:(OnDestroyedXMagic _Nullable)onDestroyedXMagic;

/// 解除绑定
- (void)unbind;

@end

NS_ASSUME_NONNULL_END
