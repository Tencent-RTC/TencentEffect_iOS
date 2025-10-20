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
#import <XMagic/XmagicConstant.h>
#import "../TEUIConfig.h"
#import "TEBeautyProcess.h"
#import "TECommonDefine.h"

#define beautyCollectionItemWidth 62
#define beautyCollectionItemHeight 90
#define beautyCollectionHeight 250
// 屏幕的宽
#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
// 屏幕的高
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height

// TEPanelView的类扩展，声明私有属性和协议遵循
@interface TEPanelView() <
    UICollectionViewDelegate,               // 集合视图代理（处理交互事件）
    UICollectionViewDataSource,             // 集合视图数据源（提供内容）
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate,        // 图片选择控制器代理
    TEBeautyProcessDelegate,
    UIGestureRecognizerDelegate>             // 手势识别代理

/* 视图相关属性 */
@property (nonatomic, strong) UICollectionView *beautyCollection;       // 美颜参数集合视图
@property (nonatomic, strong) TEBeautyProcess *beautyProcess;           //负责业务处理
@property (nonatomic, strong) UIView *blackView;                       // 黑色遮罩视图
@property (nonatomic, strong) UIView *vLineView;                        // 垂直分割线
@property (nonatomic, strong) UIView *hLineView;                        // 水平分割线
@property (nonatomic, strong) UIView *rightResetView;                   // 右侧重置按钮容器
@property (nonatomic, strong) UIView *moreView;                         // 更多功能视图
@property (nonatomic, strong) UIView *commonView;                       // 通用设置视图
@property (nonatomic, strong) UIScrollView* scrollView;                 // 滚动容器视图
@property (nonatomic, strong) UILabel *beautyTitleLabel;                // 美颜标题标签
@property (nonatomic, strong) UIButton  *backButton;                    // 返回按钮
@property (nonatomic, strong) NSMutableArray <UIButton *>*titleBtns;     // 美颜分类标题按钮组
@property (nonatomic, strong) TESlider *teSlider;                        // 定制滑动条组件
@property (nonatomic, strong) UIView *makeupOrLut;                      // 美妆/LUT切换容器
@property (nonatomic, strong) UIButton *compareButton;                  // 效果对比按钮
@property (nonatomic, strong) UILabel *processLabel;                    // 进度提示标签
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;     // 加载指示器

/* 数据模型相关 */
@property (nonatomic, strong) TEUIProperty *currentUIProperty;          // 当前选中UI属性项
@property (nonatomic, strong) TEUIProperty *lastUIProperty;          // 上一个选中的UI属性项

@property (nonatomic, strong) NSMutableArray<TEUIProperty *> *currentUIPropertyList; // 当前显示属性列表
@property (nonatomic, strong) NSMutableArray<TEUIProperty *> *moreUIPropertyList; // 点击更多对应的属性列表
@property (nonatomic, strong) NSMutableArray<TEUIProperty *> *mainUIPropertyList; // 点击更多对应的属性列表
@property (nonatomic, strong) TEPanelDataProvider *tePanelDataProvider; // 数据提供器

/* 状态标记 */
@property (nonatomic, assign) BOOL faceSwitchStatus;                   // 人脸检测开关状态

@property (nonatomic, assign) BOOL gestureSwitchStatus;                // 手势识别开关状态
@property (nonatomic, assign) BOOL moreClicked;                        // 更多按钮点击状态
@property (nonatomic, assign) BOOL isShowLoading;                      // 是否显示加载指示
@property (nonatomic, assign) BOOL showCompareBtn;                     // 是否显示对比按钮
@property (nonatomic, assign) BOOL enhancedMode;                       // 增强模式开关
@property (nonatomic, assign) BOOL showOrigin;                         // 是否显示原图对比


/* 功能参数 */



@property (nonatomic, copy) NSString *abilityType;                     // 当前能力类型
@property (nonatomic, copy) NSString *comboType;                       // 组合类型
@property (nonatomic, assign) int makeupType;                         // 美妆类型

@property (nonatomic, assign) int selectedIndex;                       // 当前选中项索引
@property (nonatomic, assign) int showProgress;                        // 显示进度值

@property (nonatomic, strong) TEUIProperty *curProperty;                // 当前属性项

/* 其他 */
@property (nonatomic, strong) UITapGestureRecognizer *selfTapGesture;   // 自身点击手势


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
    self.tePanelDataProvider = [TEPanelDataProvider shareInstance];
    beautyType = 0;
    isShowGridLayout=NO;
    _moreUIPropertyList = [[NSMutableArray alloc]init];
    self.mainUIPropertyList = [_tePanelDataProvider getAllPanelData];
    self.currentUIPropertyList = self.mainUIPropertyList;
    self.currentUIProperty = self.currentUIPropertyList[beautyType];
}


