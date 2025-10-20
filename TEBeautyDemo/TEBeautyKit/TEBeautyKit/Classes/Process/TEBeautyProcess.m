//
//  TEBeautyProcess.m
//  TEBeautyKit
//
//  Created by wwk on 2025/9/9.
//

#import "TEBeautyProcess.h"
#import "TEUtils.h"
#import "TEUIDefine.h"
#import <XMagic/XmagicConstant.h>
#import "TEDownloader.h"
#import "TEUIConfig.h"
#import "TECommonDefine.h"

// 视频长度限制(ms)
static const int MAX_SEG_VIDEO_DURATION = 200 * 1000;

@interface TEBeautyProcess()
@property (nonatomic, assign) int segmentationBgType;                  // 背景分割类型
@property (nonatomic, assign) int segmentationType;                    // 分割算法类型
@property (nonatomic, copy) NSString* segmentationResPath;            // 分割资源路径
@property (nonatomic, copy) NSString* segmentationPath;               // 分割模型路径
@property (nonatomic, assign) BOOL lightMakeupUsed;                    // 轻美妆使用状态
@property (nonatomic, copy) NSString* mergeCurMotion;                  // 当前合并动画路径
@property (nonatomic, strong) NSNumber* timeOffset;                    // 时间偏移量

@property (nonatomic, strong) NSMutableArray<TEUIProperty *> *defaultBeautyList;    // 默认美颜配置列表
@property (nonatomic, strong) NSMutableArray<NSString *> *beautyMakeupEffectNames; // 单点美妆效果名称列表

@end

@implementation TEBeautyProcess


