//
//  TEUIConfig.m
//  BeautyDemo
//
//  Created by tao yue on 2024/1/21.
//

#import "BeautyParamConfig.h"

@interface BeautyParamConfig()

@property (nonatomic, strong) NSString *lastBeautyParam; // 使用 strong 修饰符

@end

@implementation BeautyParamConfig

+ (instancetype)sharedInstance
{
    static BeautyParamConfig *param;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        param = [[BeautyParamConfig alloc] init];
    });
    return param;
}

- (instancetype)init {
    if (self = [super init]) {
        // 初始化代码
    }
    return self;
}

- (NSString *)getLastBeautyParam {
    return self.lastBeautyParam;
}

- (void)setLastBeautyParam:(NSString *)lastBeautyParam {
    _lastBeautyParam = lastBeautyParam;
}

@end