-(void)initUI{
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
        make.bottom.mas_equalTo(self);
        make.height.mas_equalTo(190);
    }];
    
    [self.blackView addSubview:self.beautyCollection];
    [self setBeautyCollectionView:NO];
    
    // 先屏蔽更多按钮
    [self.commonView addSubview:self.moreView];
    [self.moreView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.mas_right);
        make.top.mas_equalTo(self.beautyCollection.mas_top);
        make.height.mas_equalTo(beautyCollectionItemHeight);
        make.width.mas_equalTo(beautyCollectionItemWidth);
    }];
    self.moreView.hidden = YES;
    
    
    [self.commonView addSubview:self.compareButton];
    [self.compareButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self).mas_offset(-5);
        make.width.height.mas_equalTo(35);
        make.bottom.mas_equalTo(self.blackView.mas_top).mas_offset(-5);
    }];
    [self.commonView addSubview:self.teSlider];
    [self.teSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self).mas_offset(10);
        make.right.mas_equalTo(self).mas_offset(-45);
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
        make.top.mas_equalTo(self.blackView).mas_offset(38);
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

- (TESlider *)teSlider{
    if(!_teSlider){
        _teSlider = [[TESlider alloc]init];
        [_teSlider setTintColor:[TEUIConfig shareInstance].seekBarProgressColor];
        _teSlider.minimumValue = 0;
        _teSlider.maximumValue = 100;
        [_teSlider addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
        [_teSlider setThumbImage:[[TEUIConfig shareInstance] imageNamed:@"SliderIcon"] forState:UIControlStateNormal];
    }
    return _teSlider;
}

- (UIView *)blackView {
    if (!_blackView) {
        _blackView = [[UIView alloc] init];
        _blackView.backgroundColor = [TEUIConfig shareInstance].panelBackgroundColor;

        // 添加点击手势
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(blackViewTapped)];
        tapGesture.delegate = self; // 设置代理
        [_blackView addGestureRecognizer:tapGesture];

        // 确保用户交互开启
        _blackView.userInteractionEnabled = YES;
    }
    return _blackView;
}

- (void)blackViewTapped {
    // 点击事件，空实现，什么都不做
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
        _beautyCollection.showsVerticalScrollIndicator = NO;
        [_beautyCollection registerClass:[TECollectionViewCell class] forCellWithReuseIdentifier:@"TECollectionViewCell"];
    }
    return _beautyCollection;
}

