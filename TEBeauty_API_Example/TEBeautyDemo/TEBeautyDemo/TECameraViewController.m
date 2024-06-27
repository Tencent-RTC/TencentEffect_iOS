//
//  TECameraViewController.m
//  TEBeautyDemo
//
//  Created by chavezchen on 2024/4/24.
//

#import "TECameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "Masonry.h"
#import "XMagic/XMagic.h"
#import "XMagic/XmagicConstant.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "RadioButton.h"
#import <SevenSwitch/SevenSwitch.h>
#import <objc/runtime.h>
#import "RadioButton.h"
#import <MobileCoreServices/MobileCoreServices.h>


typedef NS_ENUM(NSUInteger, PreviewResolution) {
    PreviewResolution540P = 0,
    PreviewResolution720P = 1,
    PreviewResolution1080P = 2
};

// 视频长度限制(ms)
static const int MAX_SEG_VIDEO_DURATION = 200 * 1000;
static char kEnableCompleteKey;
static char kDisenableCompleteKey;
int effValue = 60;
float multiple = 1.2;

@interface TECameraViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,YTSDKEventListener, YTSDKLogListener,RadioButtonDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property(nonatomic, assign) PreviewResolution currentPreviewResolution;
// Camera related
@property (nonatomic, strong) AVCaptureDevice *cameraDevice;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVSampleBufferDisplayLayer *previewLayer;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) XMagic *xMagicKit;
@property (nonatomic, strong) UILabel *faceCountLabel;
@property (nonatomic, assign) BOOL showFace;
@property (nonatomic, assign) BOOL enableEnhancedMode;

@end

@implementation TECameraViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self buildUI];
    [self initXMagic];
    [self buildCamra];
}

