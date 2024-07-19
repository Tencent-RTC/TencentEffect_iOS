//
//  TEPanelView.m
//  TEBeautyKit
//
//  Created by tao yue on 2024/1/9.
//

#import <objc/runtime.h>
#import "TEPanelView.h"
#import "TECollectionViewCell.h"
#import "../Provider/TEPanelDataProvider.h"
#import <Masonry/Masonry.h>
#import "../Model/TEUIProperty.h"
#import "TESlider.h"
#import "../Download/TEDownloader.h"
#import "TEClassificationView.h"
#import "TESwitch.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "../Tool/TEUtils.h"
#import "../Tool/TEToast.h"
#import "../Tool/TEUIDefine.h"
#import <XMagic/XmagicConstant.h>
#import "../TEUIConfig.h"

// 视频长度限制(ms)
static const int MAX_SEG_VIDEO_DURATION = 200 * 1000;
#define beautyCollectionItemWidth 70
#define beautyCollectionItemHeight 78
// 屏幕的宽
#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
// 屏幕的高
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height

@interface TEPanelView()<UICollectionViewDelegate,UICollectionViewDataSource,UIImagePickerControllerDelegate>

@property (nonatomic, strong) UICollectionView *beautyCollection;
@property (nonatomic, strong) TEUIProperty *currentUIProperty;
@property (nonatomic, strong) NSMutableArray<TEUIProperty *> *defaultBeautyList;
@property (nonatomic, strong) NSMutableArray<TEUIProperty *> *currentUIPropertyList;
@property (nonatomic, strong) TEPanelDataProvider *tePanelDataProvider;
@property (nonatomic, strong) UIView *blackView;
@property (nonatomic, strong) UIView *vLineView;
@property (nonatomic, strong) UIView *hLineView;
@property (nonatomic, strong) UIView *rightResetView;
@property (nonatomic, strong) UIView *commonView;
@property (nonatomic, strong) UIView *resetView;
@property (nonatomic, strong) UIView *closeBottomView;
@property (nonatomic, strong) UIView *openBottomView;
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIView *templateParamView;
@property (nonatomic, strong) UIScrollView* scrollView;
@property (nonatomic, strong) UILabel *beautyTitleLabel;
@property (nonatomic, strong) UIButton  *backButton;
@property (nonatomic, strong) NSMutableArray <UIButton *>*titleBtns;//美颜类型title
@property (nonatomic, strong) UISlider *commonSlider;
@property (nonatomic, strong) TESlider *teSlider;
@property (nonatomic, strong) UIView *makeupOrLut;
@property (nonatomic, strong) UIButton *compareButton; // 美颜对比按钮
@property (nonatomic, strong) UIView *loadingCover;
@property (nonatomic, strong) UILabel *processLabel;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) UIImageView *takePhoto; //拍照
@property (nonatomic, strong) TESwitch *capabilitiesSwitch;
@property (nonatomic, strong) UILabel *capabilitiesStatusLabel;
@property (nonatomic, assign) BOOL faceSwitchStatus;
@property (nonatomic, assign) BOOL gestureSwitchStatus;
@property (nonatomic, strong) UIView *underView;
@property (nonatomic, assign) int segmentationBgType;
@property (nonatomic, assign) int segmentationType;
@property (nonatomic, copy) NSString* segmentationResPath;
@property (nonatomic, copy) NSString* segmentationPath;
@property (nonatomic, copy) NSString* mergeCurMotion;
@property (nonatomic, strong) NSNumber* timeOffset;
@property (nonatomic, copy) NSString *abilityType;
@property (nonatomic, copy) NSString *comboType;
@property (nonatomic, assign) int makeupType;
@property (nonatomic, assign) int templateType;
@property (nonatomic, strong) TEUIProperty *currentTemplateProperty;
@property (nonatomic, assign) int beautyType;
@property (nonatomic, assign) int selectedIndex;
@property (nonatomic, assign) BOOL isShowLoading;
@property (nonatomic, assign) int showProgress;
@property (nonatomic, assign) BOOL showCompareBtn;
@property (nonatomic, assign) BOOL enhancedMode;//增强模式
@property (nonatomic, assign) BOOL showOrigin;//是否显示原图
@property (nonatomic, assign) BOOL templateParam;//是否是在修改美颜模板界面
@property (nonatomic, strong) TEUIProperty *lastTemplateProperty;
//分类View
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIView *originBeautyView;
@property (nonatomic, strong) TEClassificationView *stickerView;
@property (nonatomic, strong) TEClassificationView *beautyView;
@property (nonatomic, strong) UIImageView *photoView;
@property (nonatomic, strong) UIButton *photoBtn;
@property (nonatomic, strong) TEClassificationView *makeupView;
@property (nonatomic, strong) TEClassificationView *lutView;


@end

@implementation TEPanelView

- (instancetype)init:(NSString *)abilityType comboType:(NSString *)comboType{
    if (self = [super init]) {
        self.abilityType = abilityType;
        self.comboType = comboType;
        self.showCompareBtn = YES;
        [self initData];
        [self initUI];
    }
    return self;
}

-(void)initData{
    _tePanelDataProvider = [TEPanelDataProvider shareInstance];
    if([self isTEDemo]){
        if([_abilityType isEqualToString:TEUI_BEAUTY] ||
           [_abilityType isEqualToString:TEUI_BEAUTY_IMAGE] ||
           [_abilityType isEqualToString:TEUI_BEAUTY_SHAPE] ||
           [_abilityType isEqualToString:TEUI_BEAUTY_BODY]){
            _currentUIPropertyList = [_tePanelDataProvider getAbilitiesBeautyData:self.comboType];
            _beautyType = (int)[_tePanelDataProvider.abilitiesBeautyArray indexOfObject:_abilityType];
        }else if ([_abilityType isEqualToString:TEUI_BEAUTY_MAKEUP] ||
                  [_abilityType isEqualToString:TEUI_MAKEUP]){
            _currentUIPropertyList = [_tePanelDataProvider getAbilitiesMakeupData:self.comboType];
            _beautyType = (int)[_tePanelDataProvider.abilitiesMakeupArray indexOfObject:_abilityType];
        }else if ([_abilityType isEqualToString:TEUI_MOTION_2D] ||
                  [_abilityType isEqualToString:TEUI_MOTION_3D] ||
                  [_abilityType isEqualToString:TEUI_MOTION_GESTURE] ||
                  [_abilityType isEqualToString:TEUI_MOTION_CAMERA_MOVE] ||
                  [_abilityType isEqualToString:TEUI_SEGMENTATION]){
            _currentUIPropertyList = [_tePanelDataProvider getAbilitiesMotionData:self.comboType];
            _beautyType = (int)[_tePanelDataProvider.abilitiesMotionArray indexOfObject:_abilityType];
        }else if([_abilityType isEqualToString:TEUI_LUT] ){
            _currentUIProperty = [_tePanelDataProvider getLutData];
            return;
        }else if ([_abilityType isEqualToString:TEUI_PORTRAIT_SEGMENTATION]){
            _currentUIProperty = [_tePanelDataProvider getPortraitSegmentationData];
            return;
        }else if ([_abilityType isEqualToString:TEUI_BEAUTY_TEMPLATE]){
            _currentUIPropertyList = [_tePanelDataProvider getAbilitiesTemplateData:self.comboType];
        }else if ([_abilityType isEqualToString:TEUI_GESTURE_DETECTION] ||
                  [_abilityType isEqualToString:TEUI_FACE_DETECTION]){
            _currentUIPropertyList = [_tePanelDataProvider getCapabilitiesListData];
            _beautyType = (int)[_tePanelDataProvider.capabilitiesArray indexOfObject:_abilityType];
            if([_abilityType isEqualToString:TEUI_GESTURE_DETECTION]){
                _gestureSwitchStatus = YES;
            }else{
                _faceSwitchStatus = YES;
            }
        }
        _defaultBeautyList = [_tePanelDataProvider getAbilitiesBeautyData:self.comboType];
        _currentUIProperty = _currentUIPropertyList[_beautyType];
    }else{
        _currentUIPropertyList = [_tePanelDataProvider getAllPanelData];
        _currentUIProperty = _currentUIPropertyList[_beautyType];
    }
}