- (TEBeautyProcess *)beautyProcess {
    if (!_beautyProcess) {
        _beautyProcess = [[TEBeautyProcess alloc] init];
        _beautyProcess.delegate=self;
        _beautyProcess.enhancedMode=self.enhancedMode;
        _beautyProcess.abilityType=self.abilityType;
    }
    
    if(self.teBeautyKit && !_beautyProcess.teBeautyKit){
        _beautyProcess.teBeautyKit=self.teBeautyKit;
    }
    return _beautyProcess;
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

- (UIButton *)createButtonWithIndex:(NSInteger)i index:(int)index{
    // 1. 基础配置
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor clearColor];
    btn.tag = index;
    
    // 2. 国际化标题
    NSString *title = [TEUtils isCurrentLanguageHans]
        ? self.currentUIPropertyList[i].displayName
        : self.currentUIPropertyList[i].displayNameEn;
    [btn setTitle:title forState:UIControlStateNormal];
    
    // 3. 统一字体配置
    btn.titleLabel.font = [UIFont systemFontOfSize:16];
    
    // 4. 颜色配置
    UIColor *titleColor = (i == beautyType)
        ? [UIColor whiteColor]
        : [UIColor colorWithRed:1 green:1 blue:1 alpha:0.7];
    [btn setTitleColor:titleColor forState:UIControlStateNormal];
    
    // 5. 添加点击事件
    [btn addTarget:self action:@selector(onSetAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return btn;
}

- (void)layoutButton:(UIButton *)btn x:(CGFloat *)x {
    // 1. 计算按钮宽度
    CGFloat textWidth = [TEUtils textWidthFromTitle:btn.titleLabel.text font:btn.titleLabel.font];
    CGFloat btnWidth = textWidth + 5;
    
    // 2. 更新按钮Frame
    btn.frame = CGRectMake(*x, 0, btnWidth, 24);
    
    // 3. 更新X坐标
    *x += btnWidth + 20;
}

#pragma mark - 清空美颜面板顶部按钮视图
- (void)clearTitleView {
    // 1. 从父视图移除所有按钮
    for (UIButton *btn in self.titleBtns) {
        [btn removeFromSuperview];
    }
    
    // 2. 清空数组
    [self.titleBtns removeAllObjects];
    
    // 遍历并移除所有子视图
    for (UIView *subview in self.scrollView.subviews) {
        [subview removeFromSuperview];
    }
}

- (int)selectedBeautyType {
    TEUIProperty * currentProp = self.currentUIProperty;
    
    for (int i = 0; i < self.currentUIPropertyList.count; i++) {
        TEUIProperty *mode = self.currentUIPropertyList[i];
        if (mode == currentProp) {
            return i;
        }
        
        for (TEUIProperty *prod in mode.propertyList) {
            if (prod == currentProp) {
                return i;
            }
        }
    }
    return 0;
}


#pragma mark - 美颜面板顶部菜单选项按钮
- (void)addTabButtons:(BOOL)reset{
    CGFloat btnHeight = 24;
    CGFloat btnWidth = 0;
    CGFloat x = 20;
    
    [self clearTitleView];
    
    if (self.currentUIPropertyList.count == 0) {
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
        [self.titleBtns addObject:btn];
        [self.scrollView addSubview:btn];
        [self.commonView addSubview:self.scrollView];
        [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(btnWidth);
            make.height.mas_equalTo(24);
            make.centerX.mas_equalTo(self);
            make.top.mas_equalTo(self.blackView.mas_top).mas_offset(6);
        }];
        self.scrollView.scrollEnabled = NO;
        return;
    }
    
    int index=0;
    
    self.currentUIPropertyList = isShowGridLayout ? self.moreUIPropertyList:self.mainUIPropertyList;
    for (int i = 0; i < self.currentUIPropertyList.count; i++) {
        // 2. 创建按钮
        UIButton *btn = [self createButtonWithIndex:i index:index];
        index++;
        // 3. 计算布局
        [self layoutButton:btn x:&x];
        
        // 4. 添加视图
        [self.titleBtns addObject:btn];
        [self.scrollView addSubview:btn];
        
    }
    
    [self setTitleColor];
    beautyType=[self selectedBeautyType];//找到当前的beautyType值
    [self.titleBtns[beautyType] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    if (self.scrollView.superview == nil) {
        [self.commonView addSubview:self.scrollView];
    }
    
//    [TEUIConfig shareInstance].isPanelTitleCentered = YES;
    // 定义约束配置的 Block
    void (^configureConstraints)(BOOL isCountGreaterThanThree) = ^(BOOL titleCentered) {
        [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
            if (!titleCentered) {
                make.left.mas_equalTo(self);
            }
            make.height.mas_equalTo(24);
            make.top.mas_equalTo(self.blackView.mas_top).mas_offset(6);
            make.width.mas_equalTo(self.frame.size.width - 81);
            make.right.mas_equalTo(self).mas_equalTo(-81);
            if (titleCentered) {
                make.centerX.mas_equalTo(self);
            }
        }];
    };
    //只有当item 小于等于3 并且宽度小于可用空间，并且isPanelTitleCentered = YES的情况
    bool centered = self.currentUIPropertyList.count <= 3 && [TEUIConfig shareInstance].isPanelTitleCentered && x < (ScreenWidth - 81);
    configureConstraints(centered);
    self.scrollView.contentSize = CGSizeMake(x, 24);
    self.scrollView.scrollEnabled = YES;
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
        
        [self.blackView addSubview:_backButton];
        [_backButton addTarget:self action:@selector(clickBack) forControlEvents:UIControlEventTouchUpInside];
    }
    self.scrollView.hidden = hide;
    self.backButton.hidden = !hide;
    self.beautyTitleLabel.hidden = !hide;
}


#pragma mark - 处理美颜参数集合视图展示
-(void)setBeautyCollectionView:(BOOL)isShowMoreView{
    if(isShowMoreView && !isShowGridLayout){
        [self.beautyCollection mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.mas_left).mas_offset(20);  // 左边缘距父视图左边缘20
            make.right.mas_equalTo(self.mas_right).offset(-70);   // 右边缘距父视图右边缘-70
            make.bottom.mas_equalTo(self.blackView.mas_bottom).mas_offset(-50); // 底部对齐到 blackView 底部向上-50
            make.height.mas_equalTo(beautyCollectionItemHeight); // 固定高度
        }];
    }else{
        [self.beautyCollection mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self.mas_width);
            isShowGridLayout?(make.left.mas_equalTo(self.mas_left).mas_offset(20)):(make.left.mas_equalTo(self.mas_left));
            make.bottom.mas_equalTo(self.blackView.mas_bottom).mas_offset(-50); // 底部对齐到 blackView 底部向上-50
            make.height.mas_equalTo(beautyCollectionItemHeight); // 固定高度
        }];
        
    }
    self.moreView.hidden = !(isShowMoreView && !isShowGridLayout);
}

-(void)setTitleColor{
    for (int i = 0; i < self.titleBtns.count; i++) {
        [self.titleBtns[i] setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.7] forState:UIControlStateNormal];
    }
}