- (void)buildUI
{
    self.view.backgroundColor = [UIColor blackColor];
    self.currentPreviewResolution = PreviewResolution720P;
    
    self.previewLayer = [AVSampleBufferDisplayLayer layer];
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    self.previewLayer.frame = self.view.bounds;
    
    [self.view addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.view.mas_bottom);
        make.left.right.mas_equalTo(self.view);
        make.height.mas_equalTo(370);
    }];
    
    //人脸检测
    [self.view addSubview:self.faceCountLabel];
    [self.faceCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).mas_offset(10);
        make.right.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view).mas_offset(100);
        make.height.mas_equalTo(30);
    }];
    __weak __typeof(self)weakSelf = self;
    //增强模式
    UIView *strongView = [self selectView:@"增强模式" enableComplete:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.xMagicKit enableEnhancedMode];
        strongSelf.enableEnhancedMode = YES;
    } disenableCpmplete:^{
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.enableEnhancedMode = NO;
    }];
    [self.bottomView addSubview:strongView];
    [strongView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.bottomView);
        make.left.mas_equalTo(self.bottomView).mas_offset(10);
        make.right.mas_equalTo(self.bottomView);
        make.height.mas_equalTo(30);
    }];
    //智能美颜
    UIView *smartBeautyView = [self selectView:@"智能美颜（男性或婴儿效果减弱）" enableComplete:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.xMagicKit setFeatureEnableDisable:SMART_BEAUTY enable:YES];
    } disenableCpmplete:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.xMagicKit setFeatureEnableDisable:SMART_BEAUTY enable:NO];
    }];
    [self.bottomView addSubview:smartBeautyView];
    [smartBeautyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(strongView);
        make.right.mas_equalTo(self.bottomView);
        make.top.mas_equalTo(strongView.mas_bottom);
        make.height.mas_equalTo(30);
    }];
    //人脸检测
    UIView *faceView = [self selectView:@"人脸检测" enableComplete:^{
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.showFace = YES;
    } disenableCpmplete:^{
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.showFace = NO;
    }];
    [self.bottomView addSubview:faceView];
    [faceView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(strongView);
        make.right.mas_equalTo(self.bottomView);
        make.top.mas_equalTo(smartBeautyView.mas_bottom);
        make.height.mas_equalTo(30);
    }];
    //美白
    UIView *whiteView = [self selectView:@"美白" enableComplete:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.enableEnhancedMode) {
            effValue = effValue * multiple;
        }
        [strongSelf.xMagicKit setEffect:BEAUTY_WHITEN effectValue:effValue resourcePath:nil extraInfo:nil];
    } disenableCpmplete:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.xMagicKit setEffect:BEAUTY_WHITEN effectValue:0 resourcePath:nil extraInfo:nil];
    }];
    [self.bottomView addSubview:whiteView];
    [whiteView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(strongView);
        make.top.mas_equalTo(faceView.mas_bottom);
        make.width.mas_equalTo(65);
        make.height.mas_equalTo(30);
    }];
    //磨皮
    UIView *smoothView = [self selectView:@"磨皮" enableComplete:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.enableEnhancedMode) {
            effValue = effValue * multiple;
        }
        [strongSelf.xMagicKit setEffect:BEAUTY_SMOOTH effectValue:effValue resourcePath:nil extraInfo:nil];
    } disenableCpmplete:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.xMagicKit setEffect:BEAUTY_SMOOTH effectValue:0 resourcePath:nil extraInfo:nil];
    }];
    [self.bottomView addSubview:smoothView];
    [smoothView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(whiteView.mas_right).mas_offset(10);
        make.top.mas_equalTo(whiteView);
        make.width.mas_equalTo(65);
        make.height.mas_equalTo(30);
    }];
    //滤镜
    UIView *lutView = [self selectView:@"滤镜" enableComplete:^{
        __strong typeof(self) strongSelf = weakSelf;
        NSString *path = [[[NSBundle mainBundle] pathForResource:@"lut" ofType:@"bundle"] stringByAppendingPathComponent:@"baixi_lf.png"];
        [strongSelf.xMagicKit setEffect:EFFECT_LUT effectValue:60 resourcePath:path extraInfo:nil];
    } disenableCpmplete:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.xMagicKit setEffect:EFFECT_LUT effectValue:0 resourcePath:nil extraInfo:nil];
    }];
    [self.bottomView addSubview:lutView];
    [lutView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(smoothView.mas_right).mas_offset(10);
        make.top.mas_equalTo(smoothView);
        make.width.mas_equalTo(65);
        make.height.mas_equalTo(30);
    }];
    //瘦脸-自然
    UIView *thinFaceView = [self selectView:@"瘦脸-自然" enableComplete:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.enableEnhancedMode) {
            effValue = effValue * multiple;
        }
        [strongSelf.xMagicKit setEffect:BEAUTY_FACE_NATURE effectValue:effValue resourcePath:nil extraInfo:nil];
    } disenableCpmplete:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.xMagicKit setEffect:BEAUTY_FACE_NATURE effectValue:0 resourcePath:nil extraInfo:nil];
    }];
    [self.bottomView addSubview:thinFaceView];
    [thinFaceView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(lutView.mas_right).mas_offset(10);
        make.top.mas_equalTo(lutView);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(30);
    }];
    //口红-复古红
    CGRect rect = CGRectMake(20, 20, 160, 25);
    RadioButton *lips_fugu = [[RadioButton alloc] initWithFrame:rect groupId:@"lips" index:0];
    [lips_fugu setText:@"口红-复古红"];
    [lips_fugu setFont:[UIFont systemFontOfSize:16]];
    [lips_fugu setTextColor:[UIColor whiteColor]];
    [self.bottomView addSubview:lips_fugu];
    [lips_fugu mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(strongView);
        make.top.mas_equalTo(whiteView.mas_bottom);
        make.width.mas_equalTo(110);
        make.height.mas_equalTo(30);
    }];
    //口红-活力橙
    RadioButton *lips_huoli = [[RadioButton alloc] initWithFrame:rect groupId:@"lips" index:1];
    [lips_huoli setText:@"口红-活力橙"];
    [lips_huoli setFont:[UIFont systemFontOfSize:16]];
    [lips_huoli setTextColor:[UIColor whiteColor]];
    [self.bottomView addSubview:lips_huoli];
    [lips_huoli mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(lips_fugu.mas_right).mas_offset(10);
        make.top.mas_equalTo(lips_fugu);
        make.width.mas_equalTo(110);
        make.height.mas_equalTo(30);
    }];
    //口红-无
    RadioButton *lips_none = [[RadioButton alloc] initWithFrame:rect groupId:@"lips" index:2];
    [lips_none setText:@"口红-无"];
    [lips_none setFont:[UIFont systemFontOfSize:16]];
    [lips_none setTextColor:[UIColor whiteColor]];
    [self.bottomView addSubview:lips_none];
    [lips_none mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(lips_huoli.mas_right).mas_offset(10);
        make.top.mas_equalTo(lips_huoli);
        make.width.mas_equalTo(110);
        make.height.mas_equalTo(30);
    }];
    [RadioButton addObserver:self forGroupId:@"lips"];
    //美妆与动效
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor grayColor];
    label.font = [UIFont systemFontOfSize:16];
    label.text = @"美妆与动效";
    [self.bottomView addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(strongView);
        make.top.mas_equalTo(lips_fugu.mas_bottom);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(30);
    }];
    //美妆
    RadioButton *makeup = [[RadioButton alloc] initWithFrame:rect groupId:@"motion" index:0];
    [makeup setText:@"美妆"];
    [makeup setFont:[UIFont systemFontOfSize:16]];
    [makeup setTextColor:[UIColor whiteColor]];
    [self.bottomView addSubview:makeup];
    [makeup mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(strongView);
        make.top.mas_equalTo(label.mas_bottom);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(30);
    }];
    //动效
    RadioButton *motion = [[RadioButton alloc] initWithFrame:rect groupId:@"motion" index:1];
    [motion setText:@"动效"];
    [motion setFont:[UIFont systemFontOfSize:16]];
    [motion setTextColor:[UIColor whiteColor]];
    [self.bottomView addSubview:motion];
    [motion mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(strongView);
        make.top.mas_equalTo(makeup.mas_bottom);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(30);
    }];
    //背景分割
    RadioButton *segmentation = [[RadioButton alloc] initWithFrame:rect groupId:@"motion" index:2];
    [segmentation setText:@"背景分割"];
    [segmentation setFont:[UIFont systemFontOfSize:16]];
    [segmentation setTextColor:[UIColor whiteColor]];
    [self.bottomView addSubview:segmentation];
    [segmentation mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(strongView);
        make.top.mas_equalTo(motion.mas_bottom);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(30);
    }];
    //自定义背景分割
    RadioButton *customSegmentation = [[RadioButton alloc] initWithFrame:rect groupId:@"motion" index:3];
    [customSegmentation setText:@"自定义背景分割"];
    [customSegmentation setFont:[UIFont systemFontOfSize:16]];
    [customSegmentation setTextColor:[UIColor whiteColor]];
    [self.bottomView addSubview:customSegmentation];
    [customSegmentation mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(strongView);
        make.top.mas_equalTo(segmentation.mas_bottom);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(30);
    }];
    //动效叠加
    RadioButton *mergeMotion = [[RadioButton alloc] initWithFrame:rect groupId:@"motion" index:4];
    [mergeMotion setText:@"动效叠加"];
    [mergeMotion setFont:[UIFont systemFontOfSize:16]];
    [mergeMotion setTextColor:[UIColor whiteColor]];
    [self.bottomView addSubview:mergeMotion];
    [mergeMotion mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(strongView);
        make.top.mas_equalTo(customSegmentation.mas_bottom);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(30);
    }];
    //无
    RadioButton *motionNone = [[RadioButton alloc] initWithFrame:rect groupId:@"motion" index:5];
    [motionNone setText:@"无"];
    [motionNone setFont:[UIFont systemFontOfSize:16]];
    [motionNone setTextColor:[UIColor whiteColor]];
    [self.bottomView addSubview:motionNone];
    [motionNone mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(strongView);
        make.top.mas_equalTo(mergeMotion.mas_bottom);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(30);
    }];
    [RadioButton addObserver:self forGroupId:@"motion"];
}