-(void)initUI{
    if([self isTEDemo]){
        self.backgroundColor = [UIColor clearColor];
        self.commonView = [[UIView alloc]init];
        self.commonView.backgroundColor = [UIColor clearColor];
        self.commonView.userInteractionEnabled = YES;
        [self addSubview:self.commonView];
        [self.commonView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.mas_equalTo(self);
        }];
        
        [self.commonView addSubview:self.blackView];
        [self.blackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self.mas_width);
            make.left.mas_equalTo(self.mas_left);
            make.top.mas_equalTo(self.mas_top).offset(40);
            make.height.mas_equalTo(290);
        }];

        [self.commonView addSubview:self.beautyCollection];
        [self.beautyCollection mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self.mas_width);
            make.left.mas_equalTo(self.mas_left);
            make.top.mas_equalTo(self.mas_top).offset(90);
            make.height.mas_equalTo(beautyCollectionItemHeight);
        }];
        
        [self.commonView addSubview:self.makeupOrLut];
        [self.makeupOrLut mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(82);
            make.height.mas_equalTo(26);
            make.left.mas_equalTo(self).mas_offset(10);
        }];
        self.makeupOrLut.hidden = YES;

        [self.commonView addSubview:self.compareButton];
        [self.compareButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self).mas_offset(-5);
            make.top.mas_equalTo(self);
            make.width.height.mas_equalTo(35);
        }];
        
        [self.commonView addSubview:self.teSlider];
        [self.teSlider mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self).mas_offset(10);
            make.right.mas_equalTo(self).mas_offset(-45);
            make.centerY.mas_equalTo(self.compareButton.mas_centerY);
        }];
        self.teSlider.hidden = YES;

        _hLineView= [[UIView alloc] init];
        _hLineView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
        [self.commonView addSubview:_hLineView];
        [_hLineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self.mas_width);
            make.left.mas_equalTo(self.mas_left);
            make.top.mas_equalTo(self.blackView).mas_offset(38);
            make.height.mas_equalTo(1);
        }];

        [self.commonView addSubview:self.capabilitiesSwitch];
        [self.capabilitiesSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(42);
            make.height.mas_equalTo(30);
            make.top.mas_equalTo(_hLineView).mas_offset(25);
            make.centerX.mas_equalTo(self);
        }];

        [self.commonView addSubview:self.capabilitiesStatusLabel];
        [self.capabilitiesStatusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(42);
            make.height.mas_equalTo(30);
            make.top.mas_equalTo(self.capabilitiesSwitch.mas_bottom).mas_offset(2);
            make.centerX.mas_equalTo(self);
        }];

        self.underView = [[UIView alloc]init];
        self.underView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        self.underView.userInteractionEnabled = YES;
        [self addSubview:self.underView];
        [self.underView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(self);
            make.top.mas_equalTo(self.beautyCollection.mas_bottom);
            make.bottom.mas_equalTo(self.mas_bottom);
        }];

        [self addSubview:self.takePhoto];
        [self.takePhoto mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(74);
            make.top.mas_equalTo(self.beautyCollection.mas_bottom).mas_offset(10);
            make.centerX.mas_equalTo(self);
        }];

        [self.commonView addSubview:self.resetView];
        [self.resetView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(24);
            make.height.mas_equalTo(42);
            make.top.mas_equalTo(self.beautyCollection.mas_bottom).mas_offset(20);
            make.left.mas_equalTo(self).mas_offset(23);
        }];

        [self.commonView addSubview:self.backView];
        [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(24);
            make.height.mas_equalTo(42);
            make.top.mas_equalTo(self.beautyCollection.mas_bottom).mas_offset(20);
            make.right.mas_equalTo(self).mas_offset(-23);
        }];
        self.backView.hidden = YES;

        [self.commonView addSubview:self.closeBottomView];
        [self.closeBottomView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(24);
            make.height.mas_equalTo(42);
            make.top.mas_equalTo(self.beautyCollection.mas_bottom).mas_offset(20);
            if([_abilityType isEqualToString:TEUI_BEAUTY_TEMPLATE]){
                make.left.mas_equalTo(self).mas_offset(23);
            }else{
                make.right.mas_equalTo(self).mas_offset(-23);
            }
        }];
        if ([_abilityType isEqualToString:TEUI_PORTRAIT_SEGMENTATION]) {
            self.closeBottomView.hidden = YES;
        }

        [self.underView addSubview:self.openBottomView];
        [self.openBottomView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(24);
            make.height.mas_equalTo(42);
            make.top.mas_equalTo(self.beautyCollection.mas_bottom).mas_offset(20);
            if([_abilityType isEqualToString:TEUI_BEAUTY_TEMPLATE]){
                make.left.mas_equalTo(self).mas_offset(23);
            }else{
                make.right.mas_equalTo(self).mas_offset(-23);
            }
        }];

        [self.commonView addSubview:self.templateParamView];
        [self.templateParamView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(24);
            make.height.mas_equalTo(42);
            make.top.mas_equalTo(self.beautyCollection.mas_bottom).mas_offset(20);
            make.right.mas_equalTo(self).mas_offset(-23);
        }];

        if([_abilityType isEqualToString:TEUI_BEAUTY_TEMPLATE]){
            self.templateParamView.hidden = NO;
        }else{
            self.templateParamView.hidden = YES;
        }
        if([_abilityType isEqualToString:TEUI_FACE_DETECTION] ||
           [_abilityType isEqualToString:TEUI_GESTURE_DETECTION] ||
           [_abilityType isEqualToString:TEUI_BEAUTY_TEMPLATE]){
            self.resetView.hidden = YES;
        }else{
            self.resetView.hidden = NO;
        }
        self.underView.hidden = YES;
        self.openBottomView.hidden = YES;

        self.scrollView = [[UIScrollView alloc] init];
        self.scrollView.showsHorizontalScrollIndicator = NO;

        [self addTabButtons:NO];

        [self setupBottomView];
        if(_abilityType.length == 0){
            _commonView.hidden = YES;
            _bottomView.hidden = NO;
        }else{
            _bottomView.hidden = YES;
            _commonView.hidden = NO;
        }
        if([_abilityType isEqualToString:TEUI_FACE_DETECTION] ||
           [_abilityType isEqualToString:TEUI_GESTURE_DETECTION]){
            _capabilitiesSwitch.hidden = NO;
            _capabilitiesStatusLabel.hidden = NO;
        }else{
            _capabilitiesSwitch.hidden = YES;
            _capabilitiesStatusLabel.hidden = YES;
        }
    }else{
        self.backgroundColor = [UIColor clearColor];
        self.commonView = [[UIView alloc]init];
        self.commonView.backgroundColor = [UIColor clearColor];
        self.commonView.userInteractionEnabled = YES;
        [self addSubview:self.commonView];
        [self.commonView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.mas_equalTo(self);
        }];
        
        [self.commonView addSubview:self.blackView];
        [self.blackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self);
            make.right.mas_equalTo(self);
            make.bottom.mas_equalTo(self);
            make.height.mas_equalTo(160);
        }];
        
        [self.blackView addSubview:self.beautyCollection];
        [self.beautyCollection mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self);
            make.right.mas_equalTo(self);
            make.bottom.mas_equalTo(self.mas_safeAreaLayoutGuideBottom);
            make.height.mas_equalTo(beautyCollectionItemHeight);
        }];
        
        [self.commonView addSubview:self.compareButton];
        [self.compareButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self).mas_offset(-10);
            make.width.height.mas_equalTo(25);
            make.bottom.mas_equalTo(self.blackView.mas_top).mas_offset(-5);
        }];

        [self.commonView addSubview:self.teSlider];
        [self.teSlider mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self).mas_offset(10);
            make.right.mas_equalTo(self).mas_offset(_showCompareBtn ? -45:-10);
            make.centerY.mas_equalTo(self.compareButton.mas_centerY);
        }];
        self.teSlider.hidden = YES;
        
        [self.commonView addSubview:self.makeupOrLut];
        [self.makeupOrLut mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(82);
            make.height.mas_equalTo(26);
            make.left.mas_equalTo(self).mas_offset(10);
            make.centerY.mas_equalTo(self.compareButton.mas_centerY);
        }];
        self.makeupOrLut.hidden = YES;

        _hLineView= [[UIView alloc] init];
        _hLineView.backgroundColor = [TEUIConfig shareInstance].panelDividerColor;
        [self.blackView addSubview:_hLineView];
        [_hLineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self.mas_width);
            make.left.mas_equalTo(self.mas_left);
            make.bottom.mas_equalTo(self.beautyCollection.mas_top).mas_offset(-10);
            make.height.mas_equalTo(1);
        }];
        
        self.scrollView = [[UIScrollView alloc] init];
        self.scrollView.showsHorizontalScrollIndicator = NO;
        [self addTabButtons:NO];
        
        self.vLineView= [[UIView alloc] init];
        self.vLineView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
        [self.commonView addSubview:self.vLineView];
        [self.vLineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(1);
            make.right.mas_equalTo(self).mas_offset(-81);
            make.height.mas_equalTo(24);
            make.centerY.mas_equalTo(self.scrollView.mas_centerY);
        }];
        
        [self.commonView addSubview:self.rightResetView];
        [self.rightResetView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(47);
            make.height.mas_equalTo(24);
            make.right.mas_equalTo(self).mas_offset(-17);
            make.centerY.mas_equalTo(self.scrollView.mas_centerY);
        }];
    }
}

-(void)setupBottomView{
    [self addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self);
        make.height.mas_equalTo(200);
        make.bottom.mas_equalTo(self);
    }];
    
    [self.bottomView addSubview:self.originBeautyView];
    [self.originBeautyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(82);
        make.height.mas_equalTo(26);
        make.centerX.mas_equalTo(self.bottomView.mas_centerX);
        make.bottom.mas_equalTo(self.takePhoto.mas_top).mas_offset(-10);
    }];
    
    CGFloat gap = (ScreenWidth - (48 * 4 + 74))/6;
    [self.bottomView addSubview:self.stickerView];
    [self.stickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(48);
        make.height.mas_equalTo(70);
        make.left.mas_equalTo(self).mas_offset(gap);
        make.top.mas_equalTo(self.takePhoto);
        
    }];
    
    [self.bottomView addSubview:self.beautyView];
    [self.beautyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(48);
        make.height.mas_equalTo(70);
        make.left.mas_equalTo(self.stickerView.mas_right).mas_offset(gap);
        make.top.mas_equalTo(self.takePhoto);
    }];
    
    [self.bottomView addSubview:self.makeupView];
    [self.makeupView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(48);
        make.height.mas_equalTo(70);
        make.left.mas_equalTo(self.takePhoto.mas_right).mas_offset(gap);
        make.top.mas_equalTo(self.takePhoto);
    }];
    
    [self.bottomView addSubview:self.lutView];
    [self.lutView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(48);
        make.height.mas_equalTo(70);
        make.left.mas_equalTo(self.makeupView.mas_right).mas_offset(gap);
        make.top.mas_equalTo(self.takePhoto);
    }];
    self.bottomView.hidden = YES;
}

- (TESlider *)teSlider{
    if(!_teSlider){
        _teSlider = [[TESlider alloc]init];
        [_teSlider setTintColor:[TEUIConfig shareInstance].seekBarProgressColor];
        _teSlider.minimumValue = 0;
        _teSlider.maximumValue = 100;
        [_teSlider addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
        UIImage *originalThumbImage = [[TEUIConfig shareInstance] imageNamed:@"slider"];
        CGSize newSize = CGSizeMake(15, 15);
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
        [originalThumbImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        UIImage *resizedThumbImage = UIGraphicsGetImageFromCurrentImageContext();
               UIGraphicsEndImageContext();
        [_teSlider setThumbImage:resizedThumbImage forState:UIControlStateNormal];
    }
    return _teSlider;
}

- (UIView *)blackView{
    if(!_blackView){
        _blackView = [[UIView alloc] init];
        _blackView.backgroundColor = [TEUIConfig shareInstance].panelBackgroundColor;
    }
    return _blackView;
}

- (void)btnLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if(_showOrigin){
            return;
        }
        if ([self.delegate respondsToSelector:@selector(showBeautyChanged:)]) {
            [self.delegate showBeautyChanged:NO];
        }
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        if(_showOrigin){
            return;
        }
        if ([self.delegate respondsToSelector:@selector(showBeautyChanged:)]) {
            [self.delegate showBeautyChanged:YES];
        }
    }
}

- (UIButton *)compareButton {
    if (!_compareButton) {
        _compareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_compareButton setImage:[[TEUIConfig shareInstance] imageNamed:@"compare.png"] forState:UIControlStateNormal];
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(btnLongPress:)];
        longPressRecognizer.minimumPressDuration = 0; // 设置最短长按时间为 0，使其立即触发
        [_compareButton addGestureRecognizer:longPressRecognizer];
    }
    return _compareButton;
}

- (UICollectionView *)beautyCollection{
    if(!_beautyCollection){
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        layout.itemSize =CGSizeMake(beautyCollectionItemWidth, beautyCollectionItemHeight);
        _beautyCollection = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _beautyCollection.backgroundColor = [UIColor clearColor];
        _beautyCollection.dataSource = self;
        _beautyCollection.delegate = self;
        _beautyCollection.scrollEnabled = YES;
        _beautyCollection.showsHorizontalScrollIndicator = NO;
        [_beautyCollection registerClass:[TECollectionViewCell class] forCellWithReuseIdentifier:@"TECollectionViewCell"];
    }
    return _beautyCollection;
}

- (TESwitch *)capabilitiesSwitch{
    if(!_capabilitiesSwitch){
        _capabilitiesSwitch = [[TESwitch alloc] init];
        [_capabilitiesSwitch setOnTintColor: [UIColor whiteColor]];
        _capabilitiesSwitch.tintColor = [UIColor whiteColor];
        _capabilitiesSwitch.thumbTintColor = [UIColor colorWithRed:0 green:0x6e/255.0 blue:1 alpha:1];

        TESwitchStyle style = TESwitchStyleBorder;
        _capabilitiesSwitch.style = style;
        _capabilitiesSwitch.userInteractionEnabled = YES;
        [_capabilitiesSwitch setOn:YES];
        [_capabilitiesSwitch addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventValueChanged];
    }
    return _capabilitiesSwitch;
}

