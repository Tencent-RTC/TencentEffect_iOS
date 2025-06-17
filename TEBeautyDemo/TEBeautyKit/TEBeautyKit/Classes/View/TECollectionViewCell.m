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

-(void)initUI {
    self.coverView = [[UIView alloc] init];
    self.coverView.layer.cornerRadius = 6;
    self.coverView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.coverView];
    [self.coverView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(62);
        make.height.mas_equalTo(85);
        make.centerX.mas_equalTo(self.contentView);
        make.top.mas_equalTo(self.contentView);
    }];
    
    self.image = [[UIImageView alloc] init];
    self.image.layer.cornerRadius = 6;
    [self.contentView addSubview:self.image];
    [self.image mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(56);
        make.centerX.mas_equalTo(self.coverView.mas_centerX);
        make.top.mas_equalTo(self.coverView.mas_top).mas_offset(2);
    }];
    
    self.label = [[UILabel alloc] init];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.numberOfLines = 1;
    self.label.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.label setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:[TEUtils isCurrentLanguageHans] ? 12 : 8.5]];
    [self.coverView addSubview:self.label];
    [self.label setTextColor:[TEUIConfig shareInstance].textColor];
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.coverView);
        make.left.mas_equalTo(self.coverView.mas_left);
        make.top.mas_equalTo(self.image.mas_bottom).mas_offset(5);
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
    [self.contentView layoutIfNeeded];
     CGRect imageFrame = [self.image convertRect:self.image.bounds toView:self.coverView];

     UIBezierPath *roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:self.coverView.bounds cornerRadius:10];

     UIBezierPath *holePath = [UIBezierPath bezierPathWithRoundedRect:imageFrame cornerRadius:10];

     [roundedRectPath appendPath:holePath];
     roundedRectPath.usesEvenOddFillRule = YES;

     CAShapeLayer *maskLayer = [CAShapeLayer layer];
     maskLayer.path = roundedRectPath.CGPath;
     maskLayer.fillRule = kCAFillRuleEvenOdd;
     self.coverView.layer.mask = maskLayer;
}

@end
