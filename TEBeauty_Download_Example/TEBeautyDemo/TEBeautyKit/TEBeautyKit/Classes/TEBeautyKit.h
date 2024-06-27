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
@class TEPanelView;

static NSString * const kSandboxPrefix = @"{sandbox}";
static NSString * const kBundlePrefix = @"{bundle}";

typedef void(^OnInitListener)(XMagic * _Nullable api);
typedef void(^callback)(NSInteger authresult, NSString * _Nullable errorMsg);

@protocol TEBeautyKitAIDataListener <NSObject>

- (void)onAIEvent:(id _Nonnull)event;

@end

@protocol TEBeautyKitTipsListener <NSObject>

- (void)onTipsEvent:(id _Nonnull)event;

@end

@interface TEBeautyKit : NSObject

// The beauty param that is working
@property (nonatomic ,strong)NSMutableArray<TESDKParam *>* _Nullable usedSDKParam;

// create TEBeautyKit instance
+ (void)create:(OnInitListener _Nullable )onInitListener;

// create TEBeautyKit instance
+ (void)create:(BOOL)isEnableHighPerformance onInitListener:(OnInitListener _Nullable )onInitListener;

// Beauty authentication
+ (void)setTELicense:(NSString *)url key:(NSString *)key completion:(callback _Nullable )completion;

// set beauty instance
- (void)setXMagicApi:(XMagic *_Nullable)xmagicApi;

// Mute
- (void)setMute:(BOOL)isMute;

// Set a feature on or off
- (void)setFeatureEnableDisable:(NSString *_Nullable)featureName enable:(BOOL)enable;

- (UIImage *_Nullable)processUIImage:(UIImage *_Nullable)inputImage
                 imageWidth:(int)imageWidth
                imageHeight:(int)imageHeight
                  needReset:(bool)needReset;

- (YTProcessOutput *_Nullable)processTexture:(int)textureId
         textureWidth:(int)textureWidth
        textureHeight:(int)textureHeight
           withOrigin:(YtLightImageOrigin)origin
      withOrientation:(YtLightDeviceCameraOrientation)orientation;

- (YTProcessOutput * _Nullable)processPixelData:(CVPixelBufferRef _Nullable )pixelData
                          withOrigin:(YtLightImageOrigin)origin
                     withOrientation:(YtLightDeviceCameraOrientation)orientation;

- (void)setEffect:(TESDKParam *_Nullable)sdkParam;

- (void)setEffectList:(NSArray<TESDKParam *>*_Nullable)sdkParamList;

- (BOOL)isEnableEnhancedMode;

- (void)enableEnhancedMode:(BOOL)enable;

- (NSString *_Nullable)exportInUseSDKParam;

- (void)onResume;

- (void)onPause;

- (void)onDestroy;

- (void)exportCurrentTexture:(void (^_Nullable)(UIImage * _Nullable image))callback;

- (void)setLogLevel:(YtSDKLoggerLevel)level;

- (void)setAIDataListener:(id<TEBeautyKitAIDataListener> _Nullable)listener;

- (void)setTipsListener:(id<TEBeautyKitTipsListener> _Nullable)listener;

- (void)saveEffectParam:(TESDKParam *_Nonnull)sdkParam;

- (void)deleteEffectParam:(TESDKParam *_Nonnull)sdkParam;

- (void)clearEffectParam;

- (NSMutableArray<TESDKParam *> *_Nonnull)getInUseSDKParamList;

- (void)setTePanelView:(TEPanelView *)tePanelView;

@end