- (UILabel *)capabilitiesStatusLabel{
    if (!_capabilitiesStatusLabel) {
        _capabilitiesStatusLabel = [[UILabel alloc] init];
        _capabilitiesStatusLabel.text = [[TEUIConfig shareInstance] localizedString:@"pannel_btn_close"];
        _capabilitiesStatusLabel.textColor = [UIColor whiteColor];
        _capabilitiesStatusLabel.font = [UIFont systemFontOfSize:14];
        _capabilitiesStatusLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _capabilitiesStatusLabel;
}

- (UIView *)loadingCover {
    if (!_loadingCover) {
        _loadingCover = [UIView new];
        _loadingCover.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
    }
    return _loadingCover;
}

- (UIActivityIndicatorView *) loadingView {
    if (!_loadingView) {
        _loadingView = [UIActivityIndicatorView new];
        _loadingView.color = [UIColor greenColor];
    }
    return  _loadingView;
}
- (UILabel *)processLabel {
    if (!_processLabel) {
        _processLabel = [UILabel new];
        _processLabel.textAlignment = NSTextAlignmentCenter;
        _processLabel.textColor = [UIColor whiteColor];
    }
    return  _processLabel;
}

- (BOOL)isTEDemo{
    if(self.abilityType == nil && self.comboType == nil){
        return NO;
    }
    return YES;
}


- (void)addTabButtons:(BOOL)reset{
    CGFloat btnHeight = 24;
    CGFloat btnWidth = 0;
    CGFloat btnGap = 20;
    CGFloat x = 20;
    CGFloat scrollViewTopMargin = 50;
    if(![self isTEDemo]){
        scrollViewTopMargin = 40;
    }
    _titleBtns = [[NSMutableArray alloc] init];
    
    if (_currentUIPropertyList.count == 0) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.backgroundColor = [UIColor clearColor];
        if ([TEUtils isCurrentLanguageHans]) {
            [btn setTitle:_currentUIProperty.displayName forState:UIControlStateNormal];
        }else{
            [btn setTitle:_currentUIProperty.displayNameEn forState:UIControlStateNormal];
        }
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont boldSystemFontOfSize:16]];
        if([TEUtils isCurrentLanguageHans]){
            btnWidth = [TEUtils textWidthFromTitle:_currentUIProperty.displayName font:btn.titleLabel.font];
        }else{
            btnWidth = [TEUtils textWidthFromTitle:_currentUIProperty.displayNameEn font:btn.titleLabel.font];
        }
        btn.frame = CGRectMake(0, 0, btnWidth, btnHeight);
        btn.tag = 5000;
        [_titleBtns addObject:btn];
        [self.scrollView addSubview:btn];
        [self.commonView addSubview:self.scrollView];
        if(reset){
            [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(btnWidth);
                make.height.mas_equalTo(24);
                make.centerX.mas_equalTo(self);
                make.bottom.mas_equalTo(self.hLineView.mas_top).mas_offset(-5);
            }];
        }else{
            [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(btnWidth);
                make.height.mas_equalTo(24);
                make.centerX.mas_equalTo(self);
                make.bottom.mas_equalTo(self.hLineView.mas_top).mas_offset(-5);
            }];
        }
        self.scrollView.scrollEnabled = NO;
        return;
    }
    
    for (int i = 0; i < _currentUIPropertyList.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.backgroundColor = [UIColor clearColor];
        if([TEUtils isCurrentLanguageHans]){
            [btn setTitle:_currentUIPropertyList[i].displayName forState:UIControlStateNormal];
            [btn.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:16]];
        }else{
            [btn setTitle:_currentUIPropertyList[i].displayNameEn forState:UIControlStateNormal];
            [btn.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:16]];
        }
        if (i == _beautyType) {
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btn.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:16]];
        }else{
            [btn setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.7] forState:UIControlStateNormal];
            [btn.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:16]];
        }
        btnWidth = [TEUtils textWidthFromTitle:btn.titleLabel.text font:btn.titleLabel.font] + 5;
        btn.titleLabel.font = [UIFont systemFontOfSize:16];
        btn.frame = CGRectMake(x, 0, btnWidth, btnHeight);
        btn.tag = 5000 + i;
        [btn addTarget:self action:@selector(onSetAction:) forControlEvents:UIControlEventTouchUpInside];
        x = x + btnWidth + btnGap;
        [_titleBtns addObject:btn];
        [self.scrollView addSubview:btn];
    }
    if (_currentUIPropertyList.count > 3) {
        if (reset) {
            [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.mas_equalTo(self);
                make.height.mas_equalTo(24);
                make.bottom.mas_equalTo(self.hLineView.mas_top).mas_offset(-5);
                if([self isTEDemo]){
                    make.width.mas_equalTo(self);
                }else{
                    make.width.mas_equalTo(self.frame.size.width - 81);
                    make.right.mas_equalTo(self).mas_equalTo(-81);
                }
            }];
        }else{
            [self.commonView addSubview:self.scrollView];
            [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.mas_equalTo(self);
                make.height.mas_equalTo(24);
                make.bottom.mas_equalTo(self.hLineView.mas_top).mas_offset(-5);
                if([self isTEDemo]){
                    make.width.mas_equalTo(self);
                }else{
                    make.width.mas_equalTo(self.frame.size.width - 81);
                    make.right.mas_equalTo(self).mas_equalTo(-81);
                }
            }];
        }
        self.scrollView.contentSize = CGSizeMake(x, 24);
        self.scrollView.scrollEnabled = YES;
    }else{
        if (reset) {
            [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
                if(x > ScreenWidth){
                    make.left.mas_equalTo(self);
                }
                make.height.mas_equalTo(24);
                make.centerX.mas_equalTo(self);
                make.bottom.mas_equalTo(self.hLineView.mas_top).mas_offset(-5);
                if([self isTEDemo]){
                    make.width.mas_equalTo(x);
                }else{
                    make.width.mas_equalTo(self.frame.size.width - 81);
                    make.right.mas_equalTo(self).mas_equalTo(-81);
                }
            }];
        }else{
            [self.commonView addSubview:self.scrollView];
            [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
                if(x > ScreenWidth){
                    make.left.mas_equalTo(self);
                }
                make.height.mas_equalTo(24);
                make.centerX.mas_equalTo(self);
                make.bottom.mas_equalTo(self.hLineView.mas_top).mas_offset(-5);
                if([self isTEDemo]){
                    make.width.mas_equalTo(x);
                }else{
                    make.width.mas_equalTo(self.frame.size.width - 81);
                    make.right.mas_equalTo(self).mas_equalTo(-81);
                }
            }];
        }
        self.scrollView.contentSize = CGSizeMake(x, 24);
        if([TEUtils isCurrentLanguageHans]){
            self.scrollView.scrollEnabled = NO;
        }else{
            self.scrollView.scrollEnabled = YES;
        }
    }
}

- (void)switchChange:(UISwitch*)sw {
    if (sw.on) {
        self.capabilitiesStatusLabel.text = [[TEUIConfig shareInstance] localizedString:@"pannel_btn_close"];
    }else{
        self.capabilitiesStatusLabel.text = [[TEUIConfig shareInstance] localizedString:@"pannel_btn_open"];
    }
    if([_currentUIPropertyList[_beautyType].abilityType isEqualToString: TEUI_FACE_DETECTION]){
        self.faceSwitchStatus = sw.on;
        if([self.delegate respondsToSelector:@selector(faceCapabilityStatusChanged:)]){
            [self.delegate faceCapabilityStatusChanged:self.faceSwitchStatus];
        }
    }else if([_currentUIPropertyList[_beautyType].abilityType isEqualToString: TEUI_GESTURE_DETECTION]){
        self.gestureSwitchStatus = sw.on;
        if([self.delegate respondsToSelector:@selector(gestureCapabilityStatusChanged:)]){
            [self.delegate gestureCapabilityStatusChanged:self.gestureSwitchStatus];
        }
    }
}

- (void)btnTouchDownClick:(UIButton *)sender
{
    if(_showOrigin){
        return;
    }
    if ([self.delegate respondsToSelector:@selector(showBeautyChanged:)]) {
        [self.delegate showBeautyChanged:NO];
    }
}

- (void)btnTouchUpClick:(UIButton *)sender
{
    if(_showOrigin){
        return;
    }
    if ([self.delegate respondsToSelector:@selector(showBeautyChanged:)]) {
        [self.delegate showBeautyChanged:YES];
    }
}

-(UIImageView *)takePhoto{
    if(!_takePhoto){
        _takePhoto = [[UIImageView alloc] init];
        [_takePhoto setImage:[[TEUIConfig shareInstance] imageNamed:@"take_photo_icon"]];
        _takePhoto.userInteractionEnabled = YES;
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(takePhoto:)];
        [_takePhoto addGestureRecognizer:tapGesture];
    }
    return  _takePhoto;
}

- (void)setSubMenu:(BOOL)hide{
    if (!self.beautyTitleLabel) {
        self.beautyTitleLabel = [[UILabel alloc] init];
        [self.beautyTitleLabel setTextColor:[UIColor whiteColor]];
        self.beautyTitleLabel.font = [UIFont systemFontOfSize:16];
        [self.blackView addSubview:self.beautyTitleLabel];
    }
    CGFloat width;
    if ([TEUtils isCurrentLanguageHans]) {
        self.beautyTitleLabel.text = _currentUIProperty.displayName;
        width = [TEUtils textWidthFromTitle:_currentUIProperty.displayName font:self.beautyTitleLabel.font];
    }else{
        self.beautyTitleLabel.text = _currentUIProperty.displayNameEn;
        width = [TEUtils textWidthFromTitle:_currentUIProperty.displayNameEn font:self.beautyTitleLabel.font];
    }
    self.beautyTitleLabel.frame = CGRectMake((ScreenWidth - width)/2, 5, width, 24);
    if (!_backButton) {
        _backButton=[[UIButton alloc] initWithFrame:CGRectMake(0, 2, 30, 30)];
        [_backButton setImage:[[TEUIConfig shareInstance] imageNamed:@"backto.png"] forState:UIControlStateNormal];
        [_backButton setBackgroundColor:[UIColor clearColor]];
        _backButton.alpha = 0.7;
        
        [self.blackView addSubview:_backButton];
        [_backButton addTarget:self action:@selector(clickBack) forControlEvents:UIControlEventTouchUpInside];
    }
    self.scrollView.hidden = hide;
    self.backButton.hidden = !hide;
    self.beautyTitleLabel.hidden = !hide;
}

