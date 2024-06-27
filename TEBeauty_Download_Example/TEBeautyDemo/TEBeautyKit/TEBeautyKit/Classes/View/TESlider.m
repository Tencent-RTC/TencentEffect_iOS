//
//  TESlider.m
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/10.
//

#import "TESlider.h"

#import "WaterDropView.h"

@interface TESlider()

@property (nonatomic, strong) WaterDropView *waterDropView;

@end


@implementation TESlider

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
    self.waterDropView = [[WaterDropView alloc] initWithFrame:CGRectMake(0, 0, 30, 50)]; // 设置合适的frame
    self.waterDropView.hidden = YES;
    [self addSubview:self.waterDropView];
    [self addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateWaterDropViewPosition];
}

- (void)updateWaterDropViewPosition {
    CGRect thumbRect = [self thumbRectForBounds:self.bounds trackRect:[self trackRectForBounds:self.bounds] value:self.value];
    self.waterDropView.center = CGPointMake(CGRectGetMidX(thumbRect), thumbRect.origin.y - self.waterDropView.bounds.size.height / 2);
}

- (void)sliderValueChanged:(UISlider *)slider {
    self.waterDropView.number = slider.value;
    [self updateWaterDropViewPosition];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL result = [super beginTrackingWithTouch:touch withEvent:event];
    if (result) {
        self.waterDropView.hidden = NO;
        [self updateWaterDropViewPosition];
    }
    return result;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    self.waterDropView.hidden = YES;
}

- (void)dealloc {
    [self removeTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
}
@end