- (UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    }
    return _bottomView;
}

- (UIView *)selectView:(NSString *)title enableComplete:(void(^ )(void))enableComplete disenableCpmplete:(void(^ )(void))disenableCpmplete{
    UIFont *font = [UIFont systemFontOfSize:16];
    CGFloat switchWidth = 30;
    CGFloat viewHeight = 20;
    CGFloat textWidth = [self textWidthFromTitle:title font:font];
    UIView *contentView = [[UIView alloc] init];
    contentView.frame = CGRectMake(0, 0, switchWidth + textWidth, viewHeight);
    SevenSwitch *mySwitch = [[SevenSwitch alloc] initWithFrame:CGRectMake(0, 2, 30, 15)];
    [mySwitch addTarget:self action:@selector(swicthAction:) forControlEvents:UIControlEventValueChanged];
    objc_setAssociatedObject(mySwitch, &kEnableCompleteKey, enableComplete, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(mySwitch, &kDisenableCompleteKey, disenableCpmplete, OBJC_ASSOCIATION_COPY_NONATOMIC);

    [contentView addSubview:mySwitch];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(switchWidth + 1, 0, textWidth, viewHeight)];
    label.text = title;
    label.font = font;
    label.textColor = [UIColor whiteColor];
    [contentView addSubview:label];
    return contentView;
}