- (void)onSetAction:(UIButton *)sender{
    _teSlider.hidden = YES;
    _makeupOrLut.hidden = YES;
    int number = (int)sender.tag - 5000;
    _beautyType = number;
    for (int i = 0; i < self.titleBtns.count; i++) {
        [_titleBtns[i] setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.7] forState:UIControlStateNormal];
    }
    [_titleBtns[number] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _currentUIProperty = _currentUIPropertyList[_beautyType];
    [self.beautyCollection reloadData];
    if([_currentUIPropertyList[_beautyType].abilityType isEqualToString:TEUI_FACE_DETECTION]){
        [self.capabilitiesSwitch setOn:self.faceSwitchStatus];
    }else if ([_currentUIPropertyList[_beautyType].abilityType isEqualToString:TEUI_GESTURE_DETECTION]){
        [self.capabilitiesSwitch setOn:self.gestureSwitchStatus];
    }
}

-(void)clickBack{
    if([_currentUIPropertyList[_beautyType].propertyList containsObject:_currentUIProperty]){
        for (TEUIProperty *property in _currentUIProperty.propertyList) {
            if(property.uiState == TEUIState_CHECKED_AND_IN_USE){
                int index = (int)[_currentUIPropertyList[_beautyType].propertyList indexOfObject:_currentUIProperty];
                for (int i = 0; i < _currentUIPropertyList[_beautyType].propertyList.count; i++) {
                    if(_currentUIPropertyList[_beautyType].propertyList[i].uiState == TEUIState_CHECKED_AND_IN_USE){
                        if(_currentUIPropertyList[_beautyType].propertyList[i].sdkParam.effectValue == 0){
                            _currentUIPropertyList[_beautyType].propertyList[i].uiState = TEUIState_INIT;
                        }else{
                            _currentUIPropertyList[_beautyType].propertyList[i].uiState = TEUIState_IN_USE;
                        }
                    }
                }
                _currentUIPropertyList[_beautyType].propertyList[index].uiState = TEUIState_CHECKED_AND_IN_USE;
                break;
            }else if(property.uiState == TEUIState_IN_USE){
                if(_currentUIProperty.uiState == TEUIState_INIT){
                    _currentUIProperty.uiState = TEUIState_IN_USE;
                }
            }
        }
        _currentUIProperty = _currentUIPropertyList[_beautyType];
        [self setSubMenu:NO];
    }else{
        _currentUIProperty = [self getParentProperty:_currentUIPropertyList[_beautyType].propertyList property:_currentUIProperty];
        [self setSubMenu:YES];
    }
    self.teSlider.hidden = YES;
    [self.beautyCollection reloadData];
    for (TEUIProperty *property in _currentUIProperty.propertyList) {
        if (property.uiState == TEUIState_CHECKED_AND_IN_USE) {
            int index = (int)[_currentUIPropertyList[_beautyType].propertyList indexOfObject:property];
            [self.beautyCollection scrollToItemAtIndexPath:
            [NSIndexPath indexPathForItem:index inSection:0]
            atScrollPosition:UICollectionViewScrollPositionLeft
            animated:NO];
            break;
        }
    }
}

- (void)takePhoto:(UITapGestureRecognizer *)gesture{
    if([self.delegate respondsToSelector:@selector(takePhotoClick)]){
        [self.delegate takePhotoClick];
    }
}

-(TEUIProperty *)getParentProperty:(NSMutableArray<TEUIProperty *>*)teUIPropertyList property:(TEUIProperty *)property{
    for (int i = 0; i < teUIPropertyList.count; i++) {
        if([teUIPropertyList[i].propertyList containsObject:property]){
            for (TEUIProperty *teuiproperty in property.propertyList) {
                if(teuiproperty.uiState == TEUIState_CHECKED_AND_IN_USE){
                    int index = (int)[teUIPropertyList[i].propertyList indexOfObject:property];
                    for (TEUIProperty *uiProperty in teUIPropertyList[i].propertyList) {
                        if(uiProperty.uiState == TEUIState_CHECKED_AND_IN_USE){
                            if(uiProperty.sdkParam.effectValue == TEUIState_INIT){
                                uiProperty.uiState = TEUIState_INIT;
                            }else{
                                uiProperty.uiState = TEUIState_IN_USE;
                            }
                        }
                    }
                    property.uiState = TEUIState_CHECKED_AND_IN_USE;
                }
            }
            return teUIPropertyList[i];
        }
        continue;
    }
    return nil;
}

- (void)valueChange:(id)sender {
    UISlider * slider =(UISlider*)sender;
    if(_currentUIProperty.teCategory == TECategory_MAKEUP && _makeupType == 1){
        _currentUIProperty.propertyList[_selectedIndex].sdkParam.extraInfo.makeupLutStrength = [NSString stringWithFormat:@"%f",slider.value];
    }else{
        if(self.templateParam){
            if(_currentTemplateProperty.paramList == nil){
                _currentTemplateProperty.paramList = [NSMutableArray array];
            }else{
                for (Param *param in _currentTemplateProperty.paramList) {
                    if([param.effectName isEqualToString:_currentUIProperty.propertyList[_selectedIndex].sdkParam.effectName]){
                        [_currentTemplateProperty.paramList removeObject:param];
                        break;
                    }
                }
            }
            Param *param = [[Param alloc] init];
            param.effectName = _currentUIProperty.propertyList[_selectedIndex].sdkParam.effectName;
            param.effectValue = [NSString stringWithFormat:@"%f",slider.value];
            param.resourcePath = _currentUIProperty.propertyList[_selectedIndex].sdkParam.resourcePath;
            [_currentTemplateProperty.paramList addObject:param];
        }
        _currentUIProperty.propertyList[_selectedIndex].sdkParam.effectValue = slider.value;
    }
    [self updateBeautyEffect:_currentUIProperty.propertyList[_selectedIndex]];
}

-(UIView *)resetView{
    if(!_resetView){
        _resetView = [self getBottomView:[[TEUIConfig shareInstance] localizedString:@"revert_btn_txt"] imageName:@"reset"];
        _resetView.userInteractionEnabled = YES;
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetClick)];
        [_resetView addGestureRecognizer:tapGesture];
    }
    return _resetView;
}

-(UIView *)templateParamView{
    if(!_templateParamView){
        _templateParamView = [self getBottomView:[[TEUIConfig shareInstance] localizedString:@"param"] imageName:@"template_param_icon"];
        _templateParamView.userInteractionEnabled = YES;
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(templateParamClick)];
        [_templateParamView addGestureRecognizer:tapGesture];
    }
    return _templateParamView;
}

-(UIView *)closeBottomView{
    if(!_closeBottomView){
        _closeBottomView = [self getBottomView:[[TEUIConfig shareInstance] localizedString:@"pannel_close_btn_txt"] imageName:@"closeBottom"];
        _closeBottomView.userInteractionEnabled = YES;
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeBottomClick)];
        [_closeBottomView addGestureRecognizer:tapGesture];
    }
    return _closeBottomView;
}

-(UIView *)openBottomView{
    if(!_openBottomView){
        _openBottomView = [self getBottomView:[[TEUIConfig shareInstance] localizedString:@"pannel_expand_btn_txt"] imageName:@"openBottom"];
        _openBottomView.userInteractionEnabled = YES;
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openBottomClick)];
        [_openBottomView addGestureRecognizer:tapGesture];
    }
    return _openBottomView;
}

-(UIView *)backView{
    if(!_backView){
        _backView = [self getBottomView:[[TEUIConfig shareInstance] localizedString:@"back"] imageName:@"closeBottom"];
        _backView.userInteractionEnabled = YES;
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backViewClick)];
        [_backView addGestureRecognizer:tapGesture];
    }
    return _backView;
}

-(UIView *)makeupOrLut{
    if(!_makeupOrLut){
        self.makeupType = 0;
        __weak __typeof(self)weakSelf = self;
        _makeupOrLut = [self singleChoiceView:[[TEUIConfig shareInstance] localizedString:@"panel_makeup"] rightText:[[TEUIConfig shareInstance] localizedString:@"panel_lut"] clickLeft:^{
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.makeupType = 0;
            strongSelf.teSlider.value = strongSelf.currentUIProperty.propertyList[strongSelf.selectedIndex].sdkParam.effectValue;
        } rightClick:^{
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.makeupType = 1;
            strongSelf.teSlider.value = [strongSelf.currentUIProperty.propertyList[strongSelf.selectedIndex].sdkParam.extraInfo.makeupLutStrength intValue];
        } leftTag:120 select:self.makeupType];
    }
    return _makeupOrLut;
}

-(UIView *)originBeautyView{
    if(!_originBeautyView){
        __weak __typeof(self)weakSelf = self;
        _originBeautyView = [self singleChoiceView:[[TEUIConfig shareInstance] localizedString:@"original"] rightText:[[TEUIConfig shareInstance] localizedString:@"effect"] clickLeft:^{
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.showOrigin = YES;
            if ([strongSelf.delegate respondsToSelector:@selector(showBeautyChanged:)]) {
                [strongSelf.delegate showBeautyChanged:NO];
            }
        } rightClick:^{
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.showOrigin = NO;
            if ([strongSelf.delegate respondsToSelector:@selector(showBeautyChanged:)]) {
                [strongSelf.delegate showBeautyChanged:YES];
            }
        } leftTag:100 select:1];
    }
    return _originBeautyView;
}

-(UIView *)bottomView{
    if(!_bottomView){
        _bottomView= [[UIView alloc] init];
        _bottomView.backgroundColor = [UIColor clearColor];
    }
    return _bottomView;
}

-(TEClassificationView *)stickerView{
    if(!_stickerView){
        _stickerView = [[TEClassificationView alloc] initWithTitle:NSLocalizedString(@"panel_sticker",nil) imageName:@"bottom.sticker.png"];
        _stickerView.userInteractionEnabled = YES;
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(stickerClick:)];
        [_stickerView addGestureRecognizer:tapGesture];
        [_stickerView setEnable:self.comboType.length == 0||[_tePanelDataProvider.motionOfCombos containsObject:self.comboType]];
    }
    return _stickerView;
}

-(TEClassificationView *)beautyView{
    if(!_beautyView){
        _beautyView = [[TEClassificationView alloc] initWithTitle:NSLocalizedString(@"beauty",nil) imageName:@"bottom.beauty.png"];
        _beautyView.userInteractionEnabled = YES;
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(beautyClick:)];
        [_beautyView addGestureRecognizer:tapGesture];
    }
    return _beautyView;
}

-(TEClassificationView *)makeupView{
    if(!_makeupView){
        _makeupView = [[TEClassificationView alloc] initWithTitle:NSLocalizedString(@"panel_makeup",nil) imageName:@"bottom.makeup.png"];
        _makeupView.userInteractionEnabled = YES;
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(makeupClick:)];
        [_makeupView addGestureRecognizer:tapGesture];
        [_makeupView setEnable:self.comboType.length == 0||[_tePanelDataProvider.makeupOfCombos containsObject:self.comboType]];
    }
    return _makeupView;
}

-(TEClassificationView *)lutView{
    if(!_lutView){
        _lutView = [[TEClassificationView alloc] initWithTitle:NSLocalizedString(@"panel_lut",nil) imageName:@"bottom.lut.png"];
        _lutView.userInteractionEnabled = YES;
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(lutClick:)];
        [_lutView addGestureRecognizer:tapGesture];
    }
    return _lutView;
}

