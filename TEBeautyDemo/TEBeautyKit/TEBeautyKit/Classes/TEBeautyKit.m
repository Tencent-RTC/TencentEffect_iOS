//
//  TEBeautyKit.m
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/13.
//

#import "TEBeautyKit.h"
#import <YTCommonXMagic/TELicenseCheck.h>
#import "View/TEPanelView.h"

@interface TEBeautyKit()<YTSDKEventListener, YTSDKLogListener>
@property (nonatomic, assign)int  textureWidth;
@property (nonatomic, assign)int  textureHeight;
@property (nonatomic, assign)BOOL enableEnhancedMode;
@property (nonatomic, weak)id<TEBeautyKitAIDataListener> aiDataListener;
@property (nonatomic, weak)id<TEBeautyKitTipsListener> tipsListener;
@property (nonatomic, assign)BOOL enableBeauty;

@end


@implementation TEBeautyKit

+ (void)createXMagic:(EffectMode)effectMode onInitListener:(OnInitListener)onInitListener{
    NSDictionary *assetsDict = @{@"core_name":@"LightCore.bundle",
                                 @"root_path":[[NSBundle mainBundle] bundlePath],
                                 @"effect_mode":@(effectMode)
    };
    if(onInitListener != nil){
        TEBeautyKit * kit = [[TEBeautyKit alloc] init];
        kit.xmagicApi = [[XMagic alloc] initWithRenderSize:CGSizeMake(720, 1280) assetsDict:assetsDict];
        onInitListener(kit);
    }
    
}

+ (void)create:(OnInitListener _Nullable )onInitListener{
    [self create:NO onInitListener:onInitListener];
}

+ (void)create:(BOOL)isEnableHighPerformance onInitListener:(OnInitListener)onInitListener{
    EffectMode effectMode;
    if (isEnableHighPerformance) {
        effectMode = EFFECT_MODE_NORMAL;
    }else{
        effectMode = EFFECT_MODE_PRO;
    }
    NSDictionary *assetsDict = @{@"core_name":@"LightCore.bundle",
                                 @"root_path":[[NSBundle mainBundle] bundlePath],
                                 @"effect_mode":@(effectMode)
    };
    if(onInitListener != nil){
        TEBeautyKit * kit = [[TEBeautyKit alloc] init];
        kit.xmagicApi = [[XMagic alloc] initWithRenderSize:CGSizeMake(720, 1280) assetsDict:assetsDict];
        onInitListener(kit);
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

-(instancetype)init{
    self = [super init];
        if (self) {
            self.enableBeauty = YES;
        }
     return self;
}

- (void)setXMagicApi:(XMagic *_Nullable)xmagicApi{
    self.xmagicApi = xmagicApi;
}

- (UIImage *)processUIImage:(UIImage *)inputImage imageWidth:(int)imageWidth imageHeight:(int)imageHeight needReset:(bool)needReset{
    if(!self.enableBeauty){
        return inputImage;
    }
    if(self.xmagicApi != nil && (imageWidth != self.textureWidth || imageHeight != self.textureHeight)){
        self.textureWidth = imageWidth;
        self.textureHeight = imageHeight;
        [self.xmagicApi setRenderSize:CGSizeMake(imageWidth, imageHeight)];
    }
    return [self.xmagicApi processUIImage:inputImage needReset:needReset];
}

- (YTProcessOutput *)processTexture:(unsigned int)textureId
         textureWidth:(int)textureWidth
        textureHeight:(int)textureHeight
           withOrigin:(YtLightImageOrigin)origin
      withOrientation:(YtLightDeviceCameraOrientation)orientation{
    if(!self.enableBeauty){
        YTProcessOutput *output = [[YTProcessOutput alloc] init];
        output.textureData = [[YTTextureData alloc] init];
        output.textureData.texture = textureId;
        output.textureData.textureWidth = textureWidth;
        output.textureData.textureHeight = textureHeight;
        return output;
    }
    if(self.xmagicApi != nil && (textureWidth != self.textureWidth || textureHeight != self.textureHeight)){
        self.textureWidth = textureWidth;
        self.textureHeight = textureHeight;
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
                      pixelDataWidth:(int)pixelDataWidth
                     pixelDataHeight:(int)pixelDataHeight
                          withOrigin:(YtLightImageOrigin)origin
                     withOrientation:(YtLightDeviceCameraOrientation)orientation{
    if(!self.enableBeauty){
        YTProcessOutput *output = [[YTProcessOutput alloc] init];
        output.pixelData = [[YTImagePixelData alloc] init];
        output.pixelData.data = pixelData;
        output.dataType = kYTImagePixelData;
        return output;
    }
    if(self.xmagicApi != nil && (pixelDataWidth != self.textureWidth || pixelDataHeight != self.textureHeight)){
        self.textureWidth = pixelDataWidth;
        self.textureHeight = pixelDataHeight;
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
    if(_xmagicApi) {
        [self.xmagicApi enableEnhancedMode];
    }
    
}

- (void)onPause{
    [self.xmagicApi onPause];
}

- (void)onResume{
    [self.xmagicApi onResume];
}

- (void)onDestroy{
    if(self.xmagicApi){
        [self.xmagicApi deinit];
        self.xmagicApi = nil;
    }
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

- (void)setSyncMode:(BOOL)isSync syncFrameCount:(int)syncFrameCount{
    [self.xmagicApi setSyncMode:isSync syncFrameCount:syncFrameCount];
}

+(DeviceLevel)getDeviceLevel{
    return [XMagic getDeviceLevel];
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

- (void)enableBeauty:(BOOL)enable{
    self.enableBeauty = enable;
}

- (void) registerSDKEventListener:(id<YTSDKEventListener>)listener {
    if(self.xmagicApi) {
        [self.xmagicApi registerSDKEventListener:listener];
    }
}
- (void) clearListeners {
    if(self.xmagicApi) {
        [self.xmagicApi clearListeners];
    }
}


@end