- (UILabel *)faceCountLabel{
    if (!_faceCountLabel) {
        _faceCountLabel = [[UILabel alloc] init];
        _faceCountLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
        _faceCountLabel.textColor = [UIColor grayColor];
    }
    return _faceCountLabel;
}

- (void)swicthAction:(SevenSwitch*)sw{
    void (^enableComplete)(void) = objc_getAssociatedObject(sw, &kEnableCompleteKey);
    void (^disenableCpmplete)(void) = objc_getAssociatedObject(sw, &kDisenableCompleteKey);

    if (sw.on && enableComplete != nil) {
        enableComplete();
    }
    if (!sw.on && disenableCpmplete != nil) {
        disenableCpmplete();
    }
}

- (CGFloat)textWidthFromTitle:(NSString *)title font:(UIFont *)font{
    CGSize constrainedSize = CGSizeMake(0, MAXFLOAT);
    CGRect textRect = [title boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName:font} context:nil];
    return textRect.size.width + 1;
}

- (void)initXMagic {
    NSDictionary *assetsDict = @{@"core_name":@"LightCore.bundle",
                                 @"root_path":[[NSBundle mainBundle] bundlePath],
                                 @"enableHighPerformance":@(_isEnableHighPerformance)
    };
    _xMagicKit = [[XMagic alloc] initWithRenderSize:CGSizeMake(720, 1280) assetsDict:assetsDict];
    [_xMagicKit registerSDKEventListener:self];
    [_xMagicKit registerLoggerListener:self withDefaultLevel:YT_SDK_ERROR_LEVEL];
}

