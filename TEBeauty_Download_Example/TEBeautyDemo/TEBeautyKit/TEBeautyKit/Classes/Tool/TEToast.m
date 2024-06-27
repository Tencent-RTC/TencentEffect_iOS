//
//  TEToast.m
//  BeautyDemo
//
//  Created by tao yue on 2024/1/16.
//

#import "TEToast.h"

@implementation TEToast

+ (void)showWithText:(NSString *)text inView:(UIView *)view duration:(NSTimeInterval)duration {
    UILabel *toastLabel = [[UILabel alloc] init];
    toastLabel.text = text;
    toastLabel.textColor = [UIColor whiteColor];
    toastLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    toastLabel.font = [UIFont systemFontOfSize:14.0];
    toastLabel.textAlignment = NSTextAlignmentCenter;
    toastLabel.numberOfLines = 0;
    [toastLabel sizeToFit];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    toastLabel.frame = CGRectMake((screenSize.width - toastLabel.frame.size.width - 40) / 2,
                                  screenSize.height * 0.8 - toastLabel.frame.size.height - 10,
                                  toastLabel.frame.size.width + 40,
                                  toastLabel.frame.size.height + 10);
    toastLabel.layer.cornerRadius = toastLabel.frame.size.height / 2;
    toastLabel.layer.masksToBounds = YES;
    
    [view addSubview:toastLabel];
    
    [UIView animateWithDuration:0.5
                          delay:duration
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         toastLabel.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [toastLabel removeFromSuperview];
                     }];
}

@end
