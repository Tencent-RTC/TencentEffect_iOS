//
//  TEClassificationView.m
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/12.
//

#import "TEClassificationView.h"
#import <Masonry/Masonry.h>
#import "../TEUIConfig.h"

@interface TEClassificationView()

@property (nonatomic, strong) UIView  *roundView;

@property (nonatomic, strong) UIImageView  *imageView;

@property (nonatomic, strong) UILabel  *label;

@property (nonatomic, copy) NSString  *title;

@property (nonatomic, copy) NSString  *imageName;

@end

@implementation TEClassificationView

- (instancetype)initWithTitle:(NSString *)title imageName:(NSString *)imageName{
    if (self = [super init]) {
        [self initWithName:title image:[[TEUIConfig shareInstance] imageNamed:imageName]];
    }
    return self;
}


-(void)initWithName:(NSString *)name image:(UIImage *)image{
    self.roundView = [[UIView alloc] init];
    self.roundView.frame = CGRectMake(0, 0, 48, 48);
    self.roundView.backgroundColor = [UIColor whiteColor];
    self.roundView.layer.cornerRadius = 24;
    self.roundView.clipsToBounds = YES;
    self.imageView = [[UIImageView alloc] init];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.imageView setTintColor:[UIColor colorWithRed:0 green:0x6e/255.0 blue:1 alpha:1]];
    [self.imageView setImage:image];
    [self.roundView addSubview:self.imageView];
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.width.mas_equalTo(35);
        make.centerX.mas_equalTo(self.roundView);
        make.centerY.mas_equalTo(self.roundView);
    }];
    [self addSubview:self.roundView];
    self.label = [[UILabel alloc] init];
    self.label.text = name;
    self.label.font = [UIFont systemFontOfSize:12];
    self.label.textColor = [UIColor whiteColor];
    self.label.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.label];
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(64);
        make.height.mas_equalTo(24);
        make.centerX.mas_equalTo(self.roundView.mas_centerX);
        make.top.mas_equalTo(self.roundView.mas_bottom).mas_offset(10);
    }];
}

- (void)setEnable:(BOOL)enable{
    _enable = enable;
    if(enable){
        self.roundView.backgroundColor = [UIColor whiteColor];
        self.label.textColor = [UIColor whiteColor];
    }else{
        self.roundView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
        self.label.textColor = [UIColor colorWithWhite:1 alpha:0.5];
    }
}

@end