-(void)configSegmentation:(NSString *)bgPath bgType:(NSString*)bgType{
    NSString *resourcePath = [[[NSBundle mainBundle] pathForResource:@"segmentMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:@"video_empty_segmentation"];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    dic[@"segType"] = @"custom_background";
    dic[@"bgType"] = bgType;
    dic[@"bgPath"] = bgPath;
    [_xMagicKit setEffect:EFFECT_SEGMENTATION effectValue:0 resourcePath:resourcePath extraInfo:dic];
}

-(void)openImagePicker{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    //资源类型为图片库
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes =@[(NSString*)kUTTypeMovie, (NSString*)kUTTypeImage];
    picker.delegate = self;
    picker.allowsEditing = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

// UIImage固定方向UIImageOrientationUp
- (UIImage *)fixOrientation:(UIImage*)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
    }
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
    }
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
-(NSString *)createImagePath:(NSString *)fileName{
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [path objectAtIndex:0];
    NSString *imageDocPath = [documentPath stringByAppendingPathComponent:@"TencentEffect_MediaFile"];
    [[NSFileManager defaultManager] createDirectoryAtPath:imageDocPath withIntermediateDirectories:YES attributes:nil error:nil];
    return [imageDocPath stringByAppendingPathComponent:fileName];
}
// 视频压缩转码处理
- (int)convertVideoQuailtyWithInputURL:(NSURL*)inputURL
                              outputURL:(NSURL*)outputURL
                        completeHandler:(void (^)(AVAssetExportSession*))handler {
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    CMTime videoTime = [avAsset duration];
    int timeOffset = ceil(1000 * videoTime.value / videoTime.timescale) - 10;
    if (timeOffset > MAX_SEG_VIDEO_DURATION) {
        NSLog(@"background video too long(limit %i)", MAX_SEG_VIDEO_DURATION);
        return 5003;
    }
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse= YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        switch (exportSession.status) {
            case AVAssetExportSessionStatusCompleted:{
                NSLog(@"AVAssetExportSessionStatusCompleted");
                [self configSegmentation:outputURL.path bgType:@"1"];
            }
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"AVAssetExportSessionStatusCancelled");
                break;
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"AVAssetExportSessionStatusUnknown");
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"AVAssetExportSessionStatusWaiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"AVAssetExportSessionStatusExporting");
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"AVAssetExportSessionStatusFailed");
                break;
        }
    }];
    if (exportSession.status == AVAssetExportSessionStatusFailed) {
        NSLog(@"background video export failed");
        return 5002;
    }
    return 0;
}
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    // 移除相册界面
       int errorCode = 0;
       [picker.view removeFromSuperview];
       // 获取文件类型:
       NSString *mediaType = info[UIImagePickerControllerMediaType];
       if ([mediaType isEqualToString:(NSString*)kUTTypeImage]) {
           // 用户选的文件为图片类型(kUTTypeImage)
           UIImage *image = info[UIImagePickerControllerOriginalImage];
           image = [self fixOrientation:image];
           NSData *data = UIImagePNGRepresentation(image);
           //返回为png图像。
           if (!data) {
               //返回为JPEG图像。
               data = UIImageJPEGRepresentation(image, 1.0);
           }
           NSString *imagePath = [self createImagePath:@"image.png"];
           [[NSFileManager defaultManager] createFileAtPath:imagePath contents:data attributes:nil];
           [picker dismissViewControllerAnimated:YES completion:nil];
           [self configSegmentation:imagePath bgType:@"0"];
       }else if([mediaType isEqualToString:(NSString*)kUTTypeMovie]){
           NSURL *sourceURL = [info objectForKey:UIImagePickerControllerMediaURL];
           NSDateFormatter *formater = [[NSDateFormatter alloc] init];
           [formater setDateFormat:@"yyyy-MM-dd-HH.mm.ss"];
           NSURL *newVideoUrl = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents/output-%@.mp4", [formater stringFromDate:[NSDate date]]]];
           [picker dismissViewControllerAnimated:YES completion:nil];
           // 处理视频 压缩视频
           errorCode = [self convertVideoQuailtyWithInputURL:sourceURL outputURL:newVideoUrl completeHandler:nil];
       } else {
           errorCode = 5004;
       }
       if (errorCode) {
           NSString* errorMsg = @"";
           switch (errorCode) {
           case 5000:
               errorMsg = @"分割背景图片分辨率超过2160*3840";
               break;
           case 5002:
               errorMsg = @"分割背景视频解析失败";
               break;
           case 5003:
               errorMsg = @"分割背景视频超过200秒";
               break;
           case 5004:
               errorMsg = @"分割背景视频格式不支持";
               break;
           default:
               break;
           }
           UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"背景导入失败" message:[NSString stringWithFormat:@"%i: %@", errorCode, errorMsg] preferredStyle:UIAlertControllerStyleAlert];
           [self presentViewController:alertVC animated:YES completion:nil];
       }
}

// 取消图片选择回调
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - IRRadioButtonDelegate

