//
//  TEUIConfig.m
//  BeautyDemo
//
//  Created by tao yue on 2024/1/21.
//

#import "TEUIConfig.h"

@interface TEUIConfig()

@property(nonatomic, copy)NSString *beautyPath;
@property(nonatomic, copy)NSString *beautyBodyPath;
@property(nonatomic, copy)NSString *lutPath;
@property(nonatomic, copy)NSString *motionPath;
@property(nonatomic, copy)NSString *makeupPath;
@property(nonatomic, copy)NSString *segmentationPath;
@property(nonatomic, copy)NSString *resourcePath;
@property(nonatomic, strong)NSBundle *resourceBundle;

@end

@implementation TEUIConfig

+ (instancetype)shareInstance
{
    static TEUIConfig *teUIConfig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (teUIConfig == nil) {
            teUIConfig = [[TEUIConfig alloc] init];
        }
    });
    return teUIConfig;
}

- (instancetype)init {
    if (self = [super init]) {
        _resourcePath = [[NSBundle mainBundle] pathForResource:@"TEBeautyKitResources"
                                                                 ofType:@"bundle"];
        _resourceBundle = [NSBundle bundleWithPath:self.resourcePath];
    }
    return self;
}



- (NSString *)localizedString:(NSString *)key {
    if (_resourceBundle == nil) {
        return [[NSBundle mainBundle] localizedStringForKey:key value:@"" table:nil];
    }
    NSString *language = [[NSLocale preferredLanguages] firstObject];
    if ([language hasPrefix:@"zh"]) {
        language = @"zh-Hans";
    }else {
        language = @"en";
    }
    NSBundle *languageBundle = [NSBundle bundleWithPath:[_resourceBundle pathForResource:language ofType:@"lproj"]];
    return [languageBundle localizedStringForKey:key value:@"" table:nil];
}

- (UIImage *)imageNamed:(NSString *)name{
    NSString *resourcePath = [[NSBundle mainBundle]
    pathForResource:@"TEBeautyKitResources" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:resourcePath];
    if(bundle == nil){
        bundle = [NSBundle mainBundle];
    }
    UIImage *image = [UIImage imageNamed:name inBundle:bundle
    compatibleWithTraitCollection:nil];
    return image;
}

- (void)setTEPanelViewRes:(NSString *)beauty beautyBody:(NSString *)beautyBody lut:(NSString *)lut motion:(NSString *)motion makeup:(NSString *)makeup segmentation:(NSString *)segmentation{
    _beautyPath = beauty;
    _beautyBodyPath = beautyBody;
    _lutPath = lut;
    _motionPath = motion;
    _makeupPath = makeup;
    _segmentationPath = segmentation;
}

- (NSString *)getBeautyPath{
    return _beautyPath;
}

- (NSString *)getBeautyBodyPath{
    return _beautyBodyPath;
}

- (NSString *)getLutPath{
    return _lutPath;
}

- (NSString *)getMotionPath{
    return _motionPath;
}

- (NSString *)getMakeupPath{
    return _makeupPath;
}

- (NSString *)getSegmentationPath{
    return _segmentationPath;
}

- (UIColor *)panelBackgroundColor{
    if(!_panelBackgroundColor){
        _panelBackgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    }
    return _panelBackgroundColor;
}
- (UIColor *)panelDividerColor{
    if(!_panelDividerColor){
        _panelDividerColor = [UIColor colorWithWhite:1 alpha:0.1];
    }
    return _panelDividerColor;
}

- (UIColor *)panelItemCheckedColor{
    if(!_panelItemCheckedColor){
        _panelItemCheckedColor = [UIColor colorWithRed:0 green:0.424 blue:1 alpha:1];
    }
    return _panelItemCheckedColor;
}

- (UIColor *)textColor{
    if(!_textColor){
        _textColor = [UIColor whiteColor];
    }
    return _textColor;
}

- (UIColor *)textCheckedColor{
    if(!_textCheckedColor){
        _textCheckedColor = [UIColor whiteColor];
    }
    return _textCheckedColor;
}

- (UIColor *)seekBarProgressColor{
    if(!_seekBarProgressColor){
        _seekBarProgressColor = [UIColor colorWithRed:0 green:0x6e/255.0 blue:1 alpha:1];
    }
    return _seekBarProgressColor;
}


@end