-(UIImageView *)photoView{
    if(!_photoView){
        UIImageView *image = [[UIImageView alloc] init];
        [image setImage:[[TEUIConfig shareInstance] imageNamed:@"bottom.photo.png"]];
        _photoView = [[UIImageView alloc] init];
        [_photoView setImage:[[[TEUIConfig shareInstance] imageNamed:@"bottom.round.png"]
                    imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _photoView.tintColor = [UIColor colorWithRed:0 green:0x6e/255.0 blue:1 alpha:1];
        [_photoView addSubview:image];
        [image mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(35);
            make.height.mas_equalTo(30);
            make.centerX.mas_equalTo(_photoView);
            make.centerY.mas_equalTo(_photoView);
        }];
        _photoView.userInteractionEnabled = YES;
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(takePhoto:)];
        [_photoView addGestureRecognizer:tapGesture];
        
    }
    return _photoView;
}

-(UIView *)rightResetView{
    if(!_rightResetView){
        _rightResetView =[self rightView];
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetClick)];
        [_rightResetView addGestureRecognizer:tapGesture];
    }
    return _rightResetView;
}

-(UIView *)rightView{
    UIView *rightView = [[UIView alloc] init];
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView setImage:[[TEUIConfig shareInstance] imageNamed:@"reset"]];
    [rightView addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(16);
        make.left.mas_equalTo(rightView);
        make.centerY.mas_equalTo(rightView.mas_centerY);
    }];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = [[TEUIConfig shareInstance] localizedString:@"revert_btn_txt"];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    [rightView addSubview:label];
    CGFloat width = [TEUtils textWidthFromTitle:label.text font:label.font];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(width);
        make.height.mas_equalTo(18);
        make.left.mas_equalTo(imageView.mas_right);
        make.centerY.mas_equalTo(imageView.mas_centerY);
    }];
    
    return rightView;
}


-(UIView *)getBottomView:(NSString *)text imageName:(NSString *)imageName{
    UIView *resetView = [[UIView alloc] init];
    CGFloat width = 24;
    if(![TEUtils isCurrentLanguageHans]){
        width = [TEUtils textWidthFromTitle:text font:[UIFont systemFontOfSize:12]];
    }
    resetView.frame = CGRectMake(0, 0, width, 42);
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView setImage:[[TEUIConfig shareInstance] imageNamed:imageName]];
    [resetView addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(24);
        make.top.mas_equalTo(resetView);
        make.centerX.mas_equalTo(resetView.mas_centerX);
    }];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    [resetView addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(width);
        make.height.mas_equalTo(18);
        make.top.mas_equalTo(imageView.mas_bottom);
        make.centerX.mas_equalTo(resetView.mas_centerX);
    }];
    return resetView;
}

-(UIView *)singleChoiceView:(NSString *)leftText
                  rightText:(NSString *)rightText
                  clickLeft:(void(^)(void))clickLeft
                 rightClick:(void(^)(void))rightClick
                    leftTag:(int)leftTag
                     select:(int)select{
    UIView *view = [[UIView alloc] init];
    view.frame = CGRectMake(0, 0, 82, 26);
    view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.4];
    view.layer.cornerRadius = 13;
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setTitle:leftText forState:UIControlStateNormal];
    leftBtn.layer.cornerRadius = 13;
    leftBtn.tag = leftTag;
    [leftBtn setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4] forState:UIControlStateNormal];
    leftBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:10];
    [leftBtn addTarget:self action:@selector(leftButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightBtn setTitle:rightText forState:UIControlStateNormal];
    rightBtn.layer.cornerRadius = 13;
    rightBtn.tag = leftTag + 1;
    [rightBtn setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4] forState:UIControlStateNormal];
    rightBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:10];
    [rightBtn addTarget:self action:@selector(rightButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    objc_setAssociatedObject(leftBtn, "clickLeft", clickLeft, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(rightBtn, "rightClick", rightClick, OBJC_ASSOCIATION_COPY_NONATOMIC);

    if(select == 0){
        [leftBtn setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1] forState:UIControlStateNormal];
        leftBtn.backgroundColor = [UIColor whiteColor];
        [rightBtn setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4] forState:UIControlStateNormal];
        rightBtn.backgroundColor = [UIColor clearColor];
    }else{
        [rightBtn setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1] forState:UIControlStateNormal];
        rightBtn.backgroundColor = [UIColor whiteColor];
        [leftBtn setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4] forState:UIControlStateNormal];
        leftBtn.backgroundColor = [UIColor clearColor];
    }
    
    [view addSubview:leftBtn];
    [leftBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(41);
        make.height.mas_equalTo(26);
        make.top.mas_equalTo(view);
        make.left.mas_equalTo(view);
    }];
    [view addSubview:rightBtn];
    [rightBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(41);
        make.height.mas_equalTo(26);
        make.top.mas_equalTo(view);
        make.right.mas_equalTo(view);
    }];
    
    return view;
}

- (void)beautyClick:(UITapGestureRecognizer *)gesture{
    if  (![_abilityType isEqualToString:TEUI_BEAUTY] &&
       ![_abilityType isEqualToString:TEUI_BEAUTY_IMAGE] &&
       ![_abilityType isEqualToString:TEUI_BEAUTY_SHAPE] &&
         ![_abilityType isEqualToString:TEUI_BEAUTY_BODY]){
        for (UIButton *btn in self.titleBtns) {
            [btn removeFromSuperview];
        }
        _abilityType = TEUI_BEAUTY;
        [self initData];
        [self.titleBtns removeAllObjects];
        [self addTabButtons:YES];
        [self setSubMenu:NO];
        [self.beautyCollection reloadData];
    }
    self.bottomView.hidden = YES;
    self.commonView.hidden = NO;
}

- (void)stickerClick:(UITapGestureRecognizer *)gesture{
    if(!self.stickerView.enable){
        [TEToast showWithText:NSLocalizedString(@"combo_not_support", nil) inView:[self getControllerFromView:self].view duration:2];
        return;
    }
    if(![_abilityType isEqualToString:TEUI_MOTION_2D] &&
       ![_abilityType isEqualToString:TEUI_MOTION_3D] &&
       ![_abilityType isEqualToString:TEUI_MOTION_GESTURE] &&
       ![_abilityType isEqualToString:TEUI_MOTION_CAMERA_MOVE] &&
       ![_abilityType isEqualToString:TEUI_SEGMENTATION]){
        for (UIButton *btn in self.titleBtns) {
            [btn removeFromSuperview];
        }
        _abilityType = TEUI_MOTION_2D;
        [self initData];
        [self.titleBtns removeAllObjects];
        [self addTabButtons:YES];
        [self setSubMenu:NO];
        [self.beautyCollection reloadData];
    }
    self.bottomView.hidden = YES;
    self.commonView.hidden = NO;
}

- (void)makeupClick:(UITapGestureRecognizer *)gesture{
    if(!self.makeupView.enable){
        [TEToast showWithText:NSLocalizedString(@"combo_not_support", nil) inView:[self getControllerFromView:self].view duration:2];
        return;
    }
    if(![_abilityType isEqualToString:TEUI_BEAUTY_MAKEUP] &&
       ![_abilityType isEqualToString:TEUI_MAKEUP]){
        for (UIButton *btn in self.titleBtns) {
            [btn removeFromSuperview];
        }
        _abilityType = TEUI_BEAUTY_MAKEUP;
        [self initData];
        [self.titleBtns removeAllObjects];
        [self addTabButtons:YES];
        [self setSubMenu:NO];
        [self.beautyCollection reloadData];
    }
    self.bottomView.hidden = YES;
    self.commonView.hidden = NO;
}

- (void)lutClick:(UITapGestureRecognizer *)gesture{
    if(![_abilityType isEqualToString:TEUI_LUT]){
        for (UIButton *btn in self.titleBtns) {
            [btn removeFromSuperview];
        }
        _abilityType = TEUI_LUT;
        [self initData];
        _currentUIPropertyList = nil;
        [self.titleBtns removeAllObjects];
        [self addTabButtons:YES];
        [self setSubMenu:NO];
        [self.beautyCollection reloadData];
    }
    self.bottomView.hidden = YES;
    self.commonView.hidden = NO;
}

-(void)leftButtonAction:(UIButton *)sender {
    // 获取关联的回调
    void (^clickLeft)(void) = objc_getAssociatedObject(sender, "clickLeft");

    // 修改 leftBtn 的背景颜色和文本颜色
    [sender setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1] forState:UIControlStateNormal];
    sender.backgroundColor = [UIColor whiteColor];

    // 获取 rightBtn
    UIButton *rightBtn = [sender.superview viewWithTag:sender.tag + 1];

    // 修改 rightBtn 的背景颜色和文本颜色
    [rightBtn setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4] forState:UIControlStateNormal];
    rightBtn.backgroundColor = [UIColor clearColor];

    // 调用回调
    if (clickLeft) {
        clickLeft();
    }
}

- (void)rightButtonAction:(UIButton *)sender {
    // 获取关联的回调
    void (^rightClick)(void) = objc_getAssociatedObject(sender, "rightClick");
    
    // 修改 rightBtn 的背景颜色和文本颜色
    [sender setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1] forState:UIControlStateNormal];
    sender.backgroundColor = [UIColor whiteColor];
    
    // 获取 leftBtn
    UIButton *leftBtn = [sender.superview viewWithTag:sender.tag -1];
    
    // 修改 leftBtn 的背景颜色和文本颜色
    [leftBtn setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4] forState:UIControlStateNormal];
    leftBtn.backgroundColor = [UIColor clearColor];
    
    // 调用回调
    if (rightClick) {
        rightClick();
    }
}



-(UIView *)singleChoiceItemView:(NSString *)name image:(UIImage *)image color:(UIColor *)color{
    UIView *view = [[UIView alloc] init];
    view.frame = CGRectMake(0, 0, 44, 60);
    view.layer.cornerRadius = 22;
    view.backgroundColor = [UIColor whiteColor];
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView setTintColor:color];
    [imageView setImage:image];
    [view addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(26);
        make.top.mas_equalTo(view).offset(5);
        make.centerX.mas_equalTo(view.mas_centerX);
    }];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = name;
    label.font = [UIFont fontWithName:@"PingFangSC-Medium" size:12];
    label.textColor = color;
    label.textAlignment = NSTextAlignmentCenter;
    
    [view addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(44);
        make.height.mas_equalTo(18);
        make.top.mas_equalTo(imageView.mas_bottom).mas_offset(2);
    }];
    return view;
}

