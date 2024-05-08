//
//  TESwitch.h
//  BeautyDemo
//
//  Created by tao yue on 2024/1/14.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TESwitchStyle) {
    TESwitchStyleNoBorder,
    TESwitchStyleBorder
};

@interface TESwitch : UIControl

@property (nonatomic, assign, getter = isOn) BOOL on;

@property (nonatomic, assign) TESwitchStyle style;

@property (nonatomic, strong) UIColor *onTintColor;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, strong) UIColor *thumbTintColor;
@property (nonatomic, strong) UIColor *borderColor;

@property (nonatomic, strong) UIColor *onTextColor;
@property (nonatomic, strong) UIColor *offTextColor;
@property (nonatomic, strong) UIFont *textFont;
@property (nonatomic, strong) NSString *onText;
@property (nonatomic, strong) NSString *offText;

- (void)setOn:(BOOL)on animated:(BOOL)animated;

@end
