//
//  TEUIProperty.m
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/8.
//

#import "TEUIProperty.h"

@implementation Param

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

@end

@implementation ExtraInfo

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}


@end

@implementation TESDKParam


- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key{
    [super setValue:value forKey:key];
    if([key isEqualToString:@"extraInfo"]){
        self.extraInfo = [[ExtraInfo alloc] initWithDict:value];
    }else if ([key isEqualToString:@"effectValue"]){
        self.numericalType = YES;
    }
}

- (NSDictionary *)toDictionary{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:self.effectName forKey:@"effectName"];
    [dictionary setValue:@(self.effectValue) forKey:@"effectValue"];
    [dictionary setValue:self.resourcePath forKey:@"resourcePath"];
    [dictionary setValue:@(self.numericalType) forKey:@"numericalType"];
    [dictionary setValue:self.extraInfo forKey:@"extraInfo"];
    [dictionary setValue:self.extraInfoDic forKey:@"extraInfoDic"];

    return dictionary;
}
@end

@implementation TEUIProperty

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key{
    [super setValue:value forKey:key];
    if ([key isEqualToString:@"propertyList"]) {
        NSMutableArray<TEUIProperty *> *propertyList = [NSMutableArray array];
        for (NSDictionary *info in value) {
            TEUIProperty *teUiProperty = [[TEUIProperty alloc] init];
            [teUiProperty setValuesForKeysWithDictionary:info];
            [propertyList addObject:teUiProperty];
        }
        self.propertyList = propertyList;
    }else if([key isEqualToString:@"sdkParam"]){
        self.sdkParam = [[TESDKParam alloc] initWithDict:value];
    }else if ([key isEqualToString:@"paramList"]){
        NSMutableArray<Param *> *paramList = [NSMutableArray array];
        for (NSDictionary *info in value) {
            Param *param = [[Param alloc] init];
            [param setValuesForKeysWithDictionary:info];
            [paramList addObject:param];
        }
        self.paramList = paramList;
    }else if ([key isEqualToString:@"label"]){
        self.displayName = value;
    }else if ([key isEqualToString:@"labelEn"]){
        self.displayNameEn = value;
    }else if ([key isEqualToString:@"id"]){
        self.Id = value;
    }
}

@end
