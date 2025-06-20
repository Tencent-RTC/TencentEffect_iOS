//
//  TEUIProperty.h
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/8.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TEUIState) {
    TEUIState_INIT = 0,
    TEUIState_IN_USE = 1,
    TEUIState_CHECKED_AND_IN_USE = 2,
};

typedef NS_ENUM(NSUInteger, TECategory) {
    TECategory_BEAUTY = 1,             //美颜、美体
    TECategory_LUT = 2,  //滤镜
    TECategory_MAKEUP = 3,          //美妆
    TECategory_MOTION = 4,       //动效
    TECategory_SEGMENTATION = 5,         //分割
    TECategory_TEMPLATE = 6,   //美颜模板
    TECategory_LIGHTMAKEUP = 7, //轻美妆
};

@interface Param : NSObject
@property(nonatomic,copy)NSString *effectName;
@property(nonatomic,copy)NSString *effectValue;
@property(nonatomic,copy)NSString *resourcePath;
@end

@interface ExtraInfo : NSObject

@property(nonatomic,copy)NSString *segType;
@property(nonatomic,copy)NSString *makeupLutStrength;
@property(nonatomic,copy)NSString *mergeWithCurrentMotion;
@property(nonatomic,copy)NSString *bgType;
@property(nonatomic,copy)NSString *bgPath;
@property(nonatomic,copy)NSString *keyColor;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end

@interface TESDKParam : NSObject

@property(nonatomic,copy)NSString *effectName;
@property(nonatomic,assign)int effectValue;
@property(nonatomic,copy)NSString *resourcePath;
@property(nonatomic,assign)BOOL numericalType;//是否是数值型
@property(nonatomic,strong)ExtraInfo *extraInfo;
@property(nonatomic,strong)NSDictionary *extraInfoDic;

- (instancetype)initWithDict:(NSDictionary *)dict;

- (NSDictionary *)toDictionary;
@end

@interface TEUIProperty : NSObject

@property(nonatomic,copy)NSString *displayName;
@property(nonatomic,copy)NSString *displayNameEn;
@property(nonatomic,copy)NSString *icon;
@property(nonatomic,copy)NSString *downloadPath;
@property(nonatomic,copy)NSString *resourceUri;
@property(nonatomic,assign)int uiState;
@property(nonatomic,strong)NSMutableArray<TEUIProperty *> *propertyList;
@property(nonatomic,strong)TESDKParam *sdkParam;
@property(nonatomic,assign)TECategory teCategory;
@property(nonatomic,assign)NSString *uiCategory;
@property(nonatomic,strong)NSMutableArray<Param *> *paramList;

@property(nonatomic,assign)BOOL isSelected;
@property(nonatomic,copy)NSString *abilityType;
@property(nonatomic,copy)NSString *label;
@property(nonatomic,copy)NSString *labelEn;
@property(nonatomic,copy)NSString *Id;
@property(nonatomic,copy)NSString *parentId;
@property(nonatomic,assign)BOOL isShowGridLayout;

- (instancetype)initWithDict:(NSDictionary *)dict;
- (NSDictionary *)toDictionary;

@end
