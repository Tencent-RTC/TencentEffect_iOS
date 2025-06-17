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

//美颜面板背景色
@property(nonatomic,strong)UIColor *panelBackgroundColor;
//分割线颜色
@property(nonatomic,strong)UIColor *panelDividerColor;
//选中项颜色
@property(nonatomic,strong)UIColor *panelItemCheckedColor;
//文本颜色
@property(nonatomic,strong)UIColor *textColor;
//文本选中颜色
@property(nonatomic,strong)UIColor *textCheckedColor;
//进度条颜色
@property(nonatomic,strong)UIColor *seekBarProgressColor;

+ (instancetype)shareInstance;
/**
 beauty:美颜json路径
 beautyBody：美体json路径
 lut：滤镜json路径
 motion：动效json路径
 makeup：美妆json路径
 segmentation：背景分割json路径
 */
-(void)setTEPanelViewRes:(NSString *)beauty beautyBody:(NSString *)beautyBody lut:(NSString *)lut motion:(NSString *)motion makeup:(NSString *)makeup segmentation:(NSString *)segmentation lightMakeup:(NSString *)lightMakeup;


/// 根据美颜套餐设置美颜面板的数据
/// - Parameter panelLevel: 美颜套餐
-(void)setPanelLevel:(TEPanelLevel)panelLevel;

-(NSString *)getBeautyPath;

-(NSString *)getBeautyBodyPath;

-(NSString *)getLutPath;

-(NSString *)getMotionPath;

-(NSString *)getMakeupPath;

-(NSString *)getLightMakeupPath;

-(NSString *)getSegmentationPath;

- (UIImage *)imageNamed:(NSString *)name;

- (NSString *)localizedString:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
