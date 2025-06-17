//
//  TEPanelDataProvider.m
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/8.
//

#import "TEPanelDataProvider.h"
#import "../Model/TEUIProperty.h"
#import <XMagic/XmagicConstant.h>
#import "../TEUIConfig.h"

@interface TEPanelDataProvider()

@property(nonatomic, strong)NSMutableArray *savedEffectName;

//美颜数据
@property (nonatomic ,strong) TEUIProperty *beautyPanelData;
//美体数据
@property (nonatomic ,strong) TEUIProperty *beautyBodyPanelData;
//滤镜数据
@property (nonatomic ,strong) TEUIProperty *lutPanelData;
//动效数据
@property (nonatomic ,strong) TEUIProperty *motionPanelData;
//美妆数据
@property (nonatomic ,strong) TEUIProperty *makeupPanelData;
//背景分割数据
@property (nonatomic ,strong) TEUIProperty *segmentationPanelData;
//轻美妆
@property (nonatomic ,strong) TEUIProperty *lightMakeupPanelData;



//基础美颜
@property (nonatomic ,strong) TEUIProperty *beautyBaseShapeData;
//美体
@property (nonatomic ,strong) TEUIProperty *beautyBodyData;
//通用美颜
@property (nonatomic ,strong) TEUIProperty *beautyGeneralShapeData;
//画质调整
@property (nonatomic ,strong) TEUIProperty *beautyImageData;
//单点美妆
@property (nonatomic ,strong) TEUIProperty *beautyMakeupData;
//高级美颜
@property (nonatomic ,strong) TEUIProperty *beautyShapeData;
//美颜模板
@property (nonatomic ,strong) TEUIProperty *beautyTemplateData;
//美颜
@property (nonatomic ,strong) TEUIProperty *beautyData;
//原子能力
@property (nonatomic ,strong) NSMutableArray<TEUIProperty *> *capabilitiesListData;
//滤镜
@property (nonatomic ,strong) TEUIProperty *lutData;
//美妆
@property (nonatomic ,strong) TEUIProperty *makeupData;
//轻美妆
@property (nonatomic ,strong) TEUIProperty *lightMakeupData;
//轻贴纸
@property (nonatomic ,strong) TEUIProperty *lightMotionData;
//2D动效
@property (nonatomic ,strong) TEUIProperty *motion2dData;
//3D动效
@property (nonatomic ,strong) TEUIProperty *motion3dData;
//手势动效
@property (nonatomic ,strong) TEUIProperty *motionGestureData;
//运镜动效
@property (nonatomic ,strong) TEUIProperty *motionCameraMoveData;
//虚拟背景
@property (nonatomic ,strong) TEUIProperty *portraitSegmentationData;
//分割
@property (nonatomic ,strong) TEUIProperty *segmentationData;
//美颜集合
@property (nonatomic ,strong) NSMutableArray<TEUIProperty *> *abilitiesBeautyData;
//美颜模板-美颜
@property (nonatomic ,strong) TEUIProperty *templateBeautyData;
//美颜模板-画质调整
@property (nonatomic ,strong) TEUIProperty *templateBeautyImageData;
//美颜模板-高级美颜
@property (nonatomic ,strong) TEUIProperty *templateBeautyShapeData;
//美颜模板-单点美妆
@property (nonatomic ,strong) TEUIProperty *templateBeautyMakeupData;



@end

@implementation TEPanelDataProvider

+ (instancetype)shareInstance
{
    static TEPanelDataProvider *tePanelDataProvider;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (tePanelDataProvider == nil) {
            tePanelDataProvider = [[TEPanelDataProvider alloc] init];
        }
    });
    return tePanelDataProvider;
}

- (TEUIProperty *)getBeautyPanelData{
    if(!_beautyPanelData){
        NSDictionary *dic = [self readLocalFileWithPath:[[TEUIConfig shareInstance] getBeautyPath]];
        if (dic == nil) {
            return nil;
        }
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_BEAUTY;
        _beautyPanelData = uiproperty;
    }
    return _beautyPanelData;
}

