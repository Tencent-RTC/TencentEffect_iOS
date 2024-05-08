//
//  WaterDropView.m
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/10.
//

#import "WaterDropView.h"
@interface WaterDropView()

@property (nonatomic, strong) UILabel *numberLabel;
@end

@implementation WaterDropView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];

    _numberLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _numberLabel.textAlignment = NSTextAlignmentCenter;
    _numberLabel.font = [UIFont systemFontOfSize:12];
    _numberLabel.textColor = [UIColor whiteColor];
    [self addSubview:_numberLabel];
}

- (void)setNumber:(NSInteger)number {
    self.numberLabel.text = [NSString stringWithFormat:@"%ld", (long)number];
}


- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    // 获取当前视图的宽度和高度
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);

    // 计算圆形的半径和圆心位置
    CGFloat radius = width / 2;
    CGPoint center = CGPointMake(width / 2, height / 2);

    // 创建圆形路径
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:0 endAngle:2 * M_PI clockwise:YES];

    // 设置圆形的颜色和线宽
    [[UIColor colorWithRed:0 green:0.424 blue:1 alpha:1] setFill];
    [circlePath fill];

    // 计算等边三角形的顶点位置
    CGFloat angle = M_PI / 3;
    CGPoint trianglePointA = CGPointMake(center.x - radius * cos(angle / 2), center.y + radius * sin(angle / 2));
    CGPoint trianglePointB = CGPointMake(center.x + radius * cos(angle / 2), center.y + radius * sin(angle / 2));
    CGPoint trianglePointC = CGPointMake(center.x, center.y + radius + radius * sin(angle / 2));

    // 创建等边三角形路径
    UIBezierPath *trianglePath = [UIBezierPath bezierPath];
    [trianglePath moveToPoint:trianglePointA];
    [trianglePath addLineToPoint:trianglePointB];
    [trianglePath addLineToPoint:trianglePointC];
    [trianglePath closePath];

    // 设置三角形的颜色和线宽
    [[UIColor colorWithRed:0 green:0.424 blue:1 alpha:1] setFill];
    [trianglePath fill];
}
@end