- (void)ir_RadioButtonSelectedAtIndex:(NSUInteger)index inGroup:(NSString *)groupId{
    if ([groupId isEqualToString:@"lips"]) {
        if (index == 0) {
            if (_enableEnhancedMode) {
                effValue = effValue * multiple;
            }
            [_xMagicKit setEffect:BEAUTY_MOUTH_LIPSTICK effectValue:effValue resourcePath:@"/images/beauty/lips_fuguhong.png" extraInfo:nil];
        }else if (index == 1){
            if (_enableEnhancedMode) {
                effValue = effValue * multiple;
            }
            [_xMagicKit setEffect:BEAUTY_MOUTH_LIPSTICK effectValue:effValue resourcePath:@"/images/beauty/lips_huolicheng.png" extraInfo:nil];
        }else if (index == 2){
            [_xMagicKit setEffect:BEAUTY_MOUTH_LIPSTICK effectValue:0 resourcePath:nil extraInfo:nil];
        }
    }else if ([groupId isEqualToString:@"motion"]){
        if (index == 0) {
            //美妆
            NSString *path = [[[NSBundle mainBundle] pathForResource:@"makeupMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:@"video_makeup_xuemei"];
            [_xMagicKit setEffect:EFFECT_MAKEUP effectValue:60 resourcePath:path extraInfo:nil];
        }else if (index == 1){
            //动效
            NSString *path = [[[NSBundle mainBundle] pathForResource:@"2dMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:@"video_keaituya"];
            [_xMagicKit setEffect:EFFECT_MOTION effectValue:0 resourcePath:path extraInfo:nil];
        }else if (index == 2){
            //背景分割
            NSString *path = [[[NSBundle mainBundle] pathForResource:@"segmentMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:@"video_segmentation_blur_75"];
            [_xMagicKit setEffect:EFFECT_MOTION effectValue:0 resourcePath:path extraInfo:nil];
        }else if (index == 3){
            //自定义背景分割
            [self openImagePicker];
        }else if (index == 4){
            //动效叠加:美妆和2D贴纸叠加
            NSString *path = [[[NSBundle mainBundle] pathForResource:@"makeupMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:@"video_makeup_xuemei"];
            [_xMagicKit setEffect:EFFECT_MAKEUP effectValue:60 resourcePath:path extraInfo:@{@"mergeWithCurrentMotion":@"true"}];
            NSString *motionPath = [[[NSBundle mainBundle] pathForResource:@"2dMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:@"video_keaituya"];
            [_xMagicKit setEffect:EFFECT_MOTION effectValue:0 resourcePath:motionPath extraInfo:@{@"mergeWithCurrentMotion":@"true"}];
            
        }else if (index == 5){
            //动效-无
            [_xMagicKit setEffect:EFFECT_MOTION effectValue:0 resourcePath:nil extraInfo:nil];
        }
    }
}

#pragma mark - cramera
- (void)buildCamra
{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                           error:nil];
    [self buildCamera:AVCaptureDevicePositionFront];
}

- (BOOL)checkCameraAuthorization {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:@"Tencent Effect想访问您的相机"
                                                               message:nil
                                                              delegate:self
                                                     cancelButtonTitle:@"不允许"
                                                     otherButtonTitles:@"好", nil];
            [alerView show];
        });
        return NO;
    }
    return YES;
}
- (void)buildCamera:(AVCaptureDevicePosition)cameraPosition {
    if (![self checkCameraAuthorization]) {
        return;
    }
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            // 设置摄像头翻转
            NSArray *cameraDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
            for (AVCaptureDevice *cameraDevice in cameraDevices) {
                self.cameraDevice = cameraDevice;
                if (cameraDevice.position == cameraPosition) {
                    break;
                }
            }
            AVCaptureSession *cameraCaptureSession = [[AVCaptureSession alloc] init];
            cameraCaptureSession.sessionPreset = AVCaptureSessionPresetHigh;
            [cameraCaptureSession beginConfiguration];
            
            if(self->_currentPreviewResolution == PreviewResolution540P){
                cameraCaptureSession.sessionPreset = AVCaptureSessionPresetiFrame960x540;
            } else if(self->_currentPreviewResolution == PreviewResolution1080P){
                cameraCaptureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
            } else {
                cameraCaptureSession.sessionPreset = AVCaptureSessionPreset1280x720;
            }
            
            AVCaptureDeviceInput *cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:self.cameraDevice error:nil];
            if ([cameraCaptureSession canAddInput:cameraInput]) {
                [cameraCaptureSession addInput:cameraInput];
            }
            // VideoDataOutput
            dispatch_queue_t videoDataQueue = dispatch_queue_create("com.tencent.youtu.videodata", NULL);
            self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
            self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
            self.videoDataOutput.videoSettings = @{(id) kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
            [self.videoDataOutput setSampleBufferDelegate:self queue:videoDataQueue];
            
            //设置帧率到30FPS
            int desiredFrameRate = 30;
            AVCaptureDeviceFormat *desiredFormat = nil;
            for ( AVCaptureDeviceFormat *format in [self.cameraDevice formats] ) {
              for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
                  if ( self.cameraDevice.activeFormat == format && range.maxFrameRate >= desiredFrameRate && range.minFrameRate <= desiredFrameRate ) {
                      desiredFormat = format;
                      break;
                  }
              }
              if (desiredFormat != nil) {
                  break;
              }
            }
            if ( desiredFormat ) {
              if ( [self.cameraDevice lockForConfiguration:NULL] == YES ) {
                  self.cameraDevice.activeVideoMinFrameDuration = CMTimeMake ( 1, desiredFrameRate );
                  self.cameraDevice.activeVideoMaxFrameDuration = CMTimeMake ( 1, desiredFrameRate );
                  [self.cameraDevice unlockForConfiguration];
              }
            }
            if ([cameraCaptureSession canAddOutput:self.videoDataOutput]) {
                [cameraCaptureSession addOutput:self.videoDataOutput];
            }
            cameraCaptureSession.usesApplicationAudioSession = YES;
            cameraCaptureSession.automaticallyConfiguresApplicationAudioSession = NO;
            [cameraCaptureSession commitConfiguration];
            for (AVCaptureOutput *output in cameraCaptureSession.outputs) {
                for (AVCaptureConnection *connection in output.connections) {
                    if (connection.isVideoOrientationSupported) {
                        connection.videoOrientation = AVCaptureVideoOrientationPortrait;
                    }
                    if (connection.isVideoMirroringSupported) {
                        connection.videoMirrored = cameraPosition == AVCaptureDevicePositionFront;
                    }
                }
            }
            if (cameraCaptureSession.inputs.count > 0 && cameraCaptureSession.outputs.count > 0) {
                [cameraCaptureSession startRunning];
            }
            self.captureSession = cameraCaptureSession;
        }
    }];
}

-(NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
    options:NSJSONReadingMutableContainers
    error:&err];
    if(err) {
    NSLog(@"json解析失败：%@",err);
    return nil;
    }
    return dic;

}

