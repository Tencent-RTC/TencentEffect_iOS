//
//  TEBeautyKit.m
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/13.
//

#import "TEBeautyKit.h"
#import <YTCommonXMagic/TELicenseCheck.h>
#import "View/TEPanelView.h"
#import "TEUIConfig.h"

static int TEXTUREWIDTH = 720;
static int TEXTUREHIGHT = 1280;

@interface TEBeautyKit()<YTSDKEventListener, YTSDKLogListener,TEPanelViewDelegate>
@property (nonatomic, strong)XMagic *xmagicApi;
@property (nonatomic, assign)BOOL enableEnhancedMode;
@property (nonatomic, weak)id<TEBeautyKitAIDataListener> aiDataListener;
@property (nonatomic, weak)id<TEBeautyKitTipsListener> tipsListener;
@property (nonatomic, weak)TEPanelView *tePanelView;
@property (nonatomic, assign)BOOL showOrigin;

@end


@implementation TEBeautyKit

+ (void)create:(OnInitListener _Nullable )onInitListener{
    [self create:NO onInitListener:onInitListener];
}

+ (void)create:(BOOL)isEnableHighPerformance onInitListener:(OnInitListener)onInitListener{
    NSString *corePath = [[TEUIConfig shareInstance] getLightCoreBundlePath];
    if (corePath == nil) {
        corePath = [[NSBundle mainBundle] bundlePath];
    }
    NSDictionary *assetsDict = @{@"core_name":@"LightCore.bundle",
                                 @"root_path":corePath,
                                 @"setDowngradePerformance":@(isEnableHighPerformance)
    };
    if(onInitListener != nil){
        onInitListener([[XMagic alloc] initWithRenderSize:CGSizeMake(TEXTUREWIDTH, TEXTUREHIGHT) assetsDict:assetsDict]);
    }
}

+ (void)setTELicense:(NSString *)url key:(NSString *)key completion:(callback)completion{
    [TELicenseCheck setTELicense:url key:key completion:^(NSInteger authresult, NSString * _Nonnull errorMsg) {
        NSLog(@"license check: %zd  %@",authresult,errorMsg);
        if(completion){
            completion(authresult,errorMsg);
        }
    }];
}

- (void)setXMagicApi:(XMagic *_Nullable)xmagicApi{
    self.xmagicApi = xmagicApi;
}

- (UIImage *)processUIImage:(UIImage *)inputImage imageWidth:(int)imageWidth imageHeight:(int)imageHeight needReset:(bool)needReset{
    if(self.showOrigin){
        return inputImage;
    }
    if(self.xmagicApi != nil && (imageWidth != TEXTUREWIDTH || imageHeight != TEXTUREHIGHT)){
        TEXTUREWIDTH = imageWidth;
        TEXTUREHIGHT = imageHeight;
        [self.xmagicApi setRenderSize:CGSizeMake(imageWidth, imageHeight)];
    }
    return [self.xmagicApi processUIImage:inputImage needReset:needReset];
}

- (YTProcessOutput *)processTexture:(int)textureId
         textureWidth:(int)textureWidth
        textureHeight:(int)textureHeight
           withOrigin:(YtLightImageOrigin)origin
      withOrientation:(YtLightDeviceCameraOrientation)orientation{
    if(self.showOrigin){
        YTProcessOutput *output = [[YTProcessOutput alloc] init];
        output.textureData = [[YTTextureData alloc] init];
        output.textureData.texture = textureId;
        output.textureData.textureWidth = textureWidth;
        output.textureData.textureHeight = textureHeight;
        return output;
    }
    if(self.xmagicApi != nil && (textureWidth != TEXTUREWIDTH || textureHeight != TEXTUREHIGHT)){
        TEXTUREWIDTH = textureWidth;
        TEXTUREHIGHT = textureHeight;
        [self.xmagicApi setRenderSize:CGSizeMake(textureWidth, textureHeight)];
    }
    YTProcessInput *input = [[YTProcessInput alloc] init];
    input.textureData = [[YTTextureData alloc] init];
    input.textureData.texture = textureId;
    input.textureData.textureWidth = textureWidth;
    input.textureData.textureHeight = textureHeight;
    input.dataType = kYTTextureData;
    
    YTProcessOutput * output = [self.xmagicApi process:input withOrigin:origin withOrientation:orientation];
    return output;
}

- (YTProcessOutput *)processPixelData:(CVPixelBufferRef)pixelData
                          withOrigin:(YtLightImageOrigin)origin
                     withOrientation:(YtLightDeviceCameraOrientation)orientation{
    if(self.showOrigin){
        YTProcessOutput *output = [[YTProcessOutput alloc] init];
        output.pixelData = [[YTImagePixelData alloc] init];
        output.pixelData.data = pixelData;
        output.dataType = kYTImagePixelData;
        return output;
    }
    int pixelDataWidth = (int)CVPixelBufferGetWidth(pixelData);
    int pixelDataHeight = (int)CVPixelBufferGetHeight(pixelData);
    if(self.xmagicApi != nil && (pixelDataWidth != TEXTUREWIDTH || pixelDataHeight != TEXTUREHIGHT)){
        TEXTUREWIDTH = pixelDataWidth;
        TEXTUREHIGHT = pixelDataHeight;
        [self.xmagicApi setRenderSize:CGSizeMake(pixelDataWidth, pixelDataHeight)];
    }
    YTProcessInput *input = [[YTProcessInput alloc] init];
    input.pixelData = [[YTImagePixelData alloc] init];
    input.pixelData.data = pixelData;
    input.dataType = kYTImagePixelData;
    YTProcessOutput * output = [self.xmagicApi process:input withOrigin:origin withOrientation:orientation];
    return output;
}