#pragma mark - 美颜面板顶部菜单点击事件
- (void)onSetAction:(UIButton *)sender{
    _teSlider.hidden = YES;
    _makeupOrLut.hidden = YES;
    int number = (int)sender.tag;
    beautyType = number;
    
    //处理美颜参数集合视图展示
    [self setBeautyCollectionView:self.currentUIPropertyList[beautyType].isShowGridLayout];
    
    [self setTitleColor];
    
    [self.titleBtns[number] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.currentUIProperty = self.currentUIPropertyList[beautyType];
    
    [self.beautyCollection reloadData];
    if([self.currentUIProperty.abilityType isEqualToString:TEUI_FACE_DETECTION]){
    }else if ([self.currentUIProperty.abilityType isEqualToString:TEUI_GESTURE_DETECTION]){
    }
}

#pragma mark - 返回按钮
-(void)clickBack {
    NSInteger currentIndex = beautyType;
    NSArray<TEUIProperty *> *propertyList = self.currentUIPropertyList[currentIndex].propertyList;
    TEUIProperty *currentProperty = _currentUIProperty;
    
    if ([propertyList containsObject:currentProperty]) {
        
        // 先找出当前 propertyList 中是否有 uiState == TEUIState_CHECKED_AND_IN_USE 的 property
        TEUIProperty *checkedInUseProperty = nil;
        for (TEUIProperty *prop in currentProperty.propertyList) {
            if (prop.uiState == TEUIState_CHECKED_AND_IN_USE) {
                checkedInUseProperty = prop;
                break;
            }
        }
        
        if (checkedInUseProperty) {
            // 找到当前选中的索引
            NSUInteger currentPropertyIndex = [propertyList indexOfObject:currentProperty];
            
            // 遍历 propertyList，修改 uiState，根据 effectValue 是否为 0
            for (int i = 0; i < propertyList.count; i++) {
                TEUIProperty *prop = propertyList[i];
                if (prop.uiState == TEUIState_CHECKED_AND_IN_USE) {
                    prop.uiState = (prop.sdkParam.effectValue == 0) ? TEUIState_INIT : TEUIState_IN_USE;
                }
            }
            
            // 保持当前 property 的 uiState 为 CHECKED_AND_IN_USE
            if (currentPropertyIndex != NSNotFound) {
                propertyList[currentPropertyIndex].uiState = TEUIState_CHECKED_AND_IN_USE;
            }
            
            self.lastUIProperty = currentProperty;
        } else {
            // 如果没有 CHECKED_AND_IN_USE，但当前 property uiState 为 INIT，则给它改为 IN_USE
            if (currentProperty.uiState == TEUIState_INIT) {
                currentProperty.uiState = TEUIState_IN_USE;
            }
        }
        
        self.currentUIProperty = self.currentUIPropertyList[currentIndex];
        [self setSubMenu:NO];
        
    } else {
        self.currentUIProperty = [self getParentProperty:propertyList property:currentProperty];
        [self setSubMenu:YES];
    }
    
    self.teSlider.hidden = YES;
    [self.beautyCollection reloadData];
    
    // 滚动到第一个 uiState == CHECKED_AND_IN_USE 的 property
    for (TEUIProperty *property in self.currentUIProperty.propertyList) {
        if (property.uiState == TEUIState_CHECKED_AND_IN_USE) {
            NSInteger index = [self.currentUIPropertyList[currentIndex].propertyList indexOfObject:property];
            if (index != NSNotFound) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                [self.beautyCollection scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
            }
            break;
        }
    }
}

- (TEUIProperty *)getParentProperty:(NSArray<TEUIProperty *> *)teUIPropertyList property:(TEUIProperty *)property {
    if (!property || property.propertyList.count == 0) {
        return nil;
    }
    
    for (TEUIProperty *parentProperty in teUIPropertyList) {
        // 判断父属性中是否包含property
        if ([parentProperty.propertyList containsObject:property]) {
            
            // 遍历property的子属性，检查条件
            BOOL hasCheckedAndInUseChild = NO;
            for (TEUIProperty *child in property.propertyList) {
                if (child.uiState == TEUIState_CHECKED_AND_IN_USE) {
                    hasCheckedAndInUseChild = YES;
                    break;
                }
            }
            
            if (hasCheckedAndInUseChild) {
                // 遍历父属性子项，调整状态
                for (TEUIProperty *uiProperty in parentProperty.propertyList) {
                    if (uiProperty.uiState == TEUIState_CHECKED_AND_IN_USE) {
                        if (uiProperty.sdkParam.effectValue == TEUIState_INIT) {
                            uiProperty.uiState = TEUIState_INIT;
                        } else {
                            uiProperty.uiState = TEUIState_IN_USE;
                        }
                    }
                }
                property.uiState = TEUIState_CHECKED_AND_IN_USE;
            }
            
            return parentProperty;
        }
    }
    return nil;
}

- (void)valueChange:(id)sender {
    UISlider * slider =(UISlider*)sender;
    if((_currentUIProperty.teCategory == TECategory_MAKEUP || _currentUIProperty.teCategory == TECategory_LIGHTMAKEUP) && _makeupType == 1){
        _currentUIProperty.propertyList[_selectedIndex].sdkParam.extraInfo.makeupLutStrength = [NSString stringWithFormat:@"%f",slider.value];
    }else{
        _currentUIProperty.propertyList[_selectedIndex].sdkParam.effectValue = slider.value;
        if (slider.value != 0) {
        }
    }
    [self.beautyProcess updateBeautyEffect:_currentUIProperty.propertyList[_selectedIndex]];
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

-(UIView *)rightResetView{
    if(!_rightResetView){
        _rightResetView =[self rightView];
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetClick)];
        [_rightResetView addGestureRecognizer:tapGesture];
    }
    return _rightResetView;
}

