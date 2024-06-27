//
//  Util.h
//  BeautyDemo
//
//  Created by tao yue on 2024/1/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TEUtils : NSObject

+ (BOOL)isCurrentLanguageHans;

+ (BOOL)isURL:(NSString *)uri;

+ (CGFloat)textWidthFromTitle:(NSString *)title font:(UIFont *)font;

@end