- (NSString *)convertCustomPrefixToPath:(NSString *)path {
    if ([path hasPrefix:kSandboxPrefix]) {
        return [path stringByReplacingOccurrencesOfString:kSandboxPrefix withString:NSHomeDirectory()];
    } else if ([path hasPrefix:kBundlePrefix]) {
        return [path stringByReplacingOccurrencesOfString:kBundlePrefix withString:[[NSBundle mainBundle] bundlePath]];
    }
    return path;
}

- (void)setEffect:(TESDKParam *)sdkParam{
    [self.xmagicApi setEffect:sdkParam.effectName effectValue:sdkParam.effectValue resourcePath:[self convertCustomPrefixToPath:sdkParam.resourcePath] extraInfo:sdkParam.extraInfoDic];
    [self saveEffectParam:sdkParam];
}

- (void)setEffectList:(NSArray<TESDKParam *> *)sdkParamList{
    for (TESDKParam *param in sdkParamList) {
        [self setEffect:param];
    }
}

- (void)exportCurrentTexture:(void (^)(UIImage *image))callback{
    [self.xmagicApi exportCurrentTexture:^(UIImage * _Nullable image) {
        if(callback != nil){
            callback(image);
        }
    }];
}

- (BOOL)isEnableEnhancedMode{
    return self.enableEnhancedMode;
}

- (void)enableEnhancedMode:(BOOL)enable{
    self.enableEnhancedMode = enable;
    
}

- (void)onPause{
    [self.xmagicApi onPause];
}

- (void)onResume{
    [self.xmagicApi onResume];
}

- (void)onDestroy{
    [self.xmagicApi deinit];
}

- (void)setLogLevel:(YtSDKLoggerLevel)level{
    [self.xmagicApi registerLoggerListener:self withDefaultLevel:level];
}

- (void)setMute:(BOOL)isMute{
    [self.xmagicApi setAudioMute:isMute];
}

- (void)setFeatureEnableDisable:(NSString *)featureName enable:(BOOL)enable{
    [self.xmagicApi setFeatureEnableDisable:featureName enable:enable];
}

- (void)setAIDataListener:(id<TEBeautyKitAIDataListener>)listener{
    self.aiDataListener = listener;
    [self.xmagicApi registerSDKEventListener:self];
}

- (void)setTipsListener:(id<TEBeautyKitTipsListener>)listener{
    self.tipsListener = listener;
    [self.xmagicApi registerSDKEventListener:self];
}

- (void)onAIEvent:(id _Nonnull)event {
    if([self.aiDataListener respondsToSelector:@selector(onAIEvent:)]){
        [self.aiDataListener onAIEvent:event];
    }
}

- (void)onTipsEvent:(id _Nonnull)event {
    if([self.tipsListener respondsToSelector:@selector(onTipsEvent:)]){
        [self.tipsListener onTipsEvent:event];
    }
}

- (void)setTePanelView:(TEPanelView *)tePanelView{
    _tePanelView = tePanelView;
    _tePanelView.delegate = self;
}


- (void)saveEffectParam:(TESDKParam *)sdkParam{
    if(!_usedSDKParam){
        _usedSDKParam = [NSMutableArray array];
    }
    for (TESDKParam *param in _usedSDKParam) {
        if([param.effectName isEqualToString:sdkParam.effectName]){
            [_usedSDKParam removeObject:param];
            break;
        }
    }
    [_usedSDKParam addObject:sdkParam];
}

- (void)deleteEffectParam:(TESDKParam *)sdkParam{
    for (TESDKParam *param in _usedSDKParam) {
        if([param.effectName isEqualToString:sdkParam.effectName]){
            [_usedSDKParam removeObject:param];
            return;
        }
    }
}

- (void)clearEffectParam{
    [_usedSDKParam removeAllObjects];
}

- (NSMutableArray<TESDKParam *> *)getInUseSDKParamList{
    return _usedSDKParam.mutableCopy;
}

- (NSString *)exportInUseSDKParam {
    if (_usedSDKParam.count == 0) {
        return nil;
    }
    NSMutableArray *jsonArray = [NSMutableArray arrayWithCapacity:_usedSDKParam.count];
    for (TESDKParam *param in _usedSDKParam) {
        [jsonArray addObject:[param toDictionary]];
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArray options:NSJSONWritingPrettyPrinted error:&error];
    if (!jsonData) {
        NSLog(@"Error converting _usedSDKParam to JSON: %@", error.localizedDescription);
        return nil;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


- (void)onLog:(YtSDKLoggerLevel)loggerLevel withInfo:(NSString * _Nonnull)logInfo {
    NSLog(@"[%ld]-%@", (long)loggerLevel, logInfo);
}

- (void)showBeautyChanged:(BOOL)open{
    self.showOrigin = !open;
}

@end