-(NSMutableArray *)titleBtns{
    if(!_titleBtns){
        _titleBtns = [[NSMutableArray alloc] init];
    }
    return _titleBtns;
}

-(UIView *)moreView{
    if(!_moreView){
        _moreView =[self getMoreView:[[TEUIConfig shareInstance] localizedString:@"more_btn_txt"] imageName:@"more"];
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moreClick)];
        [_moreView addGestureRecognizer:tapGesture];
    }
    return _moreView;
}

-(UIView *)rightView{
    UIView *rightView = [[UIView alloc] init];
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView setImage:[[TEUIConfig shareInstance] imageNamed:@"reset"]];
    [rightView addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(24);
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

-(UIView *)buildMoreView{
    UIView *rightView = [[UIView alloc] init];
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView setImage:[[TEUIConfig shareInstance] imageNamed:@"more"]];
    [rightView addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(16);
        make.left.mas_equalTo(rightView);
        make.centerY.mas_equalTo(rightView.mas_centerY);
    }];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = [[TEUIConfig shareInstance] localizedString:@"more_btn_txt"];
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

-(UIView *)getMoreView:(NSString *)text imageName:(NSString *)imageName{
    UIView *resetView = [[UIView alloc] init];
    resetView.frame = CGRectMake(0, 0,beautyCollectionItemWidth, beautyCollectionItemHeight);
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView setImage:[[TEUIConfig shareInstance] imageNamed:imageName]];
    [resetView addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(54);
        make.top.mas_equalTo(resetView).mas_offset(4);
        make.centerX.mas_equalTo(resetView.mas_centerX);
    }];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    [label setFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:[TEUtils isCurrentLanguageHans] ? 12 : 8.5]];
    [resetView addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(beautyCollectionItemWidth);
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

- (void)setupGestureRecognizer {
    self.selfTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(coverViewClick)];
    [self addGestureRecognizer:self.selfTapGesture];
    self.selfTapGesture.delegate = self;
    self.userInteractionEnabled = YES;
}

//系统自动调用
- (void)removeTapGesture {
    if (self.selfTapGesture) {
        [self removeGestureRecognizer:self.selfTapGesture];
        self.selfTapGesture = nil;
    }
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *touchedView = touch.view;
    
    while (touchedView) {
        if ([touchedView isKindOfClass:[UICollectionViewCell class]]) {
            // 点击了 UICollectionViewCell，返回 NO
            return NO;
        }
        if (touchedView == self.blackView  || touchedView == self.scrollView) {
            // 点击的是 blackView || scrollView本身，返回 NO
            return NO;
        }
        // 如果 parent 是 blackView || scrollView ,则当前 touchedView 是 blackView || scrollView 的子视图，返回 YES
        if (touchedView.superview == self.blackView || touchedView.superview ==self.scrollView) {
            return YES;
        }
        touchedView = touchedView.superview;
    }
    
    // 遍历结束，没有遇到黑色视图或者cell，空白区域返回 YES
    return YES;
}

#pragma mark -展开更多按钮之后，点击屏幕返回
- (void)coverViewClick{
    if (!_moreClicked) {
        return;
    }
    [self removeTapGesture];
    _moreClicked = NO;
    isShowGridLayout=NO;
    [self setMoreClick];
    
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(beautyCollectionHeight);
    }];
    [self.blackView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.mas_width);
        make.left.mas_equalTo(self.mas_left);
        make.height.mas_equalTo(190);
        make.bottom.mas_equalTo(self.mas_bottom);
    }];
    [self.beautyCollection mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.mas_left).mas_offset(20);  // 左边缘距父视图左边缘20
        make.right.mas_equalTo(self.mas_right).offset(-70);   // 右边缘距父视图右边缘70
        make.bottom.mas_equalTo(self.blackView.mas_bottom).mas_offset(-50); // 底部对齐到 blackView 底部向上20
        make.height.mas_equalTo(beautyCollectionItemHeight); // 固定高度
    }];

    [self switchCollectionViewDirection];
    if([self.delegate respondsToSelector:@selector(moreClicked:)]){
        [self.delegate moreClicked:NO];
    }
    
    [self addTabButtons:NO];
}

