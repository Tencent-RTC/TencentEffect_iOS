//
//  TEUIConfig.h
//  BeautyDemo
//
//  Created by tao yue on 2024/1/21.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TEPanelLevel) {
    A1_00,
    A1_01,
    A1_02,
    A1_03,
    A1_04,
    A1_05,
    A1_06,
    S1_00,
    S1_01,
    S1_02,
    S1_03,
    S1_04,
    S1_05,
    S1_06,
    S1_07,
};


@interface TEUIConfig : NSObject

@property(nonatomic,strong)UIColor *panelBackgroundColor;
@property(nonatomic,strong)UIColor *panelDividerColor;
@property(nonatomic,strong)UIColor *panelItemCheckedColor;
@property(nonatomic,strong)UIColor *textColor;
@property(nonatomic,strong)UIColor *textCheckedColor;
@property(nonatomic,strong)UIColor *seekBarProgressColor;

+ (instancetype)shareInstance;
/**
 beauty:beauty json path
 beautyBody：beautyBody json path
 lut：lut json path
 motion：motion json path
 makeup：makeup json path
 segmentation：segmentation json path
 */
-(void)setTEPanelViewRes:(NSString *)beauty beautyBody:(NSString *)beautyBody lut:(NSString *)lut motion:(NSString *)motion makeup:(NSString *)makeup segmentation:(NSString *)segmentation;


/// 根据美颜套餐设置美颜面板的数据
/// - Parameter panelLevel: 美颜套餐
-(void)setPanelLevel:(TEPanelLevel)panelLevel;

-(void)setLightCoreBundlePath:(NSString *)corePath;

-(NSString *)getLightCoreBundlePath;

-(NSString *)getBeautyPath;

-(NSString *)getBeautyBodyPath;

-(NSString *)getLutPath;

-(NSString *)getMotionPath;

-(NSString *)getMakeupPath;

-(NSString *)getSegmentationPath;

- (UIImage *)imageNamed:(NSString *)name;

- (NSString *)localizedString:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
