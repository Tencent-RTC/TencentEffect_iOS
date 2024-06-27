//
//  TEUtils.m
//  BeautyDemo
//
//  Created by tao yue on 2024/1/14.
//

#import "TEUtils.h"
#import <UIKit/UIKit.h>

@implementation TEUtils

/**
 判断当前语言是否是简体中文
 */
+(BOOL)isCurrentLanguageHans
{
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *currentLanguage = [languages firstObject];
    if ([currentLanguage hasPrefix:@"zh"])
    {
        return YES;
    }
    return NO;
}

+ (BOOL)isURL:(NSString *)uri {
    if (uri.length == 0) {
        return NO;
    }
    NSURL *url = [NSURL URLWithString:uri];
    return url && url.scheme && url.host;
}

+ (CGFloat)textWidthFromTitle:(NSString *)title font:(UIFont *)font{
    CGSize constrainedSize = CGSizeMake(0, MAXFLOAT);
    CGRect textRect = [title boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName:font} context:nil];
    return textRect.size.width + 1;
}

@end