#pragma mark - 更多按钮点击事件
- (void)moreClick{
    _moreClicked = YES;
    isShowGridLayout=YES;
    [self setupGestureRecognizer];
    [self setMoreClick];
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(ScreenHeight);
    }];
    [self.blackView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.mas_width);
        make.left.mas_equalTo(self.mas_left);
        make.height.mas_equalTo(360);
        make.bottom.mas_equalTo(self.mas_bottom);
    }];
    
    [self.beautyCollection mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.mas_width).mas_offset(-40);
        make.left.mas_equalTo(self.mas_left).mas_offset(20);
        make.top.mas_equalTo(self.hLineView.mas_bottom).mas_offset(10);
        make.height.mas_equalTo(230);
    }];
    

    [self switchCollectionViewDirection];
    if([self.delegate respondsToSelector:@selector(moreClicked:)]){
        [self.delegate moreClicked:YES];
    }
    
    [self addMoreTitles];
    [self addTabButtons:NO];
}

-(void)addMoreTitles{
    if(_moreUIPropertyList){
        [_moreUIPropertyList removeAllObjects];
    }
    for(TEUIProperty *mode in self.currentUIPropertyList){
        if(mode.isShowGridLayout){
            [_moreUIPropertyList addObject:mode];
        }
    }
}

#pragma mark - 点击更多按钮之后切换垂直或者水平滚动方向
- (void)switchCollectionViewDirection {
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.beautyCollection.collectionViewLayout;
    if(isShowGridLayout){
        layout.scrollDirection = UICollectionViewScrollDirectionVertical; // 改为竖直方向
    }else{
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal; // 改为横向
    }
    [self.beautyCollection.collectionViewLayout invalidateLayout];
}

- (void)setMoreClick{
    if (_moreClicked) {
        _moreView.hidden = YES;
    }else{
        _moreView.hidden = NO;
    }
}

#pragma mark - 重置功能
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
        [self performFullReset];
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

- (void)performFullReset{
    if(isShowGridLayout){
        [self coverViewClick];
        [self.beautyCollection mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self.mas_width);
            make.left.mas_equalTo(self.mas_left);
            make.bottom.mas_equalTo(self.blackView.mas_bottom).mas_offset(-50); // 底部对齐到 blackView 底部向上-50
            make.height.mas_equalTo(beautyCollectionItemHeight); // 固定高度
        }];
    }else{
        [self.beautyCollection mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self.mas_width);
            make.left.mas_equalTo(self.mas_left);
            make.bottom.mas_equalTo(self.blackView.mas_bottom).mas_offset(-50); // 底部对齐到 blackView 底部向上-50
            make.height.mas_equalTo(beautyCollectionItemHeight); // 固定高度
        }];
    }
    
    self.moreView.hidden =YES;
    isShowGridLayout=NO;

    [self.tePanelDataProvider clearData];
    [self initData];
    
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(beautyCollectionHeight);
    }];
    
    [self.blackView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.mas_width);
        make.left.mas_equalTo(self.mas_left);
        make.height.mas_equalTo(190);
        make.bottom.mas_equalTo(self.mas_bottom);
    }];
    
    [self switchCollectionViewDirection];
    [self addTabButtons:YES];
    [self setSubMenu:NO];
    
    [self.beautyProcess resetBeauty];
    [self.beautyCollection reloadData];
    self.makeupOrLut.hidden = YES;
    self.teSlider.hidden = YES;
    [self.beautyProcess clearBeauty:[self.teBeautyKit getInUseSDKParamList]];
    [self setDefaultBeauty];
}

- (void)setDefaultBeauty{
    [self.beautyProcess setDefaultBeauty];
}

- (int)handleMediaAtPath:(NSString *)path{
    return [self.beautyProcess handleMediaAtPath:path];
}


-(void)openImagePicker{
    if ([self.delegate  respondsToSelector:@selector(onCustomSegBtnClick)]) {
        [self.delegate onCustomSegBtnClick];//获取客户自己创建的图片选择器，必须继承UINavigationController
    }else{
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        //资源类型为图片库
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.mediaTypes =@[(NSString*)kUTTypeMovie, (NSString*)kUTTypeImage];
        picker.delegate = self;
        //设置选择后的图片可被编辑
        picker.allowsEditing = NO;
        [[self getControllerFromView:self] presentViewController:picker animated:YES completion:nil];
    }
}

- (void)showLoading{
    if(!_isShowLoading){
        return;
    }
    _isShowLoading = YES;
    UIViewController *curViewController = [self getControllerFromView:self];
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
    _isShowLoading = NO;
}

- (void)isShowCompareBtn:(BOOL)isShow{
    self.compareButton.hidden = !isShow;
    _showCompareBtn = isShow;
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
    [self resetBeautyData:self.currentUIPropertyList targetData:effectList];
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.beautyCollection reloadData];
    });
}

