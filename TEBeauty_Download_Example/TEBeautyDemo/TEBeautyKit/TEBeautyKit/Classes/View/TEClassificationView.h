//
//  TEClassificationView.h
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/12.
//

#import <UIKit/UIKit.h>


@interface TEClassificationView : UIView

@property(nonatomic, assign)BOOL enable;

- (instancetype)initWithTitle:(NSString *)title imageName:(NSString *)imageName;

- (void)setEnable:(BOOL)enable;

@end
