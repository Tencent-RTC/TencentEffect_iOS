//
//  RadioButton.h
//  TEBeautyDemo
//
//  Created by tao yue on 2024/6/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

//! Project version number for IRRadioButton.
FOUNDATION_EXPORT double IRRadioButtonVersionNumber;

//! Project version string for IRRadioButton.
FOUNDATION_EXPORT const unsigned char IRRadioButtonVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <IRRadioButton/PublicHeader.h>

@protocol RadioButtonDelegate <NSObject>
- (void)ir_RadioButtonSelectedAtIndex:(NSUInteger)index inGroup:(NSString *)groupId;

@end

@interface RadioButton : UIView

//单选按钮
@property (nonatomic, strong, readonly) UIButton    *radioButton;

//所在组标志位
@property (nonatomic, strong, readonly) NSString    *groupId;

//按钮在所在组的索引号
@property (nonatomic, assign, readonly) NSUInteger  index;

//显示在右边的内容Lable
@property (nonatomic, strong, readonly) UILabel     *textLbl;

//是否选中状态
@property (nonatomic, assign, readonly, getter = isSelected) BOOL selected;

- (id)initWithFrame:(CGRect)frame groupId:(NSString *)groupId index:(NSUInteger)index;

//设置默认选中项，默认未选中
- (void)setSelected:(BOOL)selected;

- (void)setFont:(UIFont *)font;

- (void)setTextColor:(UIColor *)color;

//设置显示在右边的文字
- (void)setText:(NSString *)text;

+ (void)addObserver:(id)observer forGroupId:(NSString *)groupId;
//移除分组观察者
+ (void)removeObserverForGroupId:(NSString *)groupId;
//移除所有观察者
+ (void)removeAllObserver;

@end

NS_ASSUME_NONNULL_END