- (TEUIProperty *)getBeautyBodyPanelData{
    if(!_beautyBodyPanelData){
        NSDictionary *dic = [self readLocalFileWithPath:[[TEUIConfig shareInstance] getBeautyBodyPath]];
        if (dic == nil) {
            return nil;
        }
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_BEAUTY;
        _beautyBodyPanelData = uiproperty;
    }
    return _beautyBodyPanelData;
}

- (TEUIProperty *)getLutPanelData{
    if(!_lutPanelData){
        NSDictionary *dic = [self readLocalFileWithPath:[[TEUIConfig shareInstance] getLutPath]];
        if (dic == nil) {
            return nil;
        }
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_LUT;
        _lutPanelData = uiproperty;
    }
    return _lutPanelData;
}

- (TEUIProperty *)getMotionPanelData{
    if(!_motionPanelData){
        NSDictionary *dic = [self readLocalFileWithPath:[[TEUIConfig shareInstance] getMotionPath]];
        if (dic == nil) {
            return nil;
        }
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_MOTION;
        for (TEUIProperty *property in uiproperty.propertyList) {
            property.teCategory = TECategory_MOTION;
        }
        _motionPanelData = uiproperty;
    }
    return _motionPanelData;
}

- (TEUIProperty *)getMakeupPanelData{
    if(!_makeupPanelData){
        NSDictionary *dic = [self readLocalFileWithPath:[[TEUIConfig shareInstance] getMakeupPath]];
        if (dic == nil) {
            return nil;
        }
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_MAKEUP;
        _makeupPanelData = uiproperty;
    }
    return _makeupPanelData;
}

- (TEUIProperty *)getLightMakeupPanelData{
    if(!_lightMakeupPanelData){
        NSDictionary *dic = [self readLocalFileWithPath:[[TEUIConfig shareInstance] getLightMakeupPath]];
        if (dic == nil) {
            return nil;
        }
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_LIGHTMAKEUP;
        _lightMakeupPanelData = uiproperty;
    }
    return _lightMakeupPanelData;
}

- (TEUIProperty *)getSegmentationPanelData{
    if(!_segmentationPanelData){
        NSDictionary *dic = [self readLocalFileWithPath:[[TEUIConfig shareInstance] getSegmentationPath]];
        if (dic == nil) {
            return nil;
        }
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_SEGMENTATION;
        _segmentationPanelData = uiproperty;
    }
    return _segmentationPanelData;
}

- (NSMutableArray<TEUIProperty *> *)getAllPanelData{
    NSMutableArray<TEUIProperty *>*allPanelData = [NSMutableArray array];
    if([self getBeautyPanelData] != nil){
        [allPanelData addObject:_beautyPanelData];
    }
    if([self getBeautyBodyPanelData] != nil){
        [allPanelData addObject:_beautyBodyPanelData];
    }
    if([self getLutPanelData] != nil){
        [allPanelData addObject:_lutPanelData];
    }
    if([self getMotionPanelData] != nil){
        [allPanelData addObject:_motionPanelData];
    }
    if([self getMakeupPanelData] != nil){
        [allPanelData addObject:_makeupPanelData];
    }
    if([self getLightMakeupPanelData] != nil){
        [allPanelData addObject:_lightMakeupPanelData];
    }
    if([self getSegmentationPanelData] != nil){
        [allPanelData addObject:_segmentationPanelData];
    }
    return allPanelData;
}








