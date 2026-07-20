//
//  TEPixelBufferRotator.h
//  TEBeautyDemo
//
//  图像旋转工具类，支持 vImage 和 OpenGL ES 两种方式
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@class EAGLContext;

NS_ASSUME_NONNULL_BEGIN

/// 旋转方向（逆时针，与 vImage 一致）
typedef NS_ENUM(NSInteger, TERotationDirection) {
    TERotationDirectionNone = 0,                  // 不旋转
    TERotationDirectionCounterClock90 = 1,    // 逆时针90度
    TERotationDirectionCounterClock180 = 2,   // 180度
    TERotationDirectionCounterClock270 = 3,   // 逆时针270度（顺时针90度）
};

/// 旋转引擎类型
typedef NS_ENUM(NSInteger, TERotationEngineType) {
    TERotationEngineTypeVImage,    // 使用 Accelerate/vImage (CPU)
    TERotationEngineTypeOpenGLES,  // 使用 OpenGL ES (GPU)
};

@interface TEPixelBufferRotator : NSObject

/// 当前使用的旋转引擎类型
@property (nonatomic, assign, readonly) TERotationEngineType engineType;

/// 是否使用共享的 GL 上下文
@property (nonatomic, assign, readonly) BOOL usesSharedContext;

/// 初始化旋转器（自动创建 GL 上下文）
/// @param engineType 旋转引擎类型
- (instancetype)initWithEngineType:(TERotationEngineType)engineType;

/// 初始化旋转器（使用共享的 GL 上下文）
/// @param engineType 旋转引擎类型
/// @param sharedContext 共享的 EAGLContext，传 nil 则自动创建新的上下文
- (instancetype)initWithEngineType:(TERotationEngineType)engineType
                     sharedContext:(nullable EAGLContext *)sharedContext;

/// 旋转 PixelBuffer
/// @param pixelBuffer 输入的 pixelBuffer
/// @param direction 旋转方向
/// @return 旋转后的 pixelBuffer（调用者负责释放）
- (nullable CVPixelBufferRef)rotatePixelBuffer:(CVPixelBufferRef)pixelBuffer
                                     direction:(TERotationDirection)direction CF_RETURNS_RETAINED;

/// 切换旋转引擎（使用新建上下文）
/// @param engineType 新的引擎类型
- (void)switchToEngineType:(TERotationEngineType)engineType;

/// 切换旋转引擎（可指定共享上下文）
/// @param engineType 新的引擎类型
/// @param sharedContext 共享的 EAGLContext，传 nil 则自动创建新的上下文
- (void)switchToEngineType:(TERotationEngineType)engineType
             sharedContext:(nullable EAGLContext *)sharedContext;

/// 释放资源
- (void)cleanup;

@end

NS_ASSUME_NONNULL_END
