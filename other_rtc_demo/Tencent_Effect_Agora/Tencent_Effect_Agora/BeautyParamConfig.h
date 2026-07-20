//
//  TEUIConfig.h
//  BeautyDemo
//
//  Created by tao yue on 2024/1/21.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


@interface BeautyParamConfig : NSObject

+ (instancetype)sharedInstance;

- (void)setLastBeautyParam:(NSString *)lastBeautyParam;

- (NSString *)getLastBeautyParam;
 
@end

NS_ASSUME_NONNULL_END