- (void)templateParamClick{
    for (TEUIProperty *property in _currentUIPropertyList[_templateType].propertyList) {
        if(property.uiState == TEUIState_CHECKED_AND_IN_USE){
            _currentTemplateProperty = property;
            break;
        }
    }
    _templateType = _beautyType;
    _beautyType = 0;
    _templateParam = YES;
    _currentUIPropertyList = [_tePanelDataProvider getAbilitiesTemplateBeautyData];
    _currentUIProperty = _currentUIPropertyList[_beautyType];
    for (UIButton *btn in self.titleBtns) {
        [btn removeFromSuperview];
    }
    [self.titleBtns removeAllObjects];
    [self addTabButtons:NO];
    [self.beautyCollection reloadData];
    self.templateParamView.hidden = YES;
    self.closeBottomView.hidden = YES;
    self.backView.hidden = NO;
    self.resetView.hidden = NO;
    self.makeupOrLut.hidden = YES;
    [self.teSlider mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self).mas_offset(_showCompareBtn ? -45 : -10);
        make.left.mas_equalTo(self).mas_offset(10);
        make.centerY.mas_equalTo(self.compareButton.mas_centerY);
    }];
}

- (void)resetClick{
    // 初始化UIAlertController
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    if (@available(iOS 13.0, *)) {
        alertController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    //修改title字体及颜色
    NSMutableAttributedString *titleStr = [[NSMutableAttributedString alloc] initWithString:[[TEUIConfig shareInstance] localizedString:@"revert_tip_title"]];
    [titleStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.9/1.0] range:NSMakeRange(0, titleStr.length)];
    [titleStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:20] range:NSMakeRange(0, titleStr.length)];
    [alertController setValue:titleStr forKey:@"attributedTitle"];
    // 修改message字体及颜色
    NSMutableAttributedString *messageStr = [[NSMutableAttributedString alloc] initWithString:[[TEUIConfig shareInstance] localizedString:@"revert_tip_msg"]];
    [messageStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.3/1.0] range:NSMakeRange(0, messageStr.length)];
    [messageStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:18] range:NSMakeRange(0, messageStr.length)];
    [alertController setValue:messageStr forKey:@"attributedMessage"];
    // 添加UIAlertAction
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:[[TEUIConfig shareInstance] localizedString:@"revert_tip_dialog_right_btn"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if(self.templateParam){
            [self.tePanelDataProvider clearData];
            [self templateParamClick];
            [self setSubMenu:NO];
        }else{
            [self.tePanelDataProvider clearData];
            for (UIButton *btn in self.titleBtns) {
                [btn removeFromSuperview];
            }
            [self initData];
            [self.titleBtns removeAllObjects];
            [self addTabButtons:YES];
            [self setSubMenu:NO];
            [self.beautyCollection reloadData];
            [self setBeauty:EFFECT_MOTION effectValue:0 resourcePath:nil extraInfo:nil save:YES];
            [self setBeauty:EFFECT_SEGMENTATION effectValue:0 resourcePath:nil extraInfo:nil save:YES];
            [self setBeauty:EFFECT_LUT effectValue:0 resourcePath:nil extraInfo:nil save:YES];
            [self setBeauty:EFFECT_MAKEUP effectValue:0 resourcePath:nil extraInfo:nil save:YES];
        }
        self.makeupOrLut.hidden = YES;
        self.teSlider.hidden = YES;
        [self clearBeauty:[self.teBeautyKit getInUseSDKParamList]];
        [self setDefaultBeauty];
    }];
    // KVC修改字体颜色
    [sureAction setValue:[UIColor colorWithRed:0 green:0x6e/255.0 blue:1 alpha:1] forKey:@"_titleTextColor"];
    [alertController addAction:sureAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[[TEUIConfig shareInstance] localizedString:@"revert_tip_dialog_left_btn"] style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"取消");
    }];
    [cancelAction setValue:[UIColor blackColor] forKey:@"_titleTextColor"];
    [alertController addAction:cancelAction];
    [[self getControllerFromView:self] presentViewController:alertController animated:YES completion:nil];
}

- (void)backViewClick{
    _beautyType = self.templateParam ? _templateType : 0;
    _templateParam = NO;
    self.backView.hidden = YES;
    self.closeBottomView.hidden = NO;
    self.templateParamView.hidden = NO;
    self.resetView.hidden = YES;
    [self initData];
    self.teSlider.hidden = YES;
    [self.beautyCollection reloadData];
    for (UIButton *btn in self.titleBtns) {
        [btn removeFromSuperview];
    }
    [self.titleBtns removeAllObjects];
    [self addTabButtons:YES];
    [self setSubMenu:NO];
}

- (void)openBottomClick{
    if([_abilityType isEqualToString:TEUI_FACE_DETECTION] ||
       [_abilityType isEqualToString:TEUI_GESTURE_DETECTION] ||
       [_abilityType isEqualToString:TEUI_BEAUTY_TEMPLATE]){
        self.commonView.hidden = NO;
        self.bottomView.hidden = YES;
        self.underView.hidden = YES;
    }else{
        self.commonView.hidden = NO;
        self.bottomView.hidden = NO;
        self.underView.hidden = YES;
    }
}

- (void)closeBottomClick{
    if([_abilityType isEqualToString:TEUI_FACE_DETECTION] ||
       [_abilityType isEqualToString:TEUI_GESTURE_DETECTION] ||
       [_abilityType isEqualToString:TEUI_BEAUTY_TEMPLATE]){
        self.openBottomView.hidden = NO;
        self.commonView.hidden = YES;
        self.bottomView.hidden = YES;
        self.underView.hidden = NO;
    }else{
        self.teSlider.hidden = YES;
        self.makeupOrLut.hidden = YES;
        self.commonView.hidden = YES;
        self.bottomView.hidden = NO;
        self.underView.hidden = YES;
    }
}

-(void)downloadRes:(NSString *)category teUIProperty:(TEUIProperty *)teUIProperty{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf showLoading];
    });
    [[TEDownloader shardManager] download:teUIProperty.resourceUri destinationURL:_currentUIProperty.downloadPath progressBlock:^(CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
               strongSelf.showProgress = progress * 100;
               strongSelf.processLabel.text = [NSString stringWithFormat:@"%@%d%%",[[TEUIConfig shareInstance] localizedString:@"downloading"],strongSelf.showProgress];
               if (strongSelf.showProgress == 100) {
                   strongSelf.showProgress = 0;
                   strongSelf.processLabel.text = @"";
               }
        });
    } successBlock:^(BOOL success, NSString *downloadFileLocalPath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf dismissLoading];
        });
        if (!success) {
            return;
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if([category isEqualToString:EFFECT_SEGMENTATION]){
            [strongSelf setSegmentation:downloadFileLocalPath teUIProperty:teUIProperty];
            return;
        }
        NSString *makeupLutStrength = teUIProperty.sdkParam.extraInfo.makeupLutStrength;
        NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
        extraInfo[@"mergeWithCurrentMotion"] = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
        if([category isEqualToString:EFFECT_MAKEUP]){
            extraInfo[@"makeupLutStrength"] = makeupLutStrength;
        }
        [strongSelf setBeauty:category effectValue:teUIProperty.sdkParam.effectValue resourcePath:downloadFileLocalPath extraInfo:extraInfo save:YES];
    }];
    
}