- (void)resetBeautyData:(NSMutableArray<TEUIProperty *>*)uiPropertyList targetData:(NSMutableArray<TESDKParam *>*)targetData{
    if (uiPropertyList.count == 0 || targetData.count == 0) {
        return;
    }
    for (TEUIProperty *uiproperty in uiPropertyList) {
        if (uiproperty.propertyList.count > 0) {
            [self resetBeautyData:uiproperty.propertyList targetData:targetData];
        }else{
            for (TESDKParam *sdkparam in targetData) {
                if ([sdkparam.effectName isEqualToString:uiproperty.sdkParam.effectName]) {
                    uiproperty.sdkParam.effectValue = sdkparam.effectValue;
                }else{
                    uiproperty.uiState = TEUIState_INIT;
                }
            }
        }
    }
}



- (void)setEnhancedMode:(BOOL)enhancedMode{
    _enhancedMode = enhancedMode;
    if(_enhancedMode){
        [self.teBeautyKit enableEnhancedMode:YES];
    }
    self.beautyProcess.enhancedMode=enhancedMode;
}

- (void)setUIState:(NSArray<TEUIProperty *>*)propertyList uiState:(int)uiState {
    for (TEUIProperty *property in propertyList) {
        property.uiState = uiState;
        [self setUIState:property.propertyList uiState:uiState];
    }
}

- (void)setCurrentUIProperty:(TEUIProperty *)currentUIProperty{
    if(_currentUIProperty!=currentUIProperty){
        _currentUIProperty=currentUIProperty;
        self.beautyProcess.currentUIProperty=currentUIProperty;
    }
}

-(void)setTePanelDataProvider:(TEPanelDataProvider *)tePanelDataProvider{
    if(_tePanelDataProvider != tePanelDataProvider){
        _tePanelDataProvider = tePanelDataProvider;
        self.beautyProcess.tePanelDataProvider = tePanelDataProvider;
    }
}

-(void)setCurrentUIPropertyList:(NSMutableArray<TEUIProperty *> *)currentUIPropertyList{
    if(self.currentUIPropertyList != currentUIPropertyList){
        _currentUIPropertyList = currentUIPropertyList;
        self.beautyProcess.currentUIPropertyList=currentUIPropertyList;
    }
}


#pragma mark - 查找互斥项
- (NSArray<NSString *> *)searchMutualExclusion:(TEUIProperty *)selectedProperty {
    NSString *effectName = selectedProperty.sdkParam.effectName;
    NSArray *results;
    for (NSArray *exclusionArray in _tePanelDataProvider.exclusionGroup) {
        //确定当前效果在哪个分组，只跟同组的效果互斥
        if ([exclusionArray containsObject:effectName]) {
            results = exclusionArray;
            break;
        }
    }
    return results;
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

#pragma mark - 子模型点击事件
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
                  [_abilityType isEqualToString:TEUI_LIGHT_MOTION] ||
                  [_abilityType isEqualToString:TEUI_MOTION_GESTURE] ||
                  [_abilityType isEqualToString:TEUI_MOTION_CAMERA_MOVE] ||
                  [_abilityType isEqualToString:TEUI_SEGMENTATION] ||
                  [_abilityType isEqualToString:TEUI_LIGHT_MAKEUP]
            ){
            [self setUIState:self.currentUIPropertyList uiState:TEUIState_INIT];
        }else if ([_abilityType isEqualToString:TEUI_LUT]){
            for (TEUIProperty *property in _currentUIProperty.propertyList) {
                property.uiState = TEUIState_INIT;
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
                if ([[self searchMutualExclusion:property] containsObject:_currentUIProperty.propertyList[indexPath.row].sdkParam.effectName]) {
                    property.uiState = TEUIState_INIT;
                }
            }
            
        }
        _currentUIProperty.propertyList[indexPath.row].uiState = TEUIState_CHECKED_AND_IN_USE;
        if(_currentUIProperty.propertyList[indexPath.row].sdkParam.numericalType){
            _teSlider.hidden = NO;
            YTBeautyPropertyInfo *propertyInfo = [self.teBeautyKit.xmagicApi getConfigPropertyWithName:_currentUIProperty.propertyList[indexPath.row].sdkParam.effectName];
            if(propertyInfo != nil){
                _teSlider.minimumValue = [propertyInfo.minValue intValue];
                _teSlider.maximumValue = [propertyInfo.maxValue intValue];
            }else{
                _teSlider.minimumValue = 0;
                _teSlider.maximumValue = 100;
            }
            _teSlider.value = _currentUIProperty.propertyList[indexPath.row].sdkParam.effectValue;
            
            if((_currentUIProperty.teCategory == TECategory_MAKEUP || _currentUIProperty.teCategory == TECategory_LIGHTMAKEUP)&& _currentUIProperty.propertyList[indexPath.row].sdkParam.extraInfo.makeupLutStrength != nil){
                self.makeupOrLut.hidden = NO;
                if(self.makeupType == 1){
                    self.teSlider.value = [_currentUIProperty.propertyList[indexPath.row].sdkParam.extraInfo.makeupLutStrength intValue];
                }
                [self.teSlider mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.left.mas_equalTo(self).mas_offset(102);
                    make.right.mas_equalTo(self).mas_offset(-45);
                    make.centerY.mas_equalTo(self.compareButton.mas_centerY);
                }];
            }else{
                self.makeupOrLut.hidden = YES;
                [self.teSlider mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.left.mas_equalTo(self).mas_offset(10);
                    make.right.mas_equalTo(self).mas_offset(-45);
                    make.centerY.mas_equalTo(self.compareButton.mas_centerY);
                }];
            }
        }else{
            _teSlider.hidden = YES;
            self.makeupOrLut.hidden = YES;
        }
        _curProperty=_currentUIProperty.propertyList[indexPath.row];
        [self teSetLastUIProperty:YES];
        [self.beautyProcess updateBeautyEffect:_curProperty];
        if([self.delegate respondsToSelector:@selector(selectEffect:)]){
            [self.delegate selectEffect:_curProperty];
        }
        [self.beautyCollection reloadData];
    }else{
        _teSlider.hidden = YES;
        _makeupOrLut.hidden = YES;
        self.currentUIProperty = _currentUIProperty.propertyList[indexPath.row];
        [self teSetLastUIProperty:NO];
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

-(void)teSetLastUIProperty:(BOOL)flag{
    if(self.currentUIProperty.teCategory == self.lastUIProperty.teCategory){
        self.lastUIProperty.uiState = flag?TEUIState_IN_USE:TEUIState_CHECKED_AND_IN_USE;
    }else{
        self.lastUIProperty=nil;
    }
}

#pragma mark - delegate

-(void)beautyCollectionRreloadData{
    [self.beautyCollection reloadData];
}

-(void)teSliderIsHidden{
    _teSlider.hidden = YES;
}

-(void)teShowLoading{
    [self showLoading];
}

-(void)TEDownloaderProgressBlock:(CGFloat)progress{
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(self) strongSelf = self;
        strongSelf.showProgress = progress * 100;
        strongSelf.processLabel.text = [NSString stringWithFormat:@"%@%d%%",[[TEUIConfig shareInstance] localizedString:@"downloading"],strongSelf.showProgress];
        if (strongSelf.showProgress == 100) {
            strongSelf.showProgress = 0;
            strongSelf.processLabel.text = @"";
        }
    });
}

