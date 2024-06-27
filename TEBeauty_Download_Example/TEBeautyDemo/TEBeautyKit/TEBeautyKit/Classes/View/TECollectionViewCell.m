//
//  TECollectionViewCell.m
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/9.
//

#import "TECollectionViewCell.h"
#import "../Model/TEUIProperty.h"
#import <Masonry/Masonry.h>
#import "../Tool/TEUtils.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "../TEUIConfig.h"

@interface TECollectionViewCell()

@property (nonatomic, strong) UIView *coverView;

@property (nonatomic, strong) UIImageView *image; // icon图片

@property (nonatomic, strong) UILabel *label; // 名称

@property (nonatomic, strong) UIView *pointView; //小蓝点

@property (nonatomic, strong) UIView *line; //分割线

@end

@implementation TECollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initUI];
    }
    return self;
}

- (void)setTeUIProperty:(TEUIProperty *)teUIProperty{
    _teUIProperty = teUIProperty;
    if([TEUtils isURL:_teUIProperty.icon]){
        [self.image setImageWithURL:[NSURL URLWithString:_teUIProperty.icon] placeholderImage:[[TEUIConfig shareInstance] imageNamed:[_teUIProperty.icon lastPathComponent]]];
    }else{
        [self.image setImage:[[TEUIConfig shareInstance] imageNamed:[_teUIProperty.icon lastPathComponent]]];
    }
    if([TEUtils isCurrentLanguageHans]){
        [self.label setText:_teUIProperty.displayName];
    }else{
        [self.label setText:_teUIProperty.displayNameEn];
    }
    if (_teUIProperty.uiState == 2) {
        self.label.textColor = [TEUIConfig shareInstance].textCheckedColor;
        self.coverView.backgroundColor = [TEUIConfig shareInstance].panelItemCheckedColor;
        self.pointView.hidden = YES;
    } else if (_teUIProperty.uiState == 1){
        self.label.textColor = [TEUIConfig shareInstance].textColor;
        self.pointView.hidden = NO;
        self.coverView.backgroundColor = [UIColor clearColor];
    }else{
        self.label.textColor = [TEUIConfig shareInstance].textColor;
        self.pointView.hidden = YES;
        self.coverView.backgroundColor = [UIColor clearColor];
    }
    if(teUIProperty.propertyList.count == 0 && teUIProperty.sdkParam == nil){
        if(teUIProperty.paramList.count > 0){
            self.line.hidden = YES;
        }else{
            self.line.hidden = NO;
        }
    }else{
        self.line.hidden = YES;
    }
    if([self isItemInUse:teUIProperty]){
        self.pointView.hidden = NO;
        self.coverView.backgroundColor = [UIColor clearColor];
    }
}

-(BOOL)isItemInUse:(TEUIProperty *)teUIProperty{
    if(teUIProperty.propertyList.count == 0){
        return teUIProperty.uiState == 1;
    }else{
        for (TEUIProperty *property in teUIProperty.propertyList) {
            return [self isItemInUse:property];
        }
    }
    return NO;
}

-(void)setItemSelected:(BOOL)isSelected{
    if (isSelected) {
        self.coverView.backgroundColor = [UIColor colorWithRed:0 green:0.424 blue:1 alpha:1];
    }else{
        self.coverView.backgroundColor = [UIColor clearColor];
    }
}

-(void)initUI{
    self.coverView = [[UIView alloc] init];
    self.coverView.layer.cornerRadius = 8;
    self.coverView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.coverView];
    [self.coverView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(50);
        make.height.mas_equalTo(78);
        make.centerX.mas_equalTo(self.contentView);
        make.top.mas_equalTo(self.contentView);
    }];
    
    self.image = [[UIImageView alloc] init];
    self.image.layer.cornerRadius = 8;
    [self.contentView addSubview:self.image];
    [self.image mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(48);
        make.centerX.mas_equalTo(self.coverView.mas_centerX);
        make.top.mas_equalTo(self.coverView.mas_top).mas_offset(1);
    }];
    
    self.line = [[UIView alloc] init];
    self.line.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.15];
    [self.contentView addSubview:self.line];
    [self.line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(1);
        make.height.mas_equalTo(23);
        make.centerY.mas_equalTo(self.image.mas_centerY);
        make.right.mas_equalTo(self.contentView);
    }];
    self.line.hidden = YES;

    self.label = [[UILabel alloc] init];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.numberOfLines = 2;
    self.label.lineBreakMode = NSLineBreakByWordWrapping;
    [self.label setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:[TEUtils isCurrentLanguageHans] ? 10 : 8.5]];
    [self.coverView addSubview:self.label];
    [self.label setTextColor:[TEUIConfig shareInstance].textColor];
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.coverView);
        make.left.mas_equalTo(self.coverView.mas_left);
//        make.height.mas_equalTo()
        make.top.mas_equalTo(self.image.mas_bottom).mas_offset(3);
    }];

    self.pointView = [[UIView alloc] init];
    self.pointView.backgroundColor = [UIColor colorWithRed:0 green:0.424 blue:1 alpha:1];
    self.pointView.layer.cornerRadius = 1;
    [self.coverView addSubview:self.pointView];
    [self.pointView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(2);
        make.centerX.mas_equalTo(self.label.mas_centerX);
        make.top.mas_equalTo(self.label.mas_bottom);
    }];
    self.pointView.hidden = YES;

    // 创建一个圆角矩形路径
    UIBezierPath *roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 50, 78) cornerRadius:8];

    // 创建一个矩形路径作为透明洞
    UIBezierPath *holePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(1, 1, 48, 48) cornerRadius:8];

    // 将两个路径组合在一起
    [roundedRectPath appendPath:holePath];
    roundedRectPath.usesEvenOddFillRule = YES;

    // 使用CAShapeLayer设置coverView的遮罩
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = roundedRectPath.CGPath;
    maskLayer.fillRule = kCAFillRuleEvenOdd;
    self.coverView.layer.mask = maskLayer;
}

@end
