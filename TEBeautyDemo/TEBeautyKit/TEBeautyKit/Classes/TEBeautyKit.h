//
//  TEBeautyKit.h
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/13.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "TEUIProperty.h"
#import <XMagic/XMagic.h>
@class TEBeautyKit;

static NSString * const kSandboxPrefix = @"{sandbox}";
static NSString * const kBundlePrefix = @"{bundle}";

typedef void(^OnInitListener)(TEBeautyKit * _Nullable beautyKit);

typedef void(^callback)(NSInteger authresult, NSString * _Nullable errorMsg);

@protocol TEBeautyKitAIDataListener <NSObject>

- (void)onAIEvent:(id _Nonnull)event;

@end

@protocol TEBeautyKitTipsListener <NSObject>

- (void)onTipsEvent:(id _Nonnull)event;

@end

@interface TEBeautyKit : NSObject

//正在生效的美颜
@property (nonatomic ,strong)NSMutableArray<TESDKParam *>* _Nullable usedSDKParam;

@property (nonatomic, strong)XMagic * _Nullable xmagicApi;

//创建TEBeautyKit对象
+ (void)create:(OnInitListener _Nullable )onInitListener DEPRECATED_MSG_ATTRIBUTE("Please use createXMagic:");

//创建TEBeautyKit对象
+ (void)createXMagic:(EffectMode)effectMode onInitListener:(OnInitListener _Nullable )onInitListener;

//创建TEBeautyKit对象
+ (void)create:(BOOL)isEnableHighPerformance onInitListener:(OnInitListener _Nullable )onInitListener DEPRECATED_MSG_ATTRIBUTE("Please use createXMagic:onInitListener:");

//美颜鉴权
+ (void)setTELicense:(NSString *)url key:(NSString *)key completion:(callback _Nullable )completion;

//设置美颜对象
- (void)setXMagicApi:(XMagic *_Nullable)xmagicApi;

//静音
- (void)setMute:(BOOL)isMute;

//开启能力
- (void)setFeatureEnableDisable:(NSString *_Nullable)featureName enable:(BOOL)enable;

/// 设置帧同步模式
/// @isSync 是否是同步
/// @syncFrameCount同步的帧数。-1表示无限制。如果isSync为false，则此参数无意义
- (void)setSyncMode:(BOOL)isSync syncFrameCount:(int)syncFrameCount;

+(DeviceLevel)getDeviceLevel;

//图片美颜
- (UIImage *_Nullable)processUIImage:(UIImage *_Nullable)inputImage
                 imageWidth:(int)imageWidth
                imageHeight:(int)imageHeight
                  needReset:(bool)needReset;

//处理texture
- (YTProcessOutput *_Nullable)processTexture:(unsigned int)textureId
         textureWidth:(int)textureWidth
        textureHeight:(int)textureHeight
           withOrigin:(YtLightImageOrigin)origin
      withOrientation:(YtLightDeviceCameraOrientation)orientation;

//处理CVPixelBufferRef
- (YTProcessOutput * _Nullable)processPixelData:(CVPixelBufferRef _Nullable )pixelData
                      pixelDataWidth:(int)pixelDataWidth
                     pixelDataHeight:(int)pixelDataHeight
                          withOrigin:(YtLightImageOrigin)origin
                     withOrientation:(YtLightDeviceCameraOrientation)orientation;

//设置美颜
- (void)setEffect:(TESDKParam *_Nullable)sdkParam;

//设置美颜
- (void)setEffectList:(NSArray<TESDKParam *>*_Nullable)sdkParamList;

//是否开启了美颜增强模式
- (BOOL)isEnableEnhancedMode;

//是否开启美颜增强模式
- (void)enableEnhancedMode:(BOOL)enable;

//获取正在使用的美颜数据
- (NSString *_Nullable)exportInUseSDKParam;

//恢复
- (void)onResume;

//暂停
- (void)onPause;

//销毁
- (void)onDestroy;

//获取当前texture的图片
- (void)exportCurrentTexture:(void (^_Nullable)(UIImage * _Nullable image))callback;

//设置log
- (void)setLogLevel:(YtSDKLoggerLevel)level;

//设置AIDataListener
- (void)setAIDataListener:(id<TEBeautyKitAIDataListener> _Nullable)listener;

//设置TipsListener
- (void)setTipsListener:(id<TEBeautyKitTipsListener> _Nullable)listener;

//保存设置的美颜数据
- (void)saveEffectParam:(TESDKParam *_Nonnull)sdkParam;

//删除某个保存的美颜数据
- (void)deleteEffectParam:(TESDKParam *_Nonnull)sdkParam;

//清空保存的美颜数据
- (void)clearEffectParam;

//获取保存的美颜数据
- (NSMutableArray<TESDKParam *> *_Nonnull)getInUseSDKParamList;

//是否开启美颜
- (void)enableBeauty:(BOOL)enable;
/**
 @brief SDK事件监听接口     SDK event monitoring interface
 @param listener 事件监听器回调，主要分为AI事件，Tips提示事件，Asset事件
 Event listener callback, mainly divided into AI events, Tips reminder events, Asset events
 */
- (void)registerSDKEventListener:(id<YTSDKEventListener> _Nullable)listener;

/// @brief 注册回调清理接口     Register callback cleanup interface
- (void)clearListeners;


@end