- (void)updateBeautyEffect:(TEUIProperty *)teUIProperty{
    if(_currentUIPropertyList[_beautyType].teCategory == TECategory_BEAUTY){
        if(teUIProperty.sdkParam == nil){ //关闭美颜
            [self setUIState:_currentUIPropertyList[_beautyType].propertyList uiState:TEUIState_INIT];
            [self setBeautyWithTEUIPropertyList:_currentUIPropertyList[_beautyType].propertyList];
            NSMutableArray<TESDKParam *> *sdkParamList = [_teBeautyKit getInUseSDKParamList];
            for (TESDKParam *sdkParam in sdkParamList) {
                if ([self isBeauty:sdkParam.effectName]) {
                    sdkParam.effectValue = 0;
                    [_teBeautyKit setEffect:sdkParam];
                }
            }
            [self.beautyCollection reloadData];
        }
        if(self.templateParam){
            if(_currentTemplateProperty.paramList == nil){
                _currentTemplateProperty.paramList = [NSMutableArray array];
            }else{
                for (Param *param in _currentTemplateProperty.paramList) {
                    if([param.effectName isEqualToString:teUIProperty.sdkParam.effectName]){
                        [_currentTemplateProperty.paramList removeObject:param];
                        break;
                    }
                }
            }
            Param *param = [[Param alloc] init];
            param.effectName = teUIProperty.sdkParam.effectName;
            param.effectValue = [NSString stringWithFormat:@"%d",teUIProperty.sdkParam.effectValue];
            param.resourcePath = teUIProperty.sdkParam.resourcePath;
            [_currentTemplateProperty.paramList addObject:param];
        }
        if ([self.tePanelDataProvider.exclusionNoneGroup containsObject:teUIProperty.sdkParam.effectName] &&
            teUIProperty.sdkParam.resourcePath.length == 0 &&
            teUIProperty.sdkParam.effectValue == 0) {
            _teSlider.hidden = YES;
        }
        [self setBeauty:teUIProperty.sdkParam.effectName effectValue:teUIProperty.sdkParam.effectValue resourcePath:teUIProperty.sdkParam.resourcePath extraInfo:nil save:YES];
    }else if(_currentUIProperty.teCategory == TECategory_LUT){
        if ([TEUtils isURL:teUIProperty.resourceUri]) {
            NSString *path = [self fileExits:teUIProperty.resourceUri dirPath:_currentUIProperty.downloadPath];
            if (path != nil) {
                [self setBeauty:EFFECT_LUT effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:nil save:YES];
            }else{
                [self downloadRes:EFFECT_LUT teUIProperty:teUIProperty];
            }
        }else{
            NSString *path = [[[NSBundle mainBundle] pathForResource:@"lut" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            if (teUIProperty.resourceUri == nil) {
                path = nil;
            }
            [self setBeauty:EFFECT_LUT effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:nil save:YES];
        }
    }else if (_currentUIProperty.teCategory == TECategory_MOTION){
        if ([TEUtils isURL:teUIProperty.resourceUri]) {
            NSString *path = [self fileExits:teUIProperty.resourceUri dirPath:_currentUIPropertyList[_beautyType].downloadPath];
            if (path != nil) {
                NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
                extraInfo[@"mergeWithCurrentMotion"] = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
                [self setBeauty:EFFECT_MOTION effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:extraInfo save:YES];
            }else{
                [self downloadRes:EFFECT_MOTION teUIProperty:teUIProperty];
            }
        }else{
            NSString *path = [[[NSBundle mainBundle] pathForResource:@"2dMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                path = [[[NSBundle mainBundle] pathForResource:@"3dMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            }
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                path = [[[NSBundle mainBundle] pathForResource:@"handMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            }
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                path = [[[NSBundle mainBundle] pathForResource:@"ganMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            }
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                NSLog(@"error: %@ not found",path);
                return;
            }
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            dic[@"mergeWithCurrentMotion"] = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
            if (teUIProperty.resourceUri == nil) {
                path = nil;
            }
            [self setBeauty:EFFECT_MOTION effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:dic save:YES];
        }
    }else if (_currentUIProperty.teCategory == TECategory_MAKEUP){
        if ([TEUtils isURL:teUIProperty.resourceUri]) {
            NSString *path = [self fileExits:teUIProperty.resourceUri dirPath:_currentUIPropertyList[_beautyType].downloadPath];
            if (path != nil) {
                NSString *makeupLutStrength = teUIProperty.sdkParam.extraInfo.makeupLutStrength;
                NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
                extraInfo[@"makeupLutStrength"] = makeupLutStrength;
                extraInfo[@"mergeWithCurrentMotion"] = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
                [self setBeauty:EFFECT_MAKEUP effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:extraInfo save:YES];
                
            }else{
                [self downloadRes:EFFECT_MAKEUP teUIProperty:teUIProperty];
            }
        }else{
            NSString *path = [[[NSBundle mainBundle] pathForResource:@"makeupMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                NSLog(@"error: %@ not found",path);
                return;
            }
            NSString *makeupLutStrength = teUIProperty.sdkParam.extraInfo.makeupLutStrength;
            NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
            extraInfo[@"makeupLutStrength"] = makeupLutStrength;
            extraInfo[@"mergeWithCurrentMotion"] = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
            if (teUIProperty.resourceUri == nil) {
                path = nil;
            }
            [self setBeauty:EFFECT_MAKEUP effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:extraInfo save:YES];
        }
    }else if (_currentUIPropertyList[_beautyType].teCategory == TECategory_SEGMENTATION ||
              _currentUIProperty.teCategory == TECategory_SEGMENTATION){
        if ([TEUtils isURL:teUIProperty.resourceUri]) {
            NSString *path = [self fileExits:teUIProperty.resourceUri dirPath:_currentUIPropertyList[_beautyType].downloadPath];
            if (path != nil) {
                NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
                extraInfo[@"mergeWithCurrentMotion"] = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
                [self setBeauty:EFFECT_SEGMENTATION effectValue:teUIProperty.sdkParam.effectValue resourcePath:path extraInfo:extraInfo save:YES];
            }else{
                [self downloadRes:EFFECT_SEGMENTATION teUIProperty:teUIProperty];
            }
        }else{
            NSString *path = [[[NSBundle mainBundle] pathForResource:@"segmentMotionRes" ofType:@"bundle"] stringByAppendingPathComponent:teUIProperty.resourceUri.lastPathComponent];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                NSLog(@"error: %@ not found",path);
                return;
            }
            if (teUIProperty.resourceUri == nil) {
                path = nil;
            }
            [self setSegmentation:path teUIProperty:teUIProperty];
        }
    }else if (_currentUIPropertyList[_beautyType].teCategory == TECategory_TEMPLATE){
        for (Param *param in _lastTemplateProperty.paramList) {
            [self setBeauty:param.effectName effectValue:0 resourcePath:param.resourcePath extraInfo:nil save:YES];
        }
        _lastTemplateProperty = teUIProperty;
        for (Param *param in teUIProperty.paramList) {
            [self setBeauty:param.effectName effectValue:[param.effectValue intValue] resourcePath:param.resourcePath extraInfo:nil save:YES];
        }
    }
}

-(void)clearBeauty:(NSMutableArray<TESDKParam *> *)sdkParams{
    for (TESDKParam *param in sdkParams) {
        [self setBeauty:param.effectName effectValue:0 resourcePath:param.resourcePath extraInfo:nil save:NO];
    }
    [_teBeautyKit clearEffectParam];
}



- (void)setSegmentation:(NSString *)path teUIProperty:(TEUIProperty *)teUIProperty{
    _mergeCurMotion = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
    if([teUIProperty.sdkParam.extraInfo.segType isEqualToString:@"custom_background"]){
        _segmentationType = 0;
        _segmentationResPath = path;
        [self openImagePicker];
    }else if ([teUIProperty.sdkParam.extraInfo.segType isEqualToString:@"green_background"]){
        _segmentationType = 1;
        _segmentationResPath = path;
        [self greenscreenAlert];
    }else{
        NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
        extraInfo[@"mergeWithCurrentMotion"] = teUIProperty.sdkParam.extraInfo.mergeWithCurrentMotion;
        
        [self setBeauty:EFFECT_SEGMENTATION effectValue:0 resourcePath:path extraInfo:extraInfo save:YES];
    }
}

-(void)greenscreenAlert{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    if (@available(iOS 13.0, *)) {
        alertController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    NSMutableAttributedString *titleStr = [[NSMutableAttributedString alloc] initWithString:[[TEUIConfig shareInstance] localizedString:@"greenscreen_import_picture"]];
    [titleStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.9/1.0] range:NSMakeRange(0, titleStr.length)];
    [titleStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:20] range:NSMakeRange(0, titleStr.length)];
    [alertController setValue:titleStr forKey:@"attributedTitle"];
    NSMutableAttributedString *messageStr = [[NSMutableAttributedString alloc] initWithString:[[TEUIConfig shareInstance] localizedString:@"greenscreen_msg"]];
    [messageStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.3/1.0] range:NSMakeRange(0, messageStr.length)];
    [messageStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:18] range:NSMakeRange(0, messageStr.length)];
    [alertController setValue:messageStr forKey:@"attributedMessage"];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:[[TEUIConfig shareInstance] localizedString:@"greenscreen_import_picture"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self openImagePicker];
    }];
    [sureAction setValue:[UIColor colorWithRed:0 green:0x6e/255.0 blue:1 alpha:1] forKey:@"_titleTextColor"];
    [alertController addAction:sureAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[[TEUIConfig shareInstance] localizedString:@"revert_tip_dialog_left_btn"] style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"取消");
    }];
    [cancelAction setValue:[UIColor blackColor] forKey:@"_titleTextColor"];
    [alertController addAction:cancelAction];
    [[self getControllerFromView:self] presentViewController:alertController animated:YES completion:nil];
}

- (void)configSegmentation{
    NSMutableDictionary* extraInfo = @{@"bgPath":_segmentationPath}.mutableCopy;
    if(_segmentationType == 0){
        [extraInfo setValue:@"custom_background" forKey:@"segType"];
    }else{
        [extraInfo setValue:@"#0x00ff00" forKey:@"keyColor"];
        [extraInfo setValue:@"green_background" forKey:@"segType"];
    }
    [extraInfo setValue:[NSString stringWithFormat:@"%d",_segmentationBgType] forKey:@"bgType"];
    extraInfo[@"mergeWithCurrentMotion"] = _mergeCurMotion;
    [self setBeauty:EFFECT_SEGMENTATION effectValue:0 resourcePath:_segmentationResPath extraInfo:extraInfo save:YES];
}

-(void)openImagePicker{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    //资源类型为图片库
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes =@[(NSString*)kUTTypeMovie, (NSString*)kUTTypeImage];
    picker.delegate = self;
    //设置选择后的图片可被编辑
    picker.allowsEditing = NO;
    [[self getControllerFromView:self] presentViewController:picker animated:YES completion:nil];
}

- (void)showLoading{
    if(_isShowLoading){
        return;
    }
    _isShowLoading = YES;
    UIViewController *curViewController = [self getControllerFromView:self];
    [curViewController.view addSubview:self.loadingCover];
    [self.loadingCover mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(curViewController.view);
        make.left.right.mas_equalTo(curViewController.view);
    }];
    [curViewController.view addSubview:self.loadingView];
    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo((curViewController.view.bounds.size.height -30)/2);
        make.left.mas_equalTo((curViewController.view.bounds.size.width -30)/2);
        make.width.height.mas_equalTo(30);
    }];
    
    [curViewController.view addSubview:self.processLabel];
    [self.processLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.loadingView.mas_bottom).offset(3);
        make.centerX.mas_equalTo(self.loadingView.mas_centerX);
        make.width.mas_equalTo(200);
        make.height.mas_equalTo(30);
    }];
    
    [self.loadingView startAnimating];
}

-(void)dismissLoading{
    [self.loadingView stopAnimating];
    [self.loadingView removeFromSuperview];
    [self.processLabel removeFromSuperview];
    [self.loadingCover removeFromSuperview];
    _isShowLoading = NO;
}

- (void)setBeauty:(NSString * _Nullable)effectName
      effectValue:(int)effectValue
     resourcePath:(NSString * _Nullable)resourcePath
        extraInfo:(NSDictionary * _Nullable)extraInfo
             save:(BOOL)save{
    float multiple = 1.0;
    if(self.enhancedMode && ([self isBeauty:effectName])){
        id value = [_tePanelDataProvider.enhancedMultipleDictionary valueForKey:effectName];
        if(value != nil){
            multiple = [value floatValue];
        }else{
            multiple = 1.2;
        }
    }
    [self.beautyKitApi setEffect:effectName effectValue:effectValue * multiple resourcePath:resourcePath extraInfo:extraInfo];
    if([self.delegate respondsToSelector:@selector(setEffect)]){
        [self.delegate setEffect];
    }
    if(!save){
        return;
    }
    TESDKParam *param = [[TESDKParam alloc] init];
    param.effectName = effectName;
    param.effectValue = effectValue;
    param.resourcePath = [self convertPathToCustomPrefix:resourcePath];
    param.extraInfoDic = extraInfo;
    [_teBeautyKit saveEffectParam:param];
}

- (NSString *)convertPathToCustomPrefix:(NSString *)path {
    if ([path hasPrefix:NSHomeDirectory()]) {
        return [path stringByReplacingOccurrencesOfString:NSHomeDirectory() withString:kSandboxPrefix];
    } else if ([path hasPrefix:[[NSBundle mainBundle] bundlePath]]) {
        return [path stringByReplacingOccurrencesOfString:[[NSBundle mainBundle] bundlePath] withString:kBundlePrefix];
    }
    return path;
}

- (void)isShowCompareBtn:(BOOL)isShow{
    self.compareButton.hidden = !isShow;
    _showCompareBtn = isShow;
}

- (void)setDefaultBeauty{
    if ([_abilityType isEqualToString:TEUI_BEAUTY_TEMPLATE]){
        for (TEUIProperty *property in _currentUIProperty.propertyList) {
            if(property.uiState == 2){
                for (Param *param in property.paramList) {
                    [self setBeauty:param.effectName effectValue:[param.effectValue intValue] resourcePath:param.resourcePath extraInfo:nil save:YES];
                }
            }
        }
        return;
    }
    if(_defaultBeautyList.count > 0){
        [self setBeautyWithTEUIPropertyList:_defaultBeautyList];
    }else{
        NSMutableArray<TEUIProperty *> *property = [NSMutableArray array];
        if(_currentUIProperty == nil){
            return;
        }
        [property addObject:_currentUIProperty];
        [self setBeautyWithTEUIPropertyList:property];
    }
}

- (void)setLastParamList:(NSString *)lastParamList{
    NSData *jsonData = [lastParamList dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData == nil) {
        return;
    }

    NSError *error;
    NSMutableDictionary *beautyDics = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    NSMutableArray<TESDKParam *>*effectList = [NSMutableArray array];
    for (NSDictionary *dic in beautyDics) {
        TESDKParam *param = [[TESDKParam alloc] init];
        [param setValuesForKeysWithDictionary:dic];
        [effectList addObject:param];
    }
    [self resetBeautyData:_currentUIPropertyList parentUIProperty:nil targetData:effectList];
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.beautyCollection reloadData];
    });
}

