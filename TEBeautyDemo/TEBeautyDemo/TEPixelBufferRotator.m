//
//  TEPixelBufferRotator.m
//  TEBeautyDemo
//

#import "TEPixelBufferRotator.h"
#import <Accelerate/Accelerate.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

// OpenGL ES 旋转所需的顶点着色器
static NSString *const kVertexShaderString = @"\
attribute vec4 position;\
attribute vec2 inputTextureCoordinate;\
varying vec2 textureCoordinate;\
void main() {\
    gl_Position = position;\
    textureCoordinate = inputTextureCoordinate;\
}";

// 片段着色器
static NSString *const kFragmentShaderString = @"\
precision mediump float;\
varying vec2 textureCoordinate;\
uniform sampler2D inputImageTexture;\
void main() {\
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);\
}";

@interface TEPixelBufferRotator ()

// 通用属性
@property (nonatomic, assign) TERotationEngineType engineType;
@property (nonatomic, assign) BOOL usesSharedContext;

// vImage 相关
@property (nonatomic, assign) CVPixelBufferPoolRef vImagePixelBufferPool;
@property (nonatomic, assign) size_t poolWidth;
@property (nonatomic, assign) size_t poolHeight;

// OpenGL ES 相关
@property (nonatomic, strong) EAGLContext *glContext;
@property (nonatomic, assign) GLuint program;
@property (nonatomic, assign) GLuint positionAttribute;
@property (nonatomic, assign) GLuint textureCoordinateAttribute;
@property (nonatomic, assign) GLuint inputTextureUniform;
@property (nonatomic, assign) GLuint frameBuffer;
@property (nonatomic, assign) GLuint renderTexture;
@property (nonatomic, assign) CVOpenGLESTextureCacheRef textureCache;
@property (nonatomic, assign) size_t glOutputWidth;
@property (nonatomic, assign) size_t glOutputHeight;

@end

@implementation TEPixelBufferRotator

- (instancetype)initWithEngineType:(TERotationEngineType)engineType {
    return [self initWithEngineType:engineType sharedContext:nil];
}

- (instancetype)initWithEngineType:(TERotationEngineType)engineType
                     sharedContext:(EAGLContext *)sharedContext {
    self = [super init];
    if (self) {
        _engineType = engineType;
        _usesSharedContext = (sharedContext != nil);
        if (engineType == TERotationEngineTypeOpenGLES) {
            [self setupOpenGLESWithSharedContext:sharedContext];
        }
    }
    return self;
}

- (void)dealloc {
    [self cleanup];
}

- (void)cleanup {
    [self cleanupVImageResources];
    [self cleanupOpenGLESResources];
}

#pragma mark - Public Methods

- (CVPixelBufferRef)rotatePixelBuffer:(CVPixelBufferRef)pixelBuffer
                            direction:(TERotationDirection)direction {
    if (pixelBuffer == NULL) {
        return NULL;
    }
    
    // 始终返回新的 buffer，即使 direction 为 None 也要 copy
    // 防止异步显示时原 buffer 被下一帧覆盖
    switch (self.engineType) {
        case TERotationEngineTypeVImage:
            return [self rotateWithVImage:pixelBuffer direction:direction];
        case TERotationEngineTypeOpenGLES:
            return [self rotateWithOpenGLES:pixelBuffer direction:direction];
    }
}

- (void)switchToEngineType:(TERotationEngineType)engineType {
    [self switchToEngineType:engineType sharedContext:nil];
}

- (void)switchToEngineType:(TERotationEngineType)engineType
             sharedContext:(EAGLContext *)sharedContext {
    if (_engineType == engineType) {
        return;
    }
    
    // 清理旧资源
    if (_engineType == TERotationEngineTypeVImage) {
        [self cleanupVImageResources];
    } else {
        [self cleanupOpenGLESResources];
    }
    
    _engineType = engineType;
    _usesSharedContext = (sharedContext != nil);
    
    // 初始化新引擎
    if (engineType == TERotationEngineTypeOpenGLES) {
        [self setupOpenGLESWithSharedContext:sharedContext];
    }
}

#pragma mark - vImage Implementation

