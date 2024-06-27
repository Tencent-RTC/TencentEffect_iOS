//
//  TEToast.h
//  BeautyDemo
//
//  Created by tao yue on 2024/1/16.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TEToast : NSObject

+ (void)showWithText:(NSString *)text inView:(UIView *)view duration:(NSTimeInterval)duration;

@end

