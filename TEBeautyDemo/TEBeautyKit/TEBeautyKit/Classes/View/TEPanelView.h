//
//  TEPanelView.h
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/9.
//

#import <UIKit/UIKit.h>
#import <XMagic/XMagic.h>
#import "TEBeautyKit.h"
#import "TEUIDefine.h"

@protocol TEPanelViewDelegate <NSObject>

- (void)faceCapabilityStatusChanged:(BOOL)open;

- (void)gestureCapabilityStatusChanged:(BOOL)open;

- (void)showBeautyChanged:(BOOL)open;

- (void)takePhotoClick;

- (void)setEffect;

- (void)selectEffect:(TEUIProperty *)property;

- (void)selectCategory:(TEShoppingType)teShoppingType;

- (void)moreClicked:(BOOL)isShowGridLayout;

- (void)closeBottomView:(BOOL)closeBottom;

- (void) onResetBtnClick;

- (void) onCustomSegBtnClick;

- (void) onGreenscreenItemClick;

@end

@interface TEPanelView : UIView

@property (nonatomic, weak) XMagic *beautyKitApi;

@property (nonatomic, strong) TEBeautyKit *teBeautyKit;

@property (nonatomic, weak) id<TEPanelViewDelegate> delegate;

- (instancetype)init:(NSString *)abilityType comboType:(NSString *)comboType;

- (void)setLastParamList:(NSString *)lastParamList;

- (void)setDefaultBeauty;

- (void)performFullReset;

- (int)handleMediaAtPath:(NSString *)path;

- (void)setEnhancedMode:(BOOL)enhancedMode;

- (void)isShowCompareBtn:(BOOL)isShow;

@end