- (CVPixelBufferRef)rotateWithVImage:(CVPixelBufferRef)pixelBuffer
                           direction:(TERotationDirection)direction {
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    size_t srcWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t srcHeight = CVPixelBufferGetHeight(pixelBuffer);
    size_t srcBytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    void *srcBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    // 计算目标尺寸
    size_t dstWidth, dstHeight;
    if (direction == TERotationDirectionCounterClock90 || direction == TERotationDirectionCounterClock270) {
        dstWidth = srcHeight;
        dstHeight = srcWidth;
    } else {
        dstWidth = srcWidth;
        dstHeight = srcHeight;
    }
    
    // 获取或创建 pixelBuffer
    CVPixelBufferRef dstPixelBuffer = [self getVImagePixelBufferWithWidth:dstWidth
                                                                   height:dstHeight
                                                              pixelFormat:CVPixelBufferGetPixelFormatType(pixelBuffer)];
    if (dstPixelBuffer == NULL) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        return NULL;
    }
    
    CVPixelBufferLockBaseAddress(dstPixelBuffer, 0);
    
    size_t dstBytesPerRow = CVPixelBufferGetBytesPerRow(dstPixelBuffer);
    void *dstBaseAddress = CVPixelBufferGetBaseAddress(dstPixelBuffer);
    
    vImage_Buffer srcBuffer = {
        .data = srcBaseAddress,
        .height = srcHeight,
        .width = srcWidth,
        .rowBytes = srcBytesPerRow
    };
    
    vImage_Buffer dstBuffer = {
        .data = dstBaseAddress,
        .height = dstHeight,
        .width = dstWidth,
        .rowBytes = dstBytesPerRow
    };
    
    // vImageRotate90_ARGB8888 的 rotationConstant 是逆时针方向：
    // 0 = 不旋转, 1 = 逆时针90°, 2 = 180°, 3 = 逆时针270°
    // TERotationDirection 也是逆时针方向，值完全一致，可以直接使用
    uint8_t bgColor[4] = {0, 0, 0, 0};
    vImageRotate90_ARGB8888(&srcBuffer, &dstBuffer, (uint8_t)direction, bgColor, kvImageNoFlags);
    
    CVPixelBufferUnlockBaseAddress(dstPixelBuffer, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    return dstPixelBuffer;
}

- (CVPixelBufferRef)getVImagePixelBufferWithWidth:(size_t)width
                                           height:(size_t)height
                                      pixelFormat:(OSType)pixelFormat {
    // 检查是否需要重新创建 pool
    if (_vImagePixelBufferPool == NULL || _poolWidth != width || _poolHeight != height) {
        [self cleanupVImageResources];
        
        NSDictionary *poolAttributes = @{
            (id)kCVPixelBufferPoolMinimumBufferCountKey: @(3)
        };
        
        NSDictionary *pixelBufferAttributes = @{
            (id)kCVPixelBufferWidthKey: @(width),
            (id)kCVPixelBufferHeightKey: @(height),
            (id)kCVPixelBufferPixelFormatTypeKey: @(pixelFormat),
            (id)kCVPixelBufferIOSurfacePropertiesKey: @{}
        };
        
        CVReturn status = CVPixelBufferPoolCreate(kCFAllocatorDefault,
                                                  (__bridge CFDictionaryRef)poolAttributes,
                                                  (__bridge CFDictionaryRef)pixelBufferAttributes,
                                                  &_vImagePixelBufferPool);
        if (status != kCVReturnSuccess) {
            NSLog(@"[TEPixelBufferRotator] Failed to create pixel buffer pool: %d", status);
            return NULL;
        }
        
        _poolWidth = width;
        _poolHeight = height;
    }
    
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault,
                                                         _vImagePixelBufferPool,
                                                         &pixelBuffer);
    if (status != kCVReturnSuccess) {
        NSLog(@"[TEPixelBufferRotator] Failed to create pixel buffer from pool: %d", status);
        return NULL;
    }
    
    return pixelBuffer;
}

- (void)cleanupVImageResources {
    if (_vImagePixelBufferPool) {
        CVPixelBufferPoolRelease(_vImagePixelBufferPool);
        _vImagePixelBufferPool = NULL;
    }
    _poolWidth = 0;
    _poolHeight = 0;
}

#pragma mark - OpenGL ES Implementation

- (void)setupOpenGLESWithSharedContext:(EAGLContext *)sharedContext {
    if (sharedContext) {
        // 使用共享上下文
        _glContext = sharedContext;
        _usesSharedContext = YES;
        NSLog(@"[TEPixelBufferRotator] Using shared OpenGL ES context");
    } else {
        // 创建新的上下文
        _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _usesSharedContext = NO;
        NSLog(@"[TEPixelBufferRotator] Created new OpenGL ES context");
    }
    
    if (!_glContext) {
        NSLog(@"[TEPixelBufferRotator] Failed to get/create OpenGL ES context");
        return;
    }
    
    EAGLContext *previousContext = [EAGLContext currentContext];
    [EAGLContext setCurrentContext:_glContext];
    
    // 创建纹理缓存
    CVReturn status = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault,
                                                   NULL,
                                                   _glContext,
                                                   NULL,
                                                   &_textureCache);
    if (status != kCVReturnSuccess) {
        NSLog(@"[TEPixelBufferRotator] Failed to create texture cache: %d", status);
        [EAGLContext setCurrentContext:previousContext];
        return;
    }
    
    // 编译着色器
    [self compileShaders];
    
    // 创建帧缓冲
    glGenFramebuffers(1, &_frameBuffer);
    
    [EAGLContext setCurrentContext:previousContext];
}