- (TEUIProperty *)getBeautyBaseShapeData{
    if (!_beautyBaseShapeData) {
        NSDictionary *dic = [self readLocalFileWithName:@"beauty_base_shape"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_BEAUTY;
        _beautyBaseShapeData = uiproperty;
    }
    return _beautyBaseShapeData;
}

- (TEUIProperty *)getBeautyBodyData{
    if (!_beautyBodyData) {
        NSDictionary *dic = [self readLocalFileWithName:@"beauty_body"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_BEAUTY;
        _beautyBodyData = uiproperty;
    }
    return _beautyBodyData;
}

- (TEUIProperty *)getBeautyGeneralShapeData{
    if (!_beautyGeneralShapeData) {
        NSDictionary *dic = [self readLocalFileWithName:@"beauty_general_shape"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_BEAUTY;
        _beautyGeneralShapeData = uiproperty;
    }
    return _beautyGeneralShapeData;
}

- (TEUIProperty *)getBeautyImageData{
    if (!_beautyImageData) {
        NSDictionary *dic = [self readLocalFileWithName:@"beauty_image"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_BEAUTY;
        _beautyImageData = uiproperty;
    }
    return _beautyImageData;
}

- (TEUIProperty *)getBeautyMakeupData{
    if (!_beautyMakeupData) {
        NSDictionary *dic = [self readLocalFileWithName:@"beauty_makeup"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_BEAUTY;
        _beautyMakeupData = uiproperty;
    }
    return _beautyMakeupData;
}

- (TEUIProperty *)getBeautyShapeData{
    if (!_beautyShapeData) {
        NSDictionary *dic = [self readLocalFileWithName:@"beauty_shape"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_BEAUTY;
        _beautyShapeData = uiproperty;
    }
    return _beautyShapeData;
}

- (TEUIProperty *)getBeautyTemplateData{
    if (!_beautyTemplateData) {
        NSDictionary *dic = [self readLocalFileWithName:@"beauty_template"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_TEMPLATE;
        _beautyTemplateData = uiproperty;
    }
    return _beautyTemplateData;
}

- (TEUIProperty *)getBeautyData{
    if (!_beautyData) {
        NSDictionary *dic = [self readLocalFileWithName:@"beauty"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_BEAUTY;
        _beautyData = uiproperty;
    }
    return _beautyData;
}

- (TEUIProperty * )getLutData{
    if (!_lutData) {
        NSDictionary *dic = [self readLocalFileWithName:@"lut"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_LUT;
        _lutData = uiproperty;
    }
    return _lutData;
}

- (TEUIProperty *)getMakeupData{
    if (!_makeupData) {
        NSDictionary *dic = [self readLocalFileWithName:@"makeup"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_MAKEUP;
        uiproperty.abilityType = @"MAKEUP";
        _makeupData = uiproperty;
    }
    return _makeupData;
}

- (TEUIProperty *)getLightMakeupData{
    if (!_lightMakeupData) {
        NSDictionary *dic = [self readLocalFileWithName:@"light_makeup"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_LIGHTMAKEUP;
        uiproperty.abilityType = @"LIGHT_MAKEUP";
        _lightMakeupData = uiproperty;
    }
    return _lightMakeupData;
}

- (TEUIProperty *)getLightMotionData{
    if (!_lightMotionData) {
        NSDictionary *dic = [self readLocalFileWithName:@"light_motion"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_MOTION;
        uiproperty.abilityType = @"LIGHT_MOTION";
        _lightMotionData = uiproperty;
    }
    return _lightMotionData;
}

- (TEUIProperty *)getMotion2dData{
    if (!_motion2dData) {
        NSDictionary *dic = [self readLocalFileWithName:@"motion_2d"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_MOTION;
        uiproperty.abilityType = @"MOTION_2D";
        _motion2dData = uiproperty;
    }
    return _motion2dData;
}

- (TEUIProperty *)getMotion3dData{
    if (!_motion3dData) {
        NSDictionary *dic = [self readLocalFileWithName:@"motion_3d"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_MOTION;
        uiproperty.abilityType = @"MOTION_3D";
        _motion3dData = uiproperty;
    }
    return _motion3dData;
}

- (TEUIProperty *)getMotionGestureData{
    if (!_motionGestureData) {
        NSDictionary *dic = [self readLocalFileWithName:@"motion_gesture"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_MOTION;
        uiproperty.abilityType = @"MOTION_GESTURE";
        _motionGestureData = uiproperty;
    }
    return _motionGestureData;
}

- (TEUIProperty *)getMotionCameraMoveData{
    if (!_motionCameraMoveData) {
        NSDictionary *dic = [self readLocalFileWithName:@"motion_camera_move"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_MOTION;
        uiproperty.abilityType = @"MOTION_CAMERA_MOVE";
        _motionCameraMoveData = uiproperty;
    }
    return _motionCameraMoveData;
}

- (TEUIProperty *)getPortraitSegmentationData{
    if (!_portraitSegmentationData) {
        NSDictionary *dic = [self readLocalFileWithName:@"portrait_segmentation"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_SEGMENTATION;
        uiproperty.abilityType = @"SEGMENTATION";
        _portraitSegmentationData = uiproperty;
    }
    return _portraitSegmentationData;
}

- (TEUIProperty *)getSegmentationData{
    if (!_segmentationData) {
        NSDictionary *dic = [self readLocalFileWithName:@"segmentation"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_SEGMENTATION;
        uiproperty.abilityType = @"SEGMENTATION";
        _segmentationData = uiproperty;
    }
    return _segmentationData;
}

- (TEUIProperty *)getTemplateBeautyData{
    if (!_templateBeautyData) {
        NSDictionary *dic = [self readLocalFileWithName:@"beauty"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_BEAUTY;
        _templateBeautyData = uiproperty;
    }
    return _templateBeautyData;
}

- (TEUIProperty *)getTemplateBeautyImageData{
    if (!_templateBeautyImageData) {
        NSDictionary *dic = [self readLocalFileWithName:@"beauty_image"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_BEAUTY;
        _templateBeautyImageData = uiproperty;
    }
    return _templateBeautyImageData;
}

- (TEUIProperty *)getTemplateBeautyShapeData{
    if (!_templateBeautyShapeData) {
        NSDictionary *dic = [self readLocalFileWithName:@"beauty_shape"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_BEAUTY;
        _templateBeautyShapeData = uiproperty;
    }
    return _templateBeautyShapeData;
}

- (TEUIProperty *)getTemplateBeautyMakeupData{
    if (!_templateBeautyMakeupData) {
        NSDictionary *dic = [self readLocalFileWithName:@"beauty_makeup"];
        TEUIProperty *uiproperty = [TEUIProperty new];
        [uiproperty setValuesForKeysWithDictionary:dic];
        uiproperty.teCategory = TECategory_BEAUTY;
        _templateBeautyMakeupData = uiproperty;
    }
    return _templateBeautyMakeupData;
}


- (NSMutableArray<TEUIProperty *> *)getCapabilitiesListData{
    if(!self.capabilitiesArray){
        self.capabilitiesArray = [NSMutableArray array];
        [self.capabilitiesArray addObject:@"FACE_DETECTION"];
        [self.capabilitiesArray addObject:@"GESTURE_DETECTION"];
    }
    if (!_capabilitiesListData) {
        NSMutableArray<TEUIProperty *> *teuiPropertylist = [NSMutableArray array];
        NSDictionary *arrays = [self readLocalFileWithName:@"capabilities_list"];
        for (NSDictionary *dic in arrays) {
            TEUIProperty *teuiProperty = [TEUIProperty new];
            [teuiProperty setValuesForKeysWithDictionary:dic];
            [teuiPropertylist addObject:teuiProperty];
        }
        _capabilitiesListData = teuiPropertylist;
    }
    return _capabilitiesListData;
}


- (NSMutableArray<TEUIProperty *> *)getAbilitiesBeautyData:(NSString *)comboType{
    [self getBeautyData];
    [self getBeautyImageData];
    [self getBeautyShapeData];
    [self getBeautyBodyData];
    [self getBeautyBaseShapeData];
    [self getBeautyGeneralShapeData];
    NSMutableArray<TEUIProperty *> *array = [NSMutableArray array];
    self.abilitiesBeautyArray = [NSMutableArray array];
    if([comboType isEqualToString:@"A1-00"]){
        [array addObject:self.beautyData];
        [self.abilitiesBeautyArray addObject:BEAUTY];
    }else if ([comboType isEqualToString:@"A1-01"] ||
              [comboType isEqualToString:@"A1-02"] ||
              [comboType isEqualToString:@"A1-05"] ||
              [comboType isEqualToString:@"A1-06"]){
        [array addObjectsFromArray:@[self.beautyData,self.beautyImageData,self.beautyBaseShapeData]];
        [self.abilitiesBeautyArray addObjectsFromArray:@[BEAUTY,BEAUTY_IMAGE,BEAUTY_BASIC]];
    }else if ([comboType isEqualToString:@"A1-03"] ||
              [comboType isEqualToString:@"A1-04"]){
        [array addObjectsFromArray:@[self.beautyData,self.beautyImageData,self.beautyGeneralShapeData]];
        [self.abilitiesBeautyArray addObjectsFromArray:@[BEAUTY,BEAUTY_IMAGE,BEAUTY_GENERAL]];
    }else if ([comboType isEqualToString:@"S1-00"] ||
              [comboType isEqualToString:@"S1-01"] ||
              [comboType isEqualToString:@"S1-02"] ||
              [comboType isEqualToString:@"S1-03"] ||
              [comboType isEqualToString:@"S1-04"]){
        [array addObjectsFromArray:@[self.beautyData,self.beautyImageData,self.beautyShapeData]];
        [self.abilitiesBeautyArray addObjectsFromArray:@[BEAUTY,BEAUTY_IMAGE,BEAUTY_SHAPE]];
    }else{
        [array addObjectsFromArray:@[self.beautyData,self.beautyImageData,self.beautyShapeData,self.beautyBodyData]];
        [self.abilitiesBeautyArray addObjectsFromArray:@[BEAUTY,BEAUTY_IMAGE,BEAUTY_SHAPE,BEAUTY_BODY]];
    }
    return array;
}

- (NSMutableArray<TEUIProperty *> *)getAbilitiesMakeupData:(NSString *)comboType{
    [self getBeautyMakeupData];
    [self getLightMakeupData];
    NSMutableArray<TEUIProperty *> *array = [NSMutableArray array];
    self.abilitiesMakeupArray = [NSMutableArray array];
    if([comboType isEqualToString:@"A1-06"]){
        [array addObject:self.lightMakeupData];
        [self.abilitiesMakeupArray addObject:LIGHT_MAKEUP];
    }else if ([comboType isEqualToString:@"S1-00"]){
        [array addObject:self.beautyMakeupData];
        [self.abilitiesMakeupArray addObject:BEAUTY_MAKEUP];
    }else{
        [array addObject:self.beautyMakeupData];
        [array addObject:self.lightMakeupData];
        [self.abilitiesMakeupArray addObject:BEAUTY_MAKEUP];
        [self.abilitiesMakeupArray addObject:LIGHT_MAKEUP];
    }
    return array;
}

- (NSMutableArray<TEUIProperty *> *)getAbilitiesMotionData:(NSString *)comboType{
    [self clearMotionLutData];
    [self getLightMotionData];
    [self getMotion2dData];
    [self getMotion3dData];
    [self getMakeupData];
    [self getMotionGestureData];
    [self getSegmentationData];
    [self getMotionCameraMoveData];
    NSMutableArray<TEUIProperty *> *array = [NSMutableArray array];
    self.abilitiesMotionArray = [NSMutableArray array];
    
    if([comboType isEqualToString:@"A1-02"] ||
       [comboType isEqualToString:@"A1-03"]){
        [array addObjectsFromArray:@[self.lightMotionData,self.motion2dData,self.motionCameraMoveData]];
        [self.abilitiesMotionArray addObjectsFromArray:@[LIGHT_MOTION,MOTION_2D,MOTION_CAMERA_MOVE]];
    }else if([comboType isEqualToString:@"A1-04"]){
        [array addObjectsFromArray:@[self.lightMotionData,self.motion2dData,self.motionGestureData,self.motionCameraMoveData]];
        [self.abilitiesMotionArray addObjectsFromArray:@[LIGHT_MOTION,MOTION_2D,MOTION_GESTURE,MOTION_CAMERA_MOVE]];
    }else if([comboType isEqualToString:@"A1-05"] ||
             [comboType isEqualToString:@"S1-03"]){
        [array addObjectsFromArray:@[self.lightMotionData,self.motion2dData,self.motion3dData,self.segmentationData,self.motionCameraMoveData]];
        [self.abilitiesMotionArray addObjectsFromArray:@[LIGHT_MOTION,MOTION_2D,MOTION_3D,SEGMENTATION,MOTION_CAMERA_MOVE]];
    }else if([comboType isEqualToString:@"A1-06"] ||
             [comboType isEqualToString:@"S1-01"]){
        [array addObjectsFromArray:@[self.lightMotionData,self.motion2dData,self.motion3dData,self.makeupData,self.motionCameraMoveData]];
        [self.abilitiesMotionArray addObjectsFromArray:@[LIGHT_MOTION,MOTION_2D,MOTION_3D,MAKEUP,MOTION_CAMERA_MOVE]];
    }else if ([comboType isEqualToString:@"S1-02"]){
        [array addObjectsFromArray:@[self.lightMotionData,self.motion2dData,self.motion3dData,self.makeupData,self.motionGestureData,self.motionCameraMoveData]];
        [self.abilitiesMotionArray addObjectsFromArray:@[LIGHT_MOTION,MOTION_2D,MOTION_3D,MAKEUP,MOTION_GESTURE,MOTION_CAMERA_MOVE]];
    }else{
        [array addObjectsFromArray:@[self.lightMotionData,self.motion2dData,self.motion3dData,self.makeupData,self.motionGestureData,self.segmentationData,self.motionCameraMoveData]];
        [self.abilitiesMotionArray addObjectsFromArray:@[LIGHT_MOTION,MOTION_2D,MOTION_3D,MAKEUP,MOTION_GESTURE,SEGMENTATION,MOTION_CAMERA_MOVE]];
    }
    return array;
}

- (NSMutableArray<TEUIProperty *> *)getAbilitiesTemplateData:(NSString *)comboType{
    [self getBeautyTemplateData];
    [self getMakeupData];
    NSMutableArray<TEUIProperty *> *array = [NSMutableArray array];
    self.abilitiesTemplateArray = [NSMutableArray array];
    
    [array addObject:self.beautyTemplateData];
    [array addObject:self.makeupData];
    [self.abilitiesTemplateArray addObject:BEAUTY_TEMPLATE];
    [self.abilitiesTemplateArray addObject:MAKEUP];
    return array;
}

- (NSMutableArray<TEUIProperty *> *)getAbilitiesTemplateBeautyData{
    [self getTemplateBeautyData];
    [self getTemplateBeautyImageData];
    [self getTemplateBeautyShapeData];
    [self getTemplateBeautyMakeupData];
    NSMutableArray<TEUIProperty *> *array = [NSMutableArray array];
    [array addObjectsFromArray:@[self.templateBeautyData,self.templateBeautyImageData,self.templateBeautyShapeData,self.templateBeautyMakeupData]];
    
    if (!self.abilitiesTemplateBeautyArray) {
        self.abilitiesTemplateBeautyArray = [NSMutableArray array];
    }
    [self.abilitiesTemplateBeautyArray addObjectsFromArray:@[BEAUTY,BEAUTY_IMAGE,BEAUTY_SHAPE,BEAUTY_MAKEUP]];
    return array;
    
}

- (void)clearData{
    self.beautyTemplateData = nil;
    self.templateBeautyData = nil;
    self.templateBeautyImageData = nil;
    self.templateBeautyShapeData = nil;
    self.templateBeautyMakeupData = nil;
    self.beautyPanelData = nil;
    self.beautyBodyPanelData = nil;
    self.lutPanelData = nil;
    self.motionPanelData = nil;
    self.makeupPanelData = nil;
    self.lightMakeupPanelData = nil;
    self.segmentationPanelData = nil;
    [self clearMotionLutData];
}

- (void)clearMotionLutData{
    self.beautyBaseShapeData = nil;
    self.beautyBodyData = nil;
    self.beautyGeneralShapeData = nil;
    self.beautyImageData = nil;
    self.beautyMakeupData = nil;
    self.beautyShapeData = nil;
    self.beautyData = nil;
    self.makeupData = nil;
    self.lightMakeupData = nil;
    self.segmentationData = nil;
    self.lutData = nil;
    self.lightMotionData = nil;
    self.motion2dData = nil;
    self.motion3dData = nil;
    self.motionGestureData = nil;
    self.motionCameraMoveData = nil;
    self.portraitSegmentationData = nil;
    self.segmentationData = nil;
}

- (NSArray<NSString *> *)motionOfCombos{
    if(!_motionOfCombos){
        _motionOfCombos = @[@"A1-02",@"A1-03",@"A1-05",@"A1-06",
                            @"S1-01",@"S1-02",@"S1-03",@"S1-04",@"S1-07"];
    }
    return _motionOfCombos;
}

- (NSArray<NSString *> *)makeupOfCombos{
    if(!_makeupOfCombos){
        _makeupOfCombos = @[@"A1-06",@"S1-00",@"S1-01",@"S1-02",@"S1-03",@"S1-04",@"S1-07"];
    }
    return _makeupOfCombos;
}

- (NSArray<NSString *> *)exclusionGroup{
    if(!_exclusionGroup){
        _exclusionGroup = @
        [BEAUTY_WHITEN0,BEAUTY_WHITEN,BEAUTY_WHITEN2,BEAUTY_WHITEN3,
         BEAUTY_BLACK1,BEAUTY_BLACK2,
         BEAUTY_SMOOTH,BEAUTY_SMOOTH2,BEAUTY_SMOOTH3,BEAUTY_SMOOTH4,
         BEAUTY_FACE_NATURE,BEAUTY_FACE_GODNESS,BEAUTY_FACE_MALE_GOD,
         BEAUTY_MOUTH_LIPSTICK,BEAUTY_FACE_RED_CHEEK,BEAUTY_FACE_SOFTLIGHT,
         BEAUTY_FACE_EYE_SHADOW,BEAUTY_FACE_EYE_LINER,BEAUTY_FACE_EYELASH,
         BEAUTY_FACE_EYE_SEQUINS,BEAUTY_FACE_EYEBALL,BEAUTY_HAIR_COLOR_LUT
        ];
    }
    return _exclusionGroup;
}

- (NSArray<NSString *> *)exclusionNoneGroup{
    if(!_exclusionNoneGroup){
        _exclusionNoneGroup = @
        [BEAUTY_MOUTH_LIPSTICK,BEAUTY_FACE_RED_CHEEK,BEAUTY_FACE_SOFTLIGHT,
         BEAUTY_FACE_EYE_SHADOW,BEAUTY_FACE_EYE_LINER,BEAUTY_FACE_EYELASH,
         BEAUTY_FACE_EYE_SEQUINS,BEAUTY_FACE_EYEBALL,BEAUTY_HAIR_COLOR_LUT
        ];
    }
    return _exclusionNoneGroup;
}

- (NSMutableDictionary *)enhancedMultipleDictionary{
    if(!_enhancedMultipleDictionary){
        _enhancedMultipleDictionary = [NSMutableDictionary dictionaryWithDictionary:@{
            BEAUTY_FACE_REMOVE_WRINKLE : @(1.3),
            BEAUTY_FACE_REMOVE_LAW_LINE : @(1.3),
            BEAUTY_FACE_SKIN_RETOUCH : @(1.3),
            BEAUTY_MOUTH_LIPSTICK : @(1.3),
            BEAUTY_WHITEN : @(1.3),
            BEAUTY_FACE_SOFTLIGHT : @(1.3),
            BEAUTY_FACE_SHORT : @(1.3),
            BEAUTY_FACE_V : @(1.3),
            BEAUTY_EYE_DISTANCE : @(1.3),
            BEAUTY_NOSE_HEIGHT : @(1.3),
            BEAUTY_EYE_LIGHTEN : @(1.5),
            BEAUTY_FACE_RED_CHEEK : @(1.8)
        }];
    }
    return _enhancedMultipleDictionary;
}

- (void)setEnhancedMultiple:(NSMutableDictionary *)enhancedMultiple{
    [enhancedMultiple enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        _enhancedMultipleDictionary[key] = obj;
    }];
}

- (NSDictionary *)readLocalFileWithName:(NSString *)name {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"json"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
        return nil;
    }
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
}

- (NSDictionary *)readLocalFileWithPath:(NSString *)path {
//    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"json"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
        NSLog(@"path:%@ is not exists",path);
        return nil;
    }
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
}
@end