#pragma mark - 更新特效
- (void)updateBeautyEffect:(TEUIProperty *)teUIProperty{
    if(self.self.currentUIPropertyList[beautyType].teCategory == TECategory_BEAUTY){
        if(self.lightMakeupUsed && [self.beautyMakeupEffectNames containsObject:teUIProperty.sdkParam.effectName]){
            [self clearLightMakeup];
            [self clearLastBeautyUi:TECategory_LIGHTMAKEUP];
            self.lightMakeupUsed = NO;
        }
        if(teUIProperty.sdkParam == nil){ //关闭美颜
            [self setBeautyUIState:self.currentUIPropertyList[beautyType].propertyList uiState:TEUIState_INIT];
            [self setBeautyWithTEUIPropertyList:self.currentUIPropertyList[beautyType].propertyList];
            NSMutableArray<TESDKParam *> *sdkParamList = [_teBeautyKit getInUseSDKParamList];
            for (TESDKParam *sdkParam in sdkParamList) {
                if ([self isBeauty:sdkParam.effectName] && [teUIProperty.abilityType isEqualToString:sdkParam.abilityType]) {
                    sdkParam.effectValue = 0;
                    [_teBeautyKit setEffect:sdkParam];
                }
            }
            teUIProperty.uiState = 2;
            if ([self.delegate respondsToSelector:@selector(beautyCollectionRreloadData)]) {
                [self.delegate beautyCollectionRreloadData];
            }
        }
        if ([self.tePanelDataProvider.exclusionNoneGroup containsObject:teUIProperty.sdkParam.effectName] &&
            teUIProperty.sdkParam.resourcePath.length == 0 &&
            teUIProperty.sdkParam.effectValue == 0) {
            if ([self.delegate respondsToSelector:@selector(teSliderIsHidden)]) {
                [self.delegate teSliderIsHidden];
            }
        }
        [self setBeauty:teUIProperty.sdkParam.effectName effectValue:teUIProperty.sdkParam.effectValue resourcePath:teUIProperty.sdkParam.resourcePath extraInfo:nil abilityType:teUIProperty.abilityType save:YES];
    }else if(self.currentUIProperty.teCategory == TECategory_LUT){
        if(self.lightMakeupUsed){
            [self clearLightMakeup];
            [self clearLastBeautyUi:TECategory_LIGHTMAKEUP];
            self.lightMakeupUsed = NO;
        }
        if ([TEUtils isURL:teUIProperty.resourceUri]) {
            NSString *path = [self fileExits:teUIProperty.resourceUri dirPath:self.currentUIProperty.downloadPath];
            if (path != nil) {
                [self setBeauty:EFFECT_LUT effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:nil abilityType:teUIProperty.abilityType save:YES];
            }else{
                [self downloadRes:EFFECT_LUT teUIProperty:teUIProperty];
            }
        }else{
            NSString *path = [[[NSBundle mainBundle] pathForResource:@"lut" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            if (teUIProperty.resourceUri == nil) {
                path = nil;
            }
            [self setBeauty:EFFECT_LUT effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:nil abilityType:teUIProperty.abilityType save:YES];
        }
    }else if (self.currentUIProperty.teCategory == TECategory_LIGHTMAKEUP){
        if (teUIProperty.resourceUri == nil) {
            self.lightMakeupUsed = NO;
        }else{
            self.lightMakeupUsed = YES;
        }
        [self clearLastBeautyUi:TECategory_BEAUTY];
        [self clearLastBeautyUi:TECategory_LUT];
        if ([TEUtils isURL:teUIProperty.resourceUri]) {
            NSString *path = [self fileExits:teUIProperty.resourceUri dirPath:self.currentUIProperty.downloadPath];
            if (path != nil) {
                NSString *makeupLutStrength = teUIProperty.sdkParam.extraInfo.makeupLutStrength;
                NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
                extraInfo[@"makeupLutStrength"] = makeupLutStrength;
                [self setBeauty:EFFECT_LIGHT_MAKEUP effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:extraInfo abilityType:teUIProperty.abilityType save:YES];
            }else{
                [self downloadRes:EFFECT_LIGHT_MAKEUP teUIProperty:teUIProperty];
            }
        }else{
            NSString *path = [[[NSBundle mainBundle] pathForResource:@"lightMakeupRes" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            if (teUIProperty.resourceUri == nil) {
                path = nil;
            }
            NSString *makeupLutStrength = teUIProperty.sdkParam.extraInfo.makeupLutStrength;
            NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
            extraInfo[@"makeupLutStrength"] = makeupLutStrength;
            [self setBeauty:EFFECT_LIGHT_MAKEUP effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:extraInfo abilityType:teUIProperty.abilityType save:YES];
        }
    }else if (self.currentUIProperty.teCategory == TECategory_MOTION){
        if ([TEUtils isURL:teUIProperty.resourceUri]) {
            NSString *path = [self fileExits:teUIProperty.resourceUri dirPath:self.currentUIPropertyList[beautyType].downloadPath];
            if (path != nil) {
                NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
                extraInfo[@"mergeWithCurrentMotion"] = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
                [self setBeauty:EFFECT_MOTION effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:extraInfo abilityType:teUIProperty.abilityType save:YES];
            }else{
                [self downloadRes:EFFECT_MOTION teUIProperty:teUIProperty];
            }
        }else{
            NSString *path = [[[NSBundle mainBundle] pathForResource:@"2dMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                path = [[[NSBundle mainBundle] pathForResource:@"3dMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            }
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                path = [[[NSBundle mainBundle] pathForResource:@"handMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            }
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                path = [[[NSBundle mainBundle] pathForResource:@"ganMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            }
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                NSLog(@"error: %@ not found",path);
                return;
            }
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            dic[@"mergeWithCurrentMotion"] = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
            if (teUIProperty.resourceUri == nil) {
                path = nil;
            }
            [self setBeauty:EFFECT_MOTION effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:dic abilityType:teUIProperty.abilityType save:YES];
        }
    }else if (self.currentUIProperty.teCategory == TECategory_MAKEUP){
        if ([TEUtils isURL:teUIProperty.resourceUri]) {
            NSString *path = [self fileExits:teUIProperty.resourceUri dirPath:self.currentUIPropertyList[beautyType].downloadPath];
            if (path != nil) {
                NSString *makeupLutStrength = teUIProperty.sdkParam.extraInfo.makeupLutStrength;
                NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
                extraInfo[@"makeupLutStrength"] = makeupLutStrength;
                extraInfo[@"mergeWithCurrentMotion"] = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
                [self setBeauty:EFFECT_MAKEUP effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:extraInfo abilityType:teUIProperty.abilityType save:YES];
            }else{
                [self downloadRes:EFFECT_MAKEUP teUIProperty:teUIProperty];
            }
        }else{
            NSString *path = [[[NSBundle mainBundle] pathForResource:@"makeupMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                NSLog(@"error: %@ not found",path);
                return;
            }
            NSString *makeupLutStrength = teUIProperty.sdkParam.extraInfo.makeupLutStrength;
            NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
            extraInfo[@"makeupLutStrength"] = makeupLutStrength;
            extraInfo[@"mergeWithCurrentMotion"] = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
            if (teUIProperty.resourceUri == nil) {
                path = nil;
            }
            [self setBeauty:EFFECT_MAKEUP effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:extraInfo abilityType:teUIProperty.abilityType save:YES];
        }
    }else if (self.currentUIPropertyList[beautyType].teCategory == TECategory_SEGMENTATION ||
              self.currentUIProperty.teCategory == TECategory_SEGMENTATION){
        if ([TEUtils isURL:teUIProperty.resourceUri]) {
            NSString *path = [self fileExits:teUIProperty.resourceUri dirPath:self.currentUIPropertyList[beautyType].downloadPath];
            if (path != nil) {
                NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
                extraInfo[@"mergeWithCurrentMotion"] = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
                [self setBeauty:EFFECT_SEGMENTATION effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:extraInfo abilityType:teUIProperty.abilityType save:YES];
            }else{
                [self downloadRes:EFFECT_SEGMENTATION teUIProperty:teUIProperty];
            }
        }else{
            NSString *path = [[[NSBundle mainBundle] pathForResource:@"segmentMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                NSLog(@"error: %@ not found",path);
                return;
            }
            if (teUIProperty.resourceUri == nil) {
                path = nil;
            }
            [self setSegmentation:path teUIProperty:teUIProperty];
        }
    }
}

//清理特定索引开始的美颜特效对应的UI
- (void)clearLastBeautyUi:(TECategory)teCategory{
    for(TEUIProperty *property in self.currentUIPropertyList){
        if(property.teCategory == teCategory){
            if(teCategory == TECategory_BEAUTY){//需要清理美颜里面的单点美妆的UI
                for(TEUIProperty *model in property.propertyList){
                    if([self.beautyMakeupEffectNames containsObject:model.propertyList[0].sdkParam.effectName] ){
                        if([model.displayName isEqualToString:@"染发"]){
                            [self setBeautySingleUIState:model uiState:TEUIState_IN_USE];
                        }else{
                            [self setBeautySingleUIState:model uiState:TEUIState_INIT];
                            [self setBeautyUIState:model.propertyList uiState:TEUIState_INIT];
                        }
                    }
                }
            }else{
                for(TEUIProperty *model in property.propertyList){
                    [self setBeautySingleUIState:model uiState:TEUIState_INIT];
                    [self setBeautyUIState:model.propertyList uiState:TEUIState_INIT];
                }
            }
        }
    }
}


-(void)downloadRes:(NSString *)category teUIProperty:(TEUIProperty *)teUIProperty{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        //[strongSelf showLoading];
        if ([strongSelf.delegate respondsToSelector:@selector(teShowLoading)]) {
            [strongSelf.delegate teShowLoading];
        }
    });
    [[TEDownloader shardManager] download:teUIProperty.resourceUri destinationURL:self.currentUIProperty.downloadPath progressBlock:^(CGFloat progress) {
        if ([self.delegate respondsToSelector:@selector(TEDownloaderProgressBlock:)]) {
            [self.delegate TEDownloaderProgressBlock:progress];
        }
    } successBlock:^(BOOL success, NSString *downloadFileLocalPath) {
        if ([self.delegate respondsToSelector:@selector(teDismissLoading)]) {
            [self.delegate teDismissLoading];
        }
        if (!success) {
            return;
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if([category isEqualToString:EFFECT_SEGMENTATION]){
            [strongSelf setSegmentation:downloadFileLocalPath teUIProperty:teUIProperty];
            return;
        }
        NSString *makeupLutStrength = teUIProperty.sdkParam.extraInfo.makeupLutStrength;
        NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
        extraInfo[@"mergeWithCurrentMotion"] = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
        if([category isEqualToString:EFFECT_MAKEUP]){
            extraInfo[@"makeupLutStrength"] = makeupLutStrength;
        }
        [strongSelf setBeauty:category effectValue:teUIProperty.sdkParam.effectValue resourcePath:downloadFileLocalPath extraInfo:extraInfo abilityType:teUIProperty.abilityType save:YES];
    }];
    
}


- (void)setSegmentation:(NSString *)path teUIProperty:(TEUIProperty *)teUIProperty{
    _mergeCurMotion = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
    if([teUIProperty.sdkParam.extraInfo.segType isEqualToString:@"custom_background"]){
        _segmentationType = 0;
        _segmentationResPath = path;
        //[self openImagePicker];
        if ([self.delegate respondsToSelector:@selector(teOpenImagePicker)]) {
            [self.delegate teOpenImagePicker];
        }
    }else if ([teUIProperty.sdkParam.extraInfo.segType isEqualToString:@"green_background"] || [teUIProperty.sdkParam.extraInfo.segType isEqualToString:@"green_background_v2"]){
        _segmentationType = 1;
        _segmentationResPath = path;
        //[self greenscreenAlert];
        if ([self.delegate respondsToSelector:@selector(teGreenscreenAlert)]) {
            [self.delegate teGreenscreenAlert];
        }
        
    }else{
        NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
        extraInfo[@"mergeWithCurrentMotion"] = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
        
        [self setBeauty:EFFECT_SEGMENTATION effectValue:0 resourcePath:path extraInfo:extraInfo abilityType: teUIProperty.abilityType save:YES];
    }
}

- (void)configSegmentation{
    NSMutableDictionary* extraInfo = @{@"bgPath":_segmentationPath}.mutableCopy;
    if(_segmentationType == 0){
        [extraInfo setValue:@"custom_background" forKey:@"segType"];
    }else{
        //[extraInfo setValue:@"[0.8, 0.234, 0.9, 0.3125]" forKey:@"tex_protect_rect"];
        //[extraInfo setValue:@"[0.513, 0.5, 1.0, 1.0]" forKey:@"green_params"];
        [extraInfo setValue:@"#0x00ff00" forKey:@"keyColor"];
        [extraInfo setValue:@"green_background" forKey:@"segType"];
    }
    [extraInfo setValue:[NSString stringWithFormat:@"%d",_segmentationBgType] forKey:@"bgType"];
    extraInfo[@"mergeWithCurrentMotion"] = _mergeCurMotion;
    [self setBeauty:EFFECT_SEGMENTATION effectValue:0 resourcePath:_segmentationResPath extraInfo:extraInfo abilityType:SEGMENTATION save:YES];
}

#pragma mark - 设置自定义背景分割或者自定义绿幕的 自定义（图片或视频）资源
- (int)handleMediaAtPath:(NSString *)filePath {
    int errorCode = 0;
    // 判断文件类型（图片或视频）
    NSString *extension = [[filePath pathExtension] lowercaseString];
    NSArray *imageExtensions = @[@"png", @"jpg", @"jpeg"];
    NSArray *videoExtensions = @[@"mp4", @"mov", @"avi"];

    if ([imageExtensions containsObject:extension]) {
        _segmentationPath = filePath;
        _timeOffset = @0;
        _segmentationBgType = 0;
        [self configSegmentation];
    } else if ([videoExtensions containsObject:extension]) {
        // 处理视频
        NSURL *sourceURL = [NSURL fileURLWithPath:filePath];
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyy-MM-dd-HH.mm.ss"];
        NSURL *newVideoUrl = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents/output-%@.mp4", [formater stringFromDate:[NSDate date]]]];
        [self convertVideoQuailtyWithInputURL:sourceURL outputURL:newVideoUrl completeHandler:nil];
    } else {
        errorCode = 5004; // 不支持的格式
    }
    return errorCode;
}

- (void)setBeauty:(NSString * _Nullable)effectName
      effectValue:(int)effectValue
     resourcePath:(NSString * _Nullable)resourcePath
        extraInfo:(NSDictionary * _Nullable)extraInfo
      abilityType:(NSString *)abilityType
             save:(BOOL)save{
    float multiple = 1;
    if(self.enhancedMode && ([self isBeauty:effectName])){
        id value = [self.tePanelDataProvider.enhancedMultipleDictionary valueForKey:effectName];
        if(value != nil){
            multiple = [value floatValue];
        }else{
            multiple = 1.2;
        }
    }
    [self.teBeautyKit.xmagicApi setEffect:effectName effectValue:effectValue * multiple resourcePath:resourcePath extraInfo:extraInfo];
//    if([self.delegate respondsToSelector:@selector(setEffect)]){
//        [self.delegate setEffect];
//    }
    if(!save){
        return;
    }
    TESDKParam *param = [[TESDKParam alloc] init];
    param.effectName = effectName;
    param.effectValue = effectValue;
    param.resourcePath = [self convertPathToCustomPrefix:resourcePath];
    param.extraInfoDic = extraInfo;
    param.abilityType = abilityType;
    [_teBeautyKit saveEffectParam:param];
}


- (void)setDefaultBeauty{
    if ([self.abilityType isEqualToString:TEUI_BEAUTY_TEMPLATE]){
        for (TEUIProperty *property in self.currentUIProperty.propertyList) {
            if(property.uiState == 2){
                for (Param *param in property.paramList) {
                    [self setBeauty:param.effectName effectValue:[param.effectValue intValue] resourcePath:param.resourcePath extraInfo:nil abilityType:nil save:YES];
                }
            }
        }
        return;
    }
    if(_defaultBeautyList.count > 0){
        [self setBeautyWithTEUIPropertyList:_defaultBeautyList];
    }else{
        NSMutableArray<TEUIProperty *> *property = [NSMutableArray array];
        if(self.currentUIProperty == nil){
            return;
        }
        [property addObject:self.currentUIProperty];
        [self setBeautyWithTEUIPropertyList:property];
    }
}

- (void)setBeautyWithTEUIPropertyList:(NSMutableArray<TEUIProperty *>*)teUIPropertyList{
    for (TEUIProperty *teUIProperty in teUIPropertyList) {
        if(teUIProperty.propertyList.count == 0 && teUIProperty.uiState != TEUIState_INIT){
            [self setBeauty:teUIProperty.sdkParam.effectName effectValue:teUIProperty.sdkParam.effectValue resourcePath:teUIProperty.sdkParam.resourcePath extraInfo:nil abilityType:teUIProperty.abilityType save:YES];
        }else{
            [self setBeautyWithTEUIPropertyList:teUIProperty.propertyList];
        }
    }
}



- (void)setEnhancedMode:(BOOL)enhancedMode{
    _enhancedMode = enhancedMode;
    for (TESDKParam *param in _teBeautyKit.usedSDKParam) {
        if([self isBeauty:param.effectName]){
            [self setBeauty:param.effectName effectValue:param.effectValue resourcePath:param.resourcePath extraInfo:param.extraInfoDic abilityType:param.abilityType save:NO];
        }
    }
}

- (void)imagePickerFinish:(UIImage *)image picker:(UIImagePickerController *)picker{
    image = [TEUtils fixOrientation:image];
    NSData *data = UIImagePNGRepresentation(image);
    //返回为png图像。
    if (!data) {
        //返回为JPEG图像。
        data = UIImageJPEGRepresentation(image, 1.0);
    }
    NSString *imagePath = [self createImagePath:@"image.png"];
    [[NSFileManager defaultManager] createFileAtPath:imagePath contents:data attributes:nil];
    [picker dismissViewControllerAnimated:YES completion:nil];
    _segmentationPath = imagePath;
    _timeOffset = [NSNumber numberWithInt:0];
    _segmentationBgType = 0;
    [self configSegmentation];
}

- (void)moviePickerFinish:(NSURL *)sourceURL picker:(UIImagePickerController *)picker completionHandler:(void (^)(BOOL success, NSError * _Nullable error, NSInteger timeOffset))completionHandler{
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyyy-MM-dd-HH.mm.ss"];
    NSURL *newVideoUrl = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents/output-%@.mp4", [formater stringFromDate:[NSDate date]]]];
    [picker dismissViewControllerAnimated:YES completion:nil];
    // 处理视频 压缩视频
    [self convertVideoQuailtyWithInputURL:sourceURL outputURL:newVideoUrl completeHandler:completionHandler];
}

#pragma mark - 视频压缩转码处理
- (void)convertVideoQuailtyWithInputURL:(NSURL*)inputURL
                              outputURL:(NSURL*)outputURL
                        completeHandler:(void (^)(BOOL success, NSError * _Nullable error, NSInteger timeOffset))handler {
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    CMTime videoTime = [avAsset duration];
    int timeOffset = ceil(1000 * videoTime.value / videoTime.timescale) - 10;
    if (timeOffset > MAX_SEG_VIDEO_DURATION) {
        NSLog(@"background video too long(limit %i)", MAX_SEG_VIDEO_DURATION);
        if(handler){
            NSError *error = [NSError errorWithDomain:@"VideoConvertErrorDomain"
                                                 code:5003
                                             userInfo:@{NSLocalizedDescriptionKey: @"Video duration exceeds limit"}];
            handler(NO,error,0);
        }
        return ;
    }
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse= YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        switch (exportSession.status) {
            case AVAssetExportSessionStatusCompleted:{
                NSLog(@"AVAssetExportSessionStatusCompleted");
                self->_segmentationPath = outputURL.path;
                self->_timeOffset = [NSNumber numberWithInt:timeOffset];
                self->_segmentationBgType = 1;
                [self configSegmentation];
                
                if(handler){
                    handler(YES,nil,timeOffset);
                }
                break;
            }
            case AVAssetExportSessionStatusFailed:{
                NSLog(@"AVAssetExportSessionStatusFailed");
                NSError *error = [NSError errorWithDomain:@"VideoConvertErrorDomain"
                                                     code:5004
                                                 userInfo:exportSession.error.userInfo];
                if(handler){
                    handler(NO,error,0);
                }
                break;
            }
            default: {
                // 其他状态（取消、未知、等待、导出中）
                NSLog(@"export session status: %ld", (long)exportSession.status);
                if (handler) {
                    NSError *error = [NSError errorWithDomain:@"VideoConvertErrorDomain"
                                                         code:5002
                                                     userInfo:@{NSLocalizedDescriptionKey: @"Video export failed"}];
                    handler(NO, error, 0);
                }
                break;
            }
        }
    }];
}


-(NSString *)fileExits:(NSString *)resUri dirPath:(NSString *)dirPath{
    NSURL *downloadURL = [NSURL URLWithString:resUri];
    NSString *filename = downloadURL.lastPathComponent;
    if([filename.pathExtension.lowercaseString isEqualToString:@"zip"]){
        filename = [filename stringByDeletingPathExtension];
    }
    NSString *path =  [[[TEDownloader shardManager].basicPath stringByAppendingPathComponent:dirPath] stringByAppendingPathComponent:filename];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
        return path;
    }
    return nil;
}

//单点美妆NSDictionary
-(NSMutableArray<NSString *> *)beautyMakeupEffectNames{
    if (!_beautyMakeupEffectNames) {
        _beautyMakeupEffectNames = @[
            BEAUTY_MOUTH_LIPSTICK,
            BEAUTY_FACE_RED_CHEEK,
            BEAUTY_FACE_SOFTLIGHT,
            BEAUTY_FACE_EYE_SHADOW,
            BEAUTY_FACE_EYE_LINER,
            BEAUTY_FACE_EYELASH,
            BEAUTY_FACE_EYE_SEQUINS,
            BEAUTY_FACE_EYEBROW,
            BEAUTY_FACE_EYEBALL,
            BEAUTY_FACE_EYELIDS,
            BEAUTY_FACE_EYEWOCAN,
        ];
    }
    return _beautyMakeupEffectNames;
}

- (void)clearLightMakeup{
    [self setBeauty:EFFECT_LIGHT_MAKEUP effectValue:0 resourcePath:nil extraInfo:nil abilityType:nil save:YES];
}

- (void)setBeautyUIState:(NSArray<TEUIProperty *>*) propertyList uiState:(int)uiState {
    for (TEUIProperty *property in propertyList) {
        if(property.propertyList.count == 0){
            property.sdkParam.effectValue = uiState;
            property.uiState = uiState;
        } else {
            property.uiState = uiState;
            [self setBeautyUIState:property.propertyList uiState:uiState];
        }
    }
}

- (void)setBeautySingleUIState:(TEUIProperty *) model uiState:(int)uiState {
    model.uiState = uiState;
    model.sdkParam.effectValue = uiState;
}



- (BOOL)isBeauty:(NSString *)effectName{
    if([effectName hasPrefix:@"beauty."] ||
        [effectName hasPrefix:@"basicV7."] ||
        [effectName hasPrefix:@"smooth."] ||
       [effectName hasPrefix:@"liquefaction."]){
        return YES;
    }
    return NO;
}
    
-(NSString *)createImagePath:(NSString *)fileName{
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [path objectAtIndex:0];
    NSString *imageDocPath = [documentPath stringByAppendingPathComponent:@"TencentEffect_MediaFile"];
    [[NSFileManager defaultManager] createDirectoryAtPath:imageDocPath withIntermediateDirectories:YES attributes:nil error:nil];
    return [imageDocPath stringByAppendingPathComponent:fileName];
}
    
- (void)resetBeauty {
        [self setBeauty:EFFECT_LIGHT_MAKEUP effectValue:0 resourcePath:nil extraInfo:nil abilityType:nil save:YES];
        [self setBeauty:EFFECT_MOTION effectValue:0 resourcePath:nil extraInfo:nil abilityType:nil save:YES];
        [self setBeauty:EFFECT_SEGMENTATION effectValue:0 resourcePath:nil extraInfo:nil abilityType:nil save:YES];
        [self setBeauty:EFFECT_LUT effectValue:0 resourcePath:nil extraInfo:nil abilityType:nil save:YES];
        [self setBeauty:EFFECT_MAKEUP effectValue:0 resourcePath:nil extraInfo:nil abilityType:nil save:YES];
}

-(void)clearBeauty:(NSMutableArray<TESDKParam *> *)sdkParams{
    for (TESDKParam *param in sdkParams) {
        [self setBeauty:param.effectName effectValue:0 resourcePath:param.resourcePath extraInfo:nil abilityType:param.abilityType save:NO];
    }
    [_teBeautyKit clearEffectParam];
}

- (NSString *)convertPathToCustomPrefix:(NSString *)path {
    if ([path hasPrefix:NSHomeDirectory()]) {
        return [path stringByReplacingOccurrencesOfString:NSHomeDirectory() withString:kSandboxPrefix];
    } else if ([path hasPrefix:[[NSBundle mainBundle] bundlePath]]) {
        return [path stringByReplacingOccurrencesOfString:[[NSBundle mainBundle] bundlePath] withString:kBundlePrefix];
    }
    return path;
}


@end
