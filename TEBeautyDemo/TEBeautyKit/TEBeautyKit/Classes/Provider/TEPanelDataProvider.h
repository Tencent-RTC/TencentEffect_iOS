//
//  TEPanelDataProvider.h
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/8.
//

#import <Foundation/Foundation.h>
#import "TEUIProperty.h"

//demo_ability_menu abilityType
#define BEAUTY_TEMPLATE          @"BEAUTY_TEMPLATE"
#define BEAUTY                   @"BEAUTY"
#define BEAUTY_BASIC             @"BEAUTY_BASIC"
#define BEAUTY_SHAPE             @"BEAUTY_SHAPE"
#define BEAUTY_GENERAL           @"BEAUTY_GENERAL"
#define BEAUTY_IMAGE             @"BEAUTY_IMAGE"
#define LUT                      @"LUT"
#define BEAUTY_MAKEUP            @"BEAUTY_MAKEUP"
#define MAKEUP                   @"MAKEUP"
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

@property (nonatomic ,strong) NSMutableArray<NSString *> *abilitiesBeautyArray;
@property (nonatomic ,strong) NSMutableArray<NSString *> *abilitiesMakeupArray;
@property (nonatomic ,strong) NSMutableArray<NSString *> *abilitiesMotionArray;

@property (nonatomic ,strong) NSMutableArray<NSString *> *abilitiesTemplateArray;
@property (nonatomic ,strong) NSMutableArray<NSString *> *abilitiesTemplateBeautyArray;

@property (nonatomic ,strong) NSArray<NSString *> *motionOfCombos;
@property (nonatomic ,strong) NSArray<NSString *> *makeupOfCombos;

@property (nonatomic ,strong) NSMutableArray<NSString *> *capabilitiesArray;

@property (nonatomic ,strong) NSArray<NSString *> *exclusionGroup ;

@property (nonatomic ,strong) NSMutableDictionary *enhancedMultipleDictionary ;

+ (instancetype)shareInstance;

// Obtain the beauty data configured by TEUIConfig
-(TEUIProperty *)getBeautyPanelData;
// Obtain the beautyBody data configured by TEUIConfig
-(TEUIProperty *)getBeautyBodyPanelData;
// Obtain the lut data configured by TEUIConfig
-(TEUIProperty *)getLutPanelData;
// Obtain the motion data configured by TEUIConfig
-(TEUIProperty *)getMotionPanelData;
// Obtain the makeup data configured by TEUIConfig
-(TEUIProperty *)getMakeupPanelData;
// Obtain the Segmentation data configured by TEUIConfig
-(TEUIProperty *)getSegmentationPanelData;

-(NSMutableArray<TEUIProperty *>*)getAllPanelData;

-(TEUIProperty *)getBeautyBaseShapeData;
-(TEUIProperty *)getBeautyBodyData;
-(TEUIProperty *)getBeautyGeneralShapeData;
-(TEUIProperty *)getBeautyImageData;
-(TEUIProperty *)getBeautyMakeupData;
-(TEUIProperty *)getBeautyShapeData;
-(TEUIProperty *)getBeautyTemplateData;
-(TEUIProperty *)getBeautyData;
-(NSMutableArray<TEUIProperty *> *)getCapabilitiesListData;
-(TEUIProperty *)getLutData;
-(TEUIProperty *)getMakeupData;
-(TEUIProperty *)getMotion2dData;
-(TEUIProperty *)getMotion3dData;
-(TEUIProperty *)getMotionGestureData;
-(TEUIProperty *)getMotionCameraMoveData;
-(TEUIProperty *)getPortraitSegmentationData;
-(TEUIProperty *)getSegmentationData;
- (NSMutableArray<TEUIProperty *> *)getAbilitiesBeautyData:(NSString *)comboType;

- (NSMutableArray<TEUIProperty *> *)getAbilitiesMakeupData:(NSString *)comboType;

- (NSMutableArray<TEUIProperty *> *)getAbilitiesMotionData:(NSString *)comboType;

- (NSMutableArray<TEUIProperty *> *)getAbilitiesTemplateData:(NSString *)comboType;

- (NSMutableArray<TEUIProperty *> *)getAbilitiesTemplateBeautyData;
- (void)setEnhancedMultiple:(NSMutableDictionary *)enhancedMultiple;
- (void)clearData;
- (void)clearMotionLutData;

@end