// 退后台停止渲染
- (void)viewWillResignActive:(NSNotification *)noti {
    [self stopUpdatingView];
}

// 后台返回恢复动效
- (void)viewDidBecomeActive:(NSNotification *)noti {
    [self resumeUpdatingView];
}

- (void)stopUpdatingView
{
    // 暂停摄像头
    if (self.captureSession) {
        [self.captureSession stopRunning];
    }
    
    [self.xMagicKit onPause];
}

- (void)resumeUpdatingView
{
    //恢复摄像头
    if (self.captureSession) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.captureSession startRunning];
        });
    }
    
    [self.xMagicKit onResume];
}
- (void)viewDidAppear:(BOOL)animated
{
    [self resumeUpdatingView];
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopUpdatingView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];

    [super viewWillDisappear:animated];

}

- (void)dealloc
{
    [_xMagicKit clearListeners];
    [_xMagicKit deinit];
    [RadioButton removeObserverForGroupId:@"lips"];
    [RadioButton removeObserverForGroupId:@"motion"];
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (captureOutput == self.videoDataOutput) {
        [self mycaptureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection originImageProcess:YES];
    }
}

- (void)mycaptureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)inputSampleBuffer fromConnection:(AVCaptureConnection *)connection originImageProcess:(BOOL)originImageProcess
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(inputSampleBuffer);
    YTProcessInput *input = [[YTProcessInput alloc] init];
    input.pixelData = [[YTImagePixelData alloc] init];
    input.pixelData.data = pixelBuffer;
    input.dataType = kYTImagePixelData;
    
    YTProcessOutput *output = [self.xMagicKit process:input];
    if (output.pixelData.data != nil) {
        CMSampleBufferRef outSampleBuffer = [self sampleBufferFromPixelBuffer:output.pixelData.data];
        // 这里是处理进入后台后layer失效问题
        if (self.previewLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            [self.previewLayer flush];
        }
        if (outSampleBuffer != NULL) {
            [self.previewLayer enqueueSampleBuffer:outSampleBuffer];
            CFRelease(outSampleBuffer);
        }
    }
    
    if (output != nil) {
        output.pixelData = nil;
        output = nil;
    }
}

- (CMSampleBufferRef)sampleBufferFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CFRetain(pixelBuffer);
    CMSampleBufferRef outputSampleBuffer = NULL;
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timing, &outputSampleBuffer);

    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(outputSampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    
    CFRelease(videoInfo);
    CFRelease(pixelBuffer);
    return outputSampleBuffer;
}

#pragma mark YTSDKEventListener

- (void)onAIEvent:(id)event{
    if (self.showFace) {
        NSDictionary *eventDict = (NSDictionary *)event;
        if (eventDict[@"ai_info"] != nil){
            NSDictionary *dic = [self dictionaryWithJsonString:eventDict[@"ai_info"]];
            if(dic != nil && dic[@"face_info"] != nil){
                NSArray *faceArray = dic[@"face_info"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.faceCountLabel.text = [NSString stringWithFormat:@"Face Count:%lu",(unsigned long)faceArray.count];
                });
            }
        }
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.faceCountLabel.text = @"";
        });
    }
}

- (void)onTipsEvent:(id)event{
    
}

- (void)onLog:(YtSDKLoggerLevel)loggerLevel withInfo:(NSString *)logInfo{
    
}

@end
