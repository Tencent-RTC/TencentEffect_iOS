//
//  TEPanelDataProvider.h
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/8.
//

#import <Foundation/Foundation.h>
#import "../Model/TEUIProperty.h"

//demo_ability_menu的abilityType字段
#define BEAUTY_TEMPLATE          @"BEAUTY_TEMPLATE"
#define BEAUTY                   @"BEAUTY"
#define BEAUTY_BASIC             @"BEAUTY_BASIC"
#define BEAUTY_SHAPE             @"BEAUTY_SHAPE"
#define BEAUTY_GENERAL           @"BEAUTY_GENERAL"
#define BEAUTY_IMAGE             @"BEAUTY_IMAGE"
#define LUT                      @"LUT"
#define BEAUTY_MAKEUP            @"BEAUTY_MAKEUP"
#define LIGHT_MAKEUP             @"LIGHT_MAKEUP"
#define MAKEUP                   @"MAKEUP"
#define LIGHT_MOTION             @"LIGHT_MOTION"
#define MOTION_2D                @"MOTION_2D"
#define MOTION_3D                @"MOTION_3D"
#define MOTION_GESTURE           @"MOTION_GESTURE"
#define SEGMENTATION             @"SEGMENTATION"
#define MOTION_CAMERA_MOVE       @"MOTION_CAMERA_MOVE"
#define BEAUTY_BODY              @"BEAUTY_BODY"
#define AVATAR                   @"AVATAR"
#define GESTURE_DETECTION        @"GESTURE_DETECTION"
#define PORTRAIT_SEGMENTATION    @"PORTRAIT_SEGMENTATION"
#define FACE_DETECTION           @"FACE_DETECTION"

@interface TEPanelDataProvider : NSObject

//单点能力-用来设置美颜组合的顺序
@property (nonatomic ,strong) NSMutableArray<NSString *> *abilitiesBeautyArray;
@property (nonatomic ,strong) NSMutableArray<NSString *> *abilitiesMakeupArray;
@property (nonatomic ,strong) NSMutableArray<NSString *> *abilitiesMotionArray;
//美颜、美妆模板
@property (nonatomic ,strong) NSMutableArray<NSString *> *abilitiesTemplateArray;
@property (nonatomic ,strong) NSMutableArray<NSString *> *abilitiesTemplateBeautyArray;
//A/S系列套餐：
@property (nonatomic ,strong) NSArray<NSString *> *motionOfCombos;
@property (nonatomic ,strong) NSArray<NSString *> *makeupOfCombos;
//原子能力
@property (nonatomic ,strong) NSMutableArray<NSString *> *capabilitiesArray;
//美颜互斥组合
@property (nonatomic ,strong) NSArray<NSString *> *exclusionGroup ;
@property (nonatomic ,strong) NSArray<NSString *> *exclusionNoneGroup ;
//增强模式倍率
@property (nonatomic ,strong) NSMutableDictionary *enhancedMultipleDictionary ;

+ (instancetype)shareInstance;

//获取TEUIConfig配置的美颜数据
-(TEUIProperty *)getBeautyPanelData;
//获取TEUIConfig配置的美体数据
-(TEUIProperty *)getBeautyBodyPanelData;
//获取TEUIConfig配置的滤镜数据
-(TEUIProperty *)getLutPanelData;
//获取TEUIConfig配置的动效数据
-(TEUIProperty *)getMotionPanelData;
//获取TEUIConfig配置的美妆数据
-(TEUIProperty *)getMakeupPanelData;
//获取TEUIConfig配置的背景分割数据
-(TEUIProperty *)getSegmentationPanelData;

-(NSMutableArray<TEUIProperty *>*)getAllPanelData;


//基础美颜
-(TEUIProperty *)getBeautyBaseShapeData;
//美体
-(TEUIProperty *)getBeautyBodyData;
//通用美颜
-(TEUIProperty *)getBeautyGeneralShapeData;
//画质调整
-(TEUIProperty *)getBeautyImageData;
//单点美妆
-(TEUIProperty *)getBeautyMakeupData;
//高级美型
-(TEUIProperty *)getBeautyShapeData;
//美颜模板
-(TEUIProperty *)getBeautyTemplateData;
//美颜
-(TEUIProperty *)getBeautyData;
//原子能力
-(NSMutableArray<TEUIProperty *> *)getCapabilitiesListData;
//滤镜
-(TEUIProperty *)getLutData;
//美妆
-(TEUIProperty *)getMakeupData;
//轻美妆
-(TEUIProperty *)getLightMakeupData;
//轻贴纸
-(TEUIProperty *)getLightMotionData;
//2D动效
-(TEUIProperty *)getMotion2dData;
//3D动效
-(TEUIProperty *)getMotion3dData;
//手势动效
-(TEUIProperty *)getMotionGestureData;
//运镜动效
-(TEUIProperty *)getMotionCameraMoveData;
//背景分割
-(TEUIProperty *)getPortraitSegmentationData;
//背景分割
-(TEUIProperty *)getSegmentationData;
//根据套餐获取美颜组合
- (NSMutableArray<TEUIProperty *> *)getAbilitiesBeautyData:(NSString *)comboType;

- (NSMutableArray<TEUIProperty *> *)getAbilitiesMakeupData:(NSString *)comboType;

- (NSMutableArray<TEUIProperty *> *)getAbilitiesMotionData:(NSString *)comboType;

- (NSMutableArray<TEUIProperty *> *)getAbilitiesTemplateData:(NSString *)comboType;

- (NSMutableArray<TEUIProperty *> *)getAbilitiesTemplateBeautyData;
//设置美颜增强属性
- (void)setEnhancedMultiple:(NSMutableDictionary *)enhancedMultiple;
//清空数据
- (void)clearData;
//清空动效和滤镜
- (void)clearMotionLutData;

@end