- (void)compileShaders {
    GLuint vertexShader = [self compileShader:kVertexShaderString type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:kFragmentShaderString type:GL_FRAGMENT_SHADER];
    
    _program = glCreateProgram();
    glAttachShader(_program, vertexShader);
    glAttachShader(_program, fragmentShader);
    glLinkProgram(_program);
    
    GLint linkStatus;
    glGetProgramiv(_program, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_program, sizeof(messages), 0, &messages[0]);
        NSLog(@"[TEPixelBufferRotator] Program link error: %s", messages);
    }
    
    _positionAttribute = glGetAttribLocation(_program, "position");
    _textureCoordinateAttribute = glGetAttribLocation(_program, "inputTextureCoordinate");
    _inputTextureUniform = glGetUniformLocation(_program, "inputImageTexture");
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
}

- (GLuint)compileShader:(NSString *)shaderString type:(GLenum)type {
    GLuint shader = glCreateShader(type);
    const char *source = [shaderString UTF8String];
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);
    
    GLint compileStatus;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileStatus);
    if (compileStatus == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        NSLog(@"[TEPixelBufferRotator] Shader compile error: %s", messages);
    }
    
    return shader;
}

- (CVPixelBufferRef)rotateWithOpenGLES:(CVPixelBufferRef)pixelBuffer
                             direction:(TERotationDirection)direction {
    if (!_glContext || !_textureCache) {
        return NULL;
    }
    
    EAGLContext *previousContext = [EAGLContext currentContext];
    [EAGLContext setCurrentContext:_glContext];
    
    size_t srcWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t srcHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    // 计算目标尺寸
    size_t dstWidth, dstHeight;
    if (direction == TERotationDirectionCounterClock90 || direction == TERotationDirectionCounterClock270) {
        dstWidth = srcHeight;
        dstHeight = srcWidth;
    } else {
        dstWidth = srcWidth;
        dstHeight = srcHeight;
    }
    
    // 创建输入纹理
    CVOpenGLESTextureRef inputTexture = NULL;
    CVReturn status = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                   _textureCache,
                                                                   pixelBuffer,
                                                                   NULL,
                                                                   GL_TEXTURE_2D,
                                                                   GL_RGBA,
                                                                   (GLsizei)srcWidth,
                                                                   (GLsizei)srcHeight,
                                                                   GL_BGRA,
                                                                   GL_UNSIGNED_BYTE,
                                                                   0,
                                                                   &inputTexture);
    if (status != kCVReturnSuccess || !inputTexture) {
        NSLog(@"[TEPixelBufferRotator] Failed to create input texture: %d", status);
        [EAGLContext setCurrentContext:previousContext];
        return NULL;
    }
    
    // 创建输出 pixelBuffer
    CVPixelBufferRef outputPixelBuffer = NULL;
    NSDictionary *attributes = @{
        (id)kCVPixelBufferWidthKey: @(dstWidth),
        (id)kCVPixelBufferHeightKey: @(dstHeight),
        (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
        (id)kCVPixelBufferIOSurfacePropertiesKey: @{},
        (id)kCVPixelBufferOpenGLESCompatibilityKey: @YES
    };
    
    status = CVPixelBufferCreate(kCFAllocatorDefault,
                                 dstWidth,
                                 dstHeight,
                                 kCVPixelFormatType_32BGRA,
                                 (__bridge CFDictionaryRef)attributes,
                                 &outputPixelBuffer);
    if (status != kCVReturnSuccess) {
        NSLog(@"[TEPixelBufferRotator] Failed to create output pixel buffer: %d", status);
        CFRelease(inputTexture);
        [EAGLContext setCurrentContext:previousContext];
        return NULL;
    }
    
    // 创建输出纹理
    CVOpenGLESTextureRef outputTexture = NULL;
    status = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          _textureCache,
                                                          outputPixelBuffer,
                                                          NULL,
                                                          GL_TEXTURE_2D,
                                                          GL_RGBA,
                                                          (GLsizei)dstWidth,
                                                          (GLsizei)dstHeight,
                                                          GL_BGRA,
                                                          GL_UNSIGNED_BYTE,
                                                          0,
                                                          &outputTexture);
    if (status != kCVReturnSuccess || !outputTexture) {
        NSLog(@"[TEPixelBufferRotator] Failed to create output texture: %d", status);
        CFRelease(inputTexture);
        CVPixelBufferRelease(outputPixelBuffer);
        [EAGLContext setCurrentContext:previousContext];
        return NULL;
    }
    
    // 绑定帧缓冲
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                           CVOpenGLESTextureGetName(outputTexture), 0);
    
    GLenum fbStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (fbStatus != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"[TEPixelBufferRotator] Framebuffer incomplete: %d", fbStatus);
        CFRelease(inputTexture);
        CFRelease(outputTexture);
        CVPixelBufferRelease(outputPixelBuffer);
        [EAGLContext setCurrentContext:previousContext];
        return NULL;
    }
    
    glViewport(0, 0, (GLsizei)dstWidth, (GLsizei)dstHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(_program);
    
    // 绑定输入纹理
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(inputTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(_inputTextureUniform, 0);
    
    // 设置顶点坐标（全屏四边形）
    static const GLfloat vertices[] = {
        -1.0f, -1.0f,
         1.0f, -1.0f,
        -1.0f,  1.0f,
         1.0f,  1.0f,
    };
    
    // 根据旋转方向设置纹理坐标
    const GLfloat *textureCoordinates = [self textureCoordinatesForDirection:direction];
    
    glEnableVertexAttribArray(_positionAttribute);
    glVertexAttribPointer(_positionAttribute, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    
    glEnableVertexAttribArray(_textureCoordinateAttribute);
    glVertexAttribPointer(_textureCoordinateAttribute, 2, GL_FLOAT, GL_FALSE, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glFinish();
    
    // 清理
    glDisableVertexAttribArray(_positionAttribute);
    glDisableVertexAttribArray(_textureCoordinateAttribute);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    CFRelease(inputTexture);
    CFRelease(outputTexture);
    
    // 刷新纹理缓存
    CVOpenGLESTextureCacheFlush(_textureCache, 0);
    
    [EAGLContext setCurrentContext:previousContext];
    
    return outputPixelBuffer;
}

- (const GLfloat *)textureCoordinatesForDirection:(TERotationDirection)direction {
    // 顶点坐标顺序：左下、右下、左上、右上
    // 顶点: (-1,-1), (1,-1), (-1,1), (1,1)
    // OpenGL ES 纹理坐标原点在左下角，(0,0) 左下，(1,1) 右上
    
    // 不旋转：纹理直接对应
    static const GLfloat noRotation[] = {
        0.0f, 0.0f,  // 左下
        1.0f, 0.0f,  // 右下
        0.0f, 1.0f,  // 左上
        1.0f, 1.0f,  // 右上
    };
    
    // 逆时针 90°：图像逆时针旋转 90°
    // 原图的顶部变成左边，底部变成右边，左边变成底部，右边变成顶部
    // 顶点左下->纹理右下, 顶点右下->纹理右上, 顶点左上->纹理左下, 顶点右上->纹理左上
    static const GLfloat rotateCounterClock90[] = {
        1.0f, 0.0f,  // 左下 -> 纹理右下
        1.0f, 1.0f,  // 右下 -> 纹理右上
        0.0f, 0.0f,  // 左上 -> 纹理左下
        0.0f, 1.0f,  // 右上 -> 纹理左上
    };
    
    // 180°：图像倒转
    static const GLfloat rotate180[] = {
        1.0f, 1.0f,  // 左下 -> 纹理右上
        0.0f, 1.0f,  // 右下 -> 纹理左上
        1.0f, 0.0f,  // 左上 -> 纹理右下
        0.0f, 0.0f,  // 右上 -> 纹理左下
    };
    
    // 逆时针 270°（顺时针 90°）：
    // 顶点左下->纹理左上, 顶点右下->纹理左下, 顶点左上->纹理右上, 顶点右上->纹理右下
    static const GLfloat rotateCounterClock270[] = {
        0.0f, 1.0f,  // 左下 -> 纹理左上
        0.0f, 0.0f,  // 右下 -> 纹理左下
        1.0f, 1.0f,  // 左上 -> 纹理右上
        1.0f, 0.0f,  // 右上 -> 纹理右下
    };
    
    switch (direction) {
        case TERotationDirectionCounterClock90:
            return rotateCounterClock90;
        case TERotationDirectionCounterClock180:
            return rotate180;
        case TERotationDirectionCounterClock270:
            return rotateCounterClock270;
        default:
            return noRotation;
    }
}

- (void)cleanupOpenGLESResources {
    if (_glContext) {
        EAGLContext *previousContext = [EAGLContext currentContext];
        [EAGLContext setCurrentContext:_glContext];
        
        if (_frameBuffer) {
            glDeleteFramebuffers(1, &_frameBuffer);
            _frameBuffer = 0;
        }
        
        if (_renderTexture) {
            glDeleteTextures(1, &_renderTexture);
            _renderTexture = 0;
        }
        
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        if (_textureCache) {
            CVOpenGLESTextureCacheFlush(_textureCache, 0);
            CFRelease(_textureCache);
            _textureCache = NULL;
        }
        
        [EAGLContext setCurrentContext:previousContext];
        
        // 清空引用（共享上下文由外部管理生命周期，这里只是释放本地引用）
        _glContext = nil;
    }
}

@end
