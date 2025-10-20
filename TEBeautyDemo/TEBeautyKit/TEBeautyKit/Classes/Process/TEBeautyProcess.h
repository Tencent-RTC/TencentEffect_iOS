//
//  TEBeautyProcess.h
//  TEBeautyKit
//
//  Created by wwk on 2025/9/9.
//

#import <Foundation/Foundation.h>
#import "TEUIProperty.h"
#import "TEBeautyKit.h"
#import "TEPanelDataProvider.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TEBeautyProcessDelegate <NSObject>
@optional

-(void)beautyCollectionRreloadData;
-(void)teSliderIsHidden;
-(void)teShowLoading;
-(void)TEDownloaderProgressBlock:(CGFloat)progress;
-(void)teDismissLoading;
-(void)teOpenImagePicker;
-(void)teGreenscreenAlert;
@end

@interface TEBeautyProcess : NSObject
@property (nonatomic, weak) id<TEBeautyProcessDelegate> delegate;
@property (nonatomic, strong) TEBeautyKit *teBeautyKit;
@property (nonatomic, strong) NSString *abilityType;
@property (nonatomic, assign) BOOL enhancedMode; //普通模式或者增强模式。默认美颜普通模式
@property (nonatomic, strong) TEUIProperty *currentUIProperty;          // 当前选中UI属性项
@property (nonatomic, strong) NSMutableArray<TEUIProperty *> *currentUIPropertyList; // 当前显示属性列表
@property (nonatomic, strong) TEPanelDataProvider *tePanelDataProvider; // 数据提供器

- (void)resetBeauty;
- (void)setDefaultBeauty;
- (int)handleMediaAtPath:(NSString *)filePath;
- (void)updateBeautyEffect:(TEUIProperty *)teUIProperty;
- (void)clearBeauty:(NSMutableArray<TESDKParam *> *)sdkParams;
- (void)imagePickerFinish:(UIImage *)image picker:(UIImagePickerController *)picker;

- (void)moviePickerFinish:(NSURL *)sourceURL picker:(UIImagePickerController *)picker completionHandler:(void (^)(BOOL success, NSError * _Nullable error, NSInteger timeOffset))completionHandler;

- (void)setBeauty:(NSString * _Nullable)effectName
      effectValue:(int)effectValue
     resourcePath:(NSString * _Nullable)resourcePath
        extraInfo:(NSDictionary * _Nullable)extraInfo
      abilityType:(NSString *)abilityType
             save:(BOOL)save;

@end


NS_ASSUME_NONNULL_END