- (void)resetBeautyData:(NSMutableArray<TEUIProperty *>*)uiPropertyList parentUIProperty:(TEUIProperty *)parentUIProperty targetData:(NSMutableArray<TESDKParam *>*)targetData{
    if (uiPropertyList.count == 0 || targetData.count == 0) {
        return;
    }
    for (TEUIProperty *uiproperty in uiPropertyList) {
        if (uiproperty.propertyList.count > 0) {
            [self resetBeautyData:uiproperty.propertyList parentUIProperty:uiproperty targetData:targetData];
        }else{
            for (TESDKParam *sdkparam in targetData) {
                if ([self.tePanelDataProvider.exclusionNoneGroup containsObject:uiproperty.sdkParam.effectName]) {
                    if ([sdkparam.effectName isEqualToString:uiproperty.sdkParam.effectName]
                        && [sdkparam.resourcePath isEqualToString:uiproperty.sdkParam.resourcePath]) {
                        uiproperty.sdkParam.effectValue = sdkparam.effectValue;
                        uiproperty.uiState = TEUIState_IN_USE;
                        parentUIProperty.uiState = TEUIState_IN_USE;
                        break;
                    }else{
                        uiproperty.uiState = TEUIState_INIT;
                    }
                }else{
                    if (uiproperty.sdkParam.effectName.length > 0) {
                        if ([sdkparam.effectName isEqualToString:uiproperty.sdkParam.effectName]) {
                            uiproperty.sdkParam.effectValue = sdkparam.effectValue;
                            uiproperty.uiState = TEUIState_IN_USE;
                            break;
                        }else{
                            uiproperty.uiState = TEUIState_INIT;
                        }
                    }else{
                        if ([uiproperty.resourceUri.lastPathComponent isEqualToString:sdkparam.resourcePath.lastPathComponent]) {
                            uiproperty.sdkParam.effectValue = sdkparam.effectValue;
                            uiproperty.uiState = TEUIState_IN_USE;
                            break;
                        }else{
                            uiproperty.uiState = TEUIState_INIT;
                        }
                    }
                }
            }
        }
    }
}

- (void)setEnhancedMode:(BOOL)enhancedMode{
    _enhancedMode = enhancedMode;
    if(_enhancedMode){
        [self.beautyKitApi enableEnhancedMode];
    }
    for (TESDKParam *param in _teBeautyKit.usedSDKParam) {
        if([self isBeauty:param.effectName]){
            [self setBeauty:param.effectName effectValue:param.effectValue resourcePath:param.resourcePath extraInfo:param.extraInfoDic save:NO];
        }
    }
}

- (BOOL)isBeauty:(NSString *)effectName{
    if([effectName hasPrefix:@"beauty."] ||
        [effectName hasPrefix:@"basicV7."] ||
        [effectName hasPrefix:@"smooth."] ||
       [effectName hasPrefix:@"liquefaction."]){
        return YES;
    }
    return NO;
}

- (void)setBeautyWithTEUIPropertyList:(NSMutableArray<TEUIProperty *>*)teUIPropertyList{
    for (TEUIProperty *teUIProperty in teUIPropertyList) {
        if(teUIProperty.propertyList.count == 0 && teUIProperty.uiState != TEUIState_INIT){
            [self setBeauty:teUIProperty.sdkParam.effectName effectValue:teUIProperty.sdkParam.effectValue resourcePath:teUIProperty.sdkParam.resourcePath extraInfo:nil save:YES];
        }else{
            [self setBeautyWithTEUIPropertyList:teUIProperty.propertyList];
        }
    }
}

- (void)setUIState:(NSArray<TEUIProperty *>*) propertyList uiState:(int)uiState{
    for (TEUIProperty *property in propertyList) {
        if(property.propertyList.count == 0){
            property.sdkParam.effectValue = uiState;
            property.uiState = uiState;
        }else{
            property.uiState = uiState;
            [self setUIState:property.propertyList uiState:uiState];
        }
    }
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _currentUIProperty.propertyList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    TECollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TECollectionViewCell" forIndexPath:indexPath];
    TEUIProperty  *teUIProperty = _currentUIProperty.propertyList[indexPath.item];
    cell.teUIProperty = teUIProperty;
    cell.userInteractionEnabled = true;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    _selectedIndex = (int)indexPath.row;
    if(self.makeupType == 1){
        self.makeupType = 0;
        UIButton *leftBtn = [self.makeupOrLut viewWithTag:120];
        [leftBtn setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1] forState:UIControlStateNormal];
        leftBtn.backgroundColor = [UIColor whiteColor];
        UIButton *rightBtn = [self.makeupOrLut viewWithTag:120 + 1];
        [rightBtn setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4] forState:UIControlStateNormal];
        rightBtn.backgroundColor = [UIColor clearColor];
    }
    if(_currentUIProperty.propertyList[indexPath.row].propertyList.count == 0){
        if ([_abilityType isEqualToString:TEUI_MOTION_2D] ||
                  [_abilityType isEqualToString:TEUI_MOTION_3D] ||
                  [_abilityType isEqualToString:TEUI_MOTION_GESTURE] ||
                  [_abilityType isEqualToString:TEUI_MOTION_CAMERA_MOVE] ||
                  [_abilityType isEqualToString:TEUI_SEGMENTATION]){
            for (TEUIProperty *teuiProperty in _currentUIPropertyList) {
                for (TEUIProperty *property in teuiProperty.propertyList) {
                    if(property.uiState == TEUIState_CHECKED_AND_IN_USE){
                        property.uiState = TEUIState_INIT;
                    }
                }
            }
        }else{
            for (TEUIProperty *property in _currentUIProperty.propertyList) {
                if(property.uiState == TEUIState_CHECKED_AND_IN_USE){
                    if(property.propertyList.count > 0){
                        property.uiState = TEUIState_IN_USE;
                    }else{
                        if(property.sdkParam.effectValue == TEUIState_INIT){
                            property.uiState = TEUIState_INIT;
                        }else{
                            property.uiState = TEUIState_IN_USE;
                        }
                    }
                }
                if([_tePanelDataProvider.exclusionGroup containsObject:_currentUIProperty.propertyList[indexPath.row].sdkParam.effectName]){
                    property.uiState = TEUIState_INIT;
                }
            }
        }
        _currentUIProperty.propertyList[indexPath.row].uiState = TEUIState_CHECKED_AND_IN_USE;
        if(_currentUIProperty.propertyList[indexPath.row].sdkParam.numericalType){
            _teSlider.hidden = NO;
            YTBeautyPropertyInfo *propertyInfo = [self.beautyKitApi getConfigPropertyWithName:_currentUIProperty.propertyList[indexPath.row].sdkParam.effectName];
            if(propertyInfo != nil){
                _teSlider.minimumValue = [propertyInfo.minValue intValue];
                _teSlider.maximumValue = [propertyInfo.maxValue intValue];
            }else{
                _teSlider.minimumValue = 0;
                _teSlider.maximumValue = 100;
            }
            if(_templateParam){
                _teSlider.value = [propertyInfo.curValue intValue];
            }else{
                _teSlider.value = _currentUIProperty.propertyList[indexPath.row].sdkParam.effectValue;
            }
            if(_currentUIProperty.teCategory == TECategory_MAKEUP && _currentUIProperty.propertyList[indexPath.row].sdkParam.extraInfo.makeupLutStrength != nil){
                self.makeupOrLut.hidden = NO;
                if(self.makeupType == 1){
                    self.teSlider.value = [_currentUIProperty.propertyList[indexPath.row].sdkParam.extraInfo.makeupLutStrength intValue];
                }
                [self.teSlider mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.left.mas_equalTo(self).mas_offset(102);
                    make.right.mas_equalTo(self).mas_offset(_showCompareBtn ? -45 : -10);
                    make.centerY.mas_equalTo(self.compareButton.mas_centerY);
                }];
            }else{
                self.makeupOrLut.hidden = YES;
                [self.teSlider mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.left.mas_equalTo(self).mas_offset(10);
                    make.right.mas_equalTo(self).mas_offset(_showCompareBtn ? -45 : -10);
                    make.centerY.mas_equalTo(self.compareButton.mas_centerY);
                }];
            }
        }else{
            _teSlider.hidden = YES;
            self.makeupOrLut.hidden = YES;
        }
        [self updateBeautyEffect:_currentUIProperty.propertyList[indexPath.row]];
        [self.beautyCollection reloadData];
    }else{
        _teSlider.hidden = YES;
        _makeupOrLut.hidden = YES;
        _currentUIProperty = _currentUIProperty.propertyList[indexPath.row];
        for (TEUIProperty *property in _currentUIProperty.propertyList) {
            if(property.uiState == TEUIState_CHECKED_AND_IN_USE){
                if(property.sdkParam.effectValue == 0){
                    property.uiState = TEUIState_INIT;
                }else{
                    property.uiState = TEUIState_IN_USE;
                }
            }
        }
        [self setSubMenu:YES];
        [self.beautyCollection reloadData];
        [self.beautyCollection scrollToItemAtIndexPath:
         [NSIndexPath indexPathForItem:0 inSection:0]
        atScrollPosition:UICollectionViewScrollPositionLeft
        animated:NO];
    }
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
           _segmentationPath = imagePath;
           _timeOffset = [NSNumber numberWithInt:0];
           _segmentationBgType = 0;
           [self configSegmentation];
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
           [[self getControllerFromView:self] presentViewController:alertVC animated:YES completion:nil];
           [self performSelector:@selector(dismissAlert:) withObject:alertVC afterDelay:2.0];
       }
}
- (void)dismissAlert:(UIAlertController *)alert{
    [alert dismissViewControllerAnimated:YES completion:nil];
}

// 取消图片选择回调
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [[self getControllerFromView:self] dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"取消");
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
                self->_segmentationPath = outputURL.path;
                self->_timeOffset = [NSNumber numberWithInt:timeOffset];
                self->_segmentationBgType = 1;
                [self configSegmentation];
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

-(NSString *)fileExits:(NSString *)resUri dirPath:(NSString *)dirPath{
    NSURL *downloadURL = [NSURL URLWithString:resUri];
    NSString *filename = downloadURL.lastPathComponent;
    if([filename.pathExtension.lowercaseString isEqualToString:@"zip"]){
        filename = [filename stringByDeletingPathExtension];
    }
    NSString *path =  [[[TEDownloader shardManager].basicPath stringByAppendingPathComponent:dirPath] stringByAppendingPathComponent:filename];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
        return path;
    }
    return nil;
}
- (UIViewController *)getControllerFromView:(UIView *)view {
    // 遍历响应者链。返回第一个找到视图控制器
    UIResponder *responder = view;
    while ((responder = [responder nextResponder])){
        if ([responder isKindOfClass: [UIViewController class]]){
            return (UIViewController *)responder;
        }
    }
    // 如果没有找到则返回nil
    return nil;
}

- (void)dealloc{
    [_tePanelDataProvider clearMotionLutData];
}

@end
