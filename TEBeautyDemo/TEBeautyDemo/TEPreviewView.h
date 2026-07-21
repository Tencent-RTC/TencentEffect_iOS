//
//  TEPreviewView.h
//  TEBeautyDemo
//
//  Created by jasonggao on 2025/3/5.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 预览视图，使用 AVSampleBufferDisplayLayer 作为根 layer
/// layer 会自动跟随 View 的 frame 变化
@interface TEPreviewView : UIView

@property (nonatomic, strong, readonly) AVSampleBufferDisplayLayer *previewLayer;

@end

NS_ASSUME_NONNULL_END