-(void)teDismissLoading{
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(self) strongSelf = self;
        [strongSelf dismissLoading];
    });
}

-(void)teOpenImagePicker{
    [self openImagePicker];
}

-(void)teGreenscreenAlert{
    [self greenscreenAlert];
}


#pragma mark - 打开相册
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    // 移除相册界面
       [picker.view removeFromSuperview];
       // 获取文件类型:
       NSString *mediaType = info[UIImagePickerControllerMediaType];
       if ([mediaType isEqualToString:(NSString*)kUTTypeImage]) {
           // 用户选的文件为图片类型(kUTTypeImage)
           UIImage *image = info[UIImagePickerControllerOriginalImage];
           [self.beautyProcess imagePickerFinish:image picker:picker];
       }else if([mediaType isEqualToString:(NSString*)kUTTypeMovie]){
           NSURL *sourceURL = [info objectForKey:UIImagePickerControllerMediaURL];
           if(sourceURL){
               __weak typeof(self) weakSelf = self; // 使用 weakSelf 避免循环引用
               [self.beautyProcess moviePickerFinish:sourceURL picker:picker completionHandler:^(BOOL success, NSError * _Nullable error, NSInteger timeOffset) {
                   __strong typeof(weakSelf) strongSelf = weakSelf; // 在 block 内部使用 strongSelf 确保 self 存在
                   if (!strongSelf) {
                       return; // 如果 self 已经被释放，直接返回
                   }
                   [strongSelf updateSegmentationUI:success error:error];
               }];
           }
       }
}


-(void)greenscreenAlert{
    if ([self.delegate  respondsToSelector:@selector(onGreenscreenItemClick)]) {
        [self.delegate onGreenscreenItemClick];
    }else {
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
}


- (void)updateSegmentationUI:(BOOL)success error:(NSError *)error {
    __weak typeof(self) weakSelf = self; // 使用 weakSelf 避免循环引用
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf; // 在 block 内部使用 strongSelf 确保 self 存在
        if (!strongSelf) {
            return; // 如果 self 已经被释放，直接返回
        }

        if (!success) {
            [strongSelf showErrorAlert:(int)error.code];
        }
    });
}
- (void)showErrorAlert:(int)errorCode{
    if (errorCode == 0) {
        return;
    }
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


- (void)dismissAlert:(UIAlertController *)alert{
    [alert dismissViewControllerAnimated:YES completion:nil];
}

// 取消图片选择回调
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [[self getControllerFromView:self] dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"取消");
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
