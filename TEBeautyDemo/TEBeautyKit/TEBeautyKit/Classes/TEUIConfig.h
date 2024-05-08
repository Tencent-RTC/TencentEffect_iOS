//
//  TEUIConfig.h
//  BeautyDemo
//
//  Created by tao yue on 2024/1/21.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


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
