//
//  TEPreviewView.m
//  TEBeautyDemo
//
//  Created by jasonggao on 2025/3/5.
//

#import "TEPreviewView.h"

@implementation TEPreviewView

+ (Class)layerClass {
    return [AVSampleBufferDisplayLayer class];
}

- (AVSampleBufferDisplayLayer *)previewLayer {
    return (AVSampleBufferDisplayLayer *)self.layer;
}

@end
