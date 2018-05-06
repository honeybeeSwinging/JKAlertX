//
//  JKAlertView.m
//  TestVideoAndPicture
//
//  Created by albert on 2017/4/18.
//  Copyright © 2017年 安永博. All rights reserved.
//

#import "JKAlertView.h"
#import "JKAlertTableViewCell.h"
#import "JKAlertCollectionViewCell.h"
#import "JKAlertTextView.h"

/** 屏幕宽度 */
#define JKAlertScreenW [UIScreen mainScreen].bounds.size.width
/** 屏幕高度 */
#define JKAlertScreenH [UIScreen mainScreen].bounds.size.height
/** 屏幕scale */
#define JKAlertScreenScale [UIScreen mainScreen].scale

#define JKAlertIsIphoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

#define JKAlertCurrentHomeIndicatorHeight (JKAlertIsIphoneX ? 34: 0)

#define JKAlertAdjustHomeIndicatorHeight (AutoAdjustHomeIndicator ? JKAlertCurrentHomeIndicatorHeight : 0)

#define JKAlertRowHeight ((JKAlertScreenW > 321) ? 53 : 46)

#define JKAlertTextContainerViewMaxH (JKAlertScreenH - 100 - JKAlertScrollViewMaxH)
#define JKAlertPlainViewMaxH (JKAlertScreenH - 100)
#define JKAlertSheetMaxH (JKAlertScreenH * 0.85)

static CGFloat    const JKAlertMinTitleLabelH = (22);
static CGFloat    const JKAlertMinMessageLabelH = (17);
static CGFloat    const JKAlertScrollViewMaxH = 176; // (JKAlertButtonH * 4)

static CGFloat    const JKAlertButtonH = 46;
static NSInteger  const JKAlertPlainButtonBeginTag = 100;
static NSString * const JKAlertDismissNotification = @"JKAlertDismissNotification";

static CGFloat    const JKAlertSheetTitleMargin = 6;

@interface JKAlertView () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, JKAlertViewProtocol>
{
    CGFloat TBMargin;
    CGFloat textContainerViewCurrentMaxH_;
    BOOL    _enableDeallocLog;
    CGFloat _iPhoneXLandscapeTextMargin;
    
    CGFloat JKAlertTitleMessageMargin;
    
    /** 分隔线宽度或高度 */
    CGFloat JKAlertSeparatorLineWH;
    
    CGFloat CancelMargin;
    CGFloat PlainViewWidth;
    
    /** 是否自动适配 iPhone X homeIndicator */
    BOOL AutoAdjustHomeIndicator;
    
    BOOL Showed;
    
    UIView  *_backGroundView;
    
    UIColor *titleTextColor;
    UIFont  *titleFont;
    
    UIColor *messageTextColor;
    UIFont  *messageFont;
}
/** customSuperView */
@property (nonatomic, weak) UIView *customSuperView;

/** contentView */
@property (nonatomic, weak) UIView *contentView;

/** sheetContainerView */
@property (nonatomic, weak) UIView *sheetContainerView;

/** sheet样式的背景view */
@property (nonatomic, strong) UIView *backGroundView;

/** tableView */
@property (nonatomic, weak) UITableView *tableView;

/** flowlayout */
@property (nonatomic, strong) UICollectionViewFlowLayout *flowlayout;

/** flowlayout2 */
@property (nonatomic, strong) UICollectionViewFlowLayout *flowlayout2;

/** collectionView */
@property (nonatomic, weak) UICollectionView *collectionView;

/** collectionView2 */
@property (nonatomic, weak) UICollectionView *collectionView2;

/** collection样式添加自定义的titleView */
@property (nonatomic, weak) UIView *customCollectionTitleView;

/** pageControl */
@property (nonatomic, weak) UIPageControl *pageControl;

/** cancelButton */
@property (nonatomic, weak) UIButton *cancelButton;

/** collectionButton */
@property (nonatomic, weak) UIButton *collectionButton;

/** 最底层背景按钮 */
@property (nonatomic, weak) UIButton *dismissButton;

/** actions */
@property (nonatomic, strong) NSMutableArray *actions;

/** actions2 */
@property (nonatomic, strong) NSMutableArray *actions2;

/** 样式 */
@property (nonatomic, assign) JKAlertStyle alertStyle;

/** 标题 */
@property (nonatomic, copy) NSString *alertTitle;

/** 富文本标题 */
@property (nonatomic, copy) NSAttributedString *alertAttributedTitle;

/** 提示信息 */
@property (nonatomic, copy) NSString *message;

/** 富文本提示信息 */
@property (nonatomic, copy) NSAttributedString *attributedMessage;

/** plainView */
@property (nonatomic, weak) UIView *plainView;

/** plain样式添加自定义的titleView */
@property (nonatomic, weak) UIView *customPlainTitleView;

/** collection样式添加自定义的titleView的父视图 */
@property (nonatomic, weak) UIScrollView *customPlainTitleScrollView;

/** customHUD */
@property (nonatomic, weak) UIView *customHUD;

/** textContainerView */
@property (nonatomic, weak) UIView *textContainerView;

/** 分隔线 */
@property (nonatomic, weak) CALayer *bottomLineLayer;

/** titleTextView */
@property (nonatomic, weak) JKAlertTextView *titleTextView;

/** messageTextView */
@property (nonatomic, weak) JKAlertTextView *messageTextView;

/** scrollView */
@property (nonatomic, weak) UIScrollView *scrollView;

/** messageLabel */
@property (nonatomic, weak) UIView *titleContentView;

/** 消失后的回调 */
@property (nonatomic, copy) void (^dismissComplete)(void);

/** 显示动画完成的回调 */
@property (nonatomic, copy) void (^showAnimationComplete)(JKAlertView *view);

@end

@implementation JKAlertView

+ (instancetype)alertViewWithTitle:(NSString *)title message:(NSString *)message style:(JKAlertStyle)alertStyle{
    
    if (alertStyle == JKAlertStyleNone) {
        
        return nil;
    }
    
    JKAlertView *alertView = [[JKAlertView alloc] init];
    
    alertView.alertStyle = alertStyle;
    alertView.alertTitle = [title copy];
    alertView.message    = [message copy];
    
    return alertView;
}

/** 链式实例化 */
+ (JKAlertView *(^)(NSString *title, NSString *message, JKAlertStyle style))alertView{
    
    return ^(NSString *title, NSString *message, JKAlertStyle style){
        
        return [JKAlertView alertViewWithTitle:title message:message style:style];
    };
}

+ (instancetype)alertViewWithAttributedTitle:(NSAttributedString *)attributedTitle attributedMessage:(NSAttributedString *)attributedMessage style:(JKAlertStyle)alertStyle{
    
    if (alertStyle == JKAlertStyleNone) {
        
        return nil;
    }
    
    JKAlertView *alertView = [[JKAlertView alloc] init];
    
    alertView.alertStyle = alertStyle;
    alertView.alertAttributedTitle = [attributedTitle copy];
    alertView.attributedMessage = [attributedMessage copy];
    
    return alertView;
}

/** 链式实例化 */
+ (JKAlertView *(^)(NSAttributedString *attributedTitle, NSAttributedString *attributedMessage, JKAlertStyle style))alertViewAttributed{
    
    return ^(NSAttributedString *attributedTitle, NSAttributedString *attributedMessage, JKAlertStyle style){
        
        return [JKAlertView alertViewWithAttributedTitle:attributedTitle attributedMessage:attributedMessage style:style];
    };
}

/** 显示文字HUD */
+ (JKAlertView *(^)(NSString *title))showHUDWithTitle{
    
    return ^(NSString *title){
        
        JKAlertView *alertView = nil;
        
        if (!title) {
            
            return alertView;
        }
        
        alertView = [JKAlertView alertViewWithTitle:title message:nil style:(JKAlertStyleHUD)];
        
        [alertView show];
        
        return alertView;
    };
}

/** 显示富文本HUD */
+ (JKAlertView *(^)(NSAttributedString *attributedTitle))showHUDWithAttributedTitle{
    
    return ^(NSAttributedString *attributedTitle){
        
        JKAlertView *alertView = nil;
        
        if (!attributedTitle) {
            
            return alertView;
        }
        
        alertView = [JKAlertView alertViewWithAttributedTitle:attributedTitle attributedMessage:nil style:(JKAlertStyleHUD)];
        
        [alertView show];
        
        return alertView;
    };
}

/**
 * 显示自定义HUD
 * 注意使用点语法调用，否则莫名报错 JKAlertView.showCustomHUD
 * customHUD尺寸将完全由自定义控制，默认显示在屏幕中间
 * 注意自己计算好自定义HUD的size，以避免横竖屏出现问题
 */
+ (JKAlertView *(^)(UIView *(^customHUD)(void)))showCustomHUD{
    
    return ^(UIView *(^customHUD)(void)){
        
        JKAlertView *alertView = nil;
        
        if (!customHUD) {

            return alertView;
        }
        
        UIView *customView = customHUD();
        
        alertView = [[JKAlertView alloc] init];
        
        alertView.customHUD = customView;
        
        [alertView show];
        
        return alertView;
    };
}

/** 移除当前所有的JKAlertView */
+ (void(^)(void))dismiss{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:JKAlertDismissNotification object:nil];
    
    return ^{};
}

#pragma mark - 懒加载------------------------
- (NSMutableArray *)actions{
    if (!_actions) {
        _actions = [NSMutableArray array];
    }
    return _actions;
}

- (NSMutableArray *)actions2{
    if (!_actions2) {
        _actions2 = [NSMutableArray array];
    }
    return _actions2;
}

- (UIView *)textContainerView{
    if (!_textContainerView) {
        UIView *textContainerView = [[UIView alloc] init];
        [self addSubview:textContainerView];
        _textContainerView = textContainerView;
    }
    return _textContainerView;
}

- (JKAlertTextView *)titleTextView{
    if (!_titleTextView) {
        JKAlertTextView *titleLabel = [[JKAlertTextView alloc] init];
        titleLabel.textColor = self.alertStyle == JKAlertStylePlain ? [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1] : [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:1];
        titleLabel.font = self.alertStyle == JKAlertStylePlain ? [UIFont boldSystemFontOfSize:17] : [UIFont systemFontOfSize:17];
        [self addSubview:titleLabel];
        
        _titleTextView = titleLabel;
    }
    return _titleTextView;
}

- (JKAlertTextView *)messageTextView{
    if (!_messageTextView) {
        JKAlertTextView *messageLabel = [[JKAlertTextView alloc] init];
        messageLabel.textColor = self.alertStyle == JKAlertStyleActionSheet ? [UIColor colorWithRed:0.55 green:0.55 blue:0.55 alpha:1] : [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1];
        messageLabel.font = self.alertStyle == JKAlertStylePlain ? [UIFont systemFontOfSize:14] : [UIFont systemFontOfSize:13];
        [self addSubview:messageLabel];
        
        _messageTextView = messageLabel;
    }
    return _messageTextView;
}

- (UIScrollView *)scrollView{
    if (!_scrollView) {
        UIScrollView *scrollView = [[UIScrollView alloc] init];
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.scrollsToTop = NO;
        [self addSubview:scrollView];
        
        SEL selector = NSSelectorFromString(@"setContentInsetAdjustmentBehavior:");
        
        if ([scrollView respondsToSelector:selector]) {
            
            IMP imp = [scrollView methodForSelector:selector];
            void (*func)(id, SEL, NSInteger) = (void *)imp;
            func(scrollView, selector, 2);
            
            // [tbView performSelector:@selector(setContentInsetAdjustmentBehavior:) withObject:@(2)];
        }
        
        _scrollView = scrollView;
    }
    return _scrollView;
}

- (UIView *)backGroundView{
    if (!_backGroundView) {
        UIToolbar *toolbar = [[UIToolbar alloc] init];
        toolbar.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1];
        self.backGroundView = toolbar;
    }
    return _backGroundView;
}

- (UIView *)sheetContainerView{
    if (!_sheetContainerView) {
        UIView *sheetContainerView = [[UIView alloc] init];
        sheetContainerView.backgroundColor = [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:0.7];
        [self.contentView addSubview:sheetContainerView];
        _sheetContainerView = sheetContainerView;
        
        // 背景
        [self backGroundView];
    }
    return _sheetContainerView;
}

- (UITableView *)tableView{
    if (!_tableView) {
        
        // 分隔线
        CALayer *hline = [CALayer layer];
        hline.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
        [self.textContainerView.layer addSublayer:hline];
         _bottomLineLayer = hline;
        
//        NSString *hVF = [NSString stringWithFormat:@"H:|-%d-[bottomLineView]-%d-|", (int)_iPhoneXLandscapeTextMargin, (int)_iPhoneXLandscapeTextMargin];
//
//        bottomLineView.translatesAutoresizingMaskIntoConstraints = NO;
//        NSArray *bottomLineViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:hVF options:0 metrics:nil views:@{@"bottomLineView" : bottomLineView}];
//        [self.textContainerView addConstraints:bottomLineViewCons1];
//
//        NSArray *bottomLineViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomLineView(0.5)]-0-|" options:0 metrics:nil views:@{@"bottomLineView" : bottomLineView}];
//        [self.textContainerView addConstraints:bottomLineViewCons2];
        
        // title和message的容器view
        self.textContainerView.backgroundColor = [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:0.7];
        [self.sheetContainerView addSubview:self.textContainerView];
        
        [self.textContainerView insertSubview:self.scrollView atIndex:0];
        
        [self.scrollView addSubview:self.titleTextView];
        
        [self.scrollView addSubview:self.messageTextView];
        
        UITableView *tbView = [[UITableView alloc] initWithFrame:CGRectZero style:(UITableViewStyleGrouped)];
        
        tbView.dataSource = self;
        tbView.delegate = self;
        
        tbView.scrollsToTop = NO;
        tbView.scrollEnabled = NO;
        tbView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        tbView.contentInset = UIEdgeInsetsMake(0, 0, JKAlertAdjustHomeIndicatorHeight, 0);
        tbView.scrollIndicatorInsets = tbView.contentInset;
        
        tbView.backgroundColor = nil;
        
        [tbView registerClass:[JKAlertTableViewCell class] forCellReuseIdentifier:NSStringFromClass([JKAlertTableViewCell class])];
        
        [_sheetContainerView addSubview:tbView];
        [_sheetContainerView insertSubview:tbView belowSubview:self.textContainerView];
        
        tbView.rowHeight = JKAlertRowHeight;
        tbView.sectionFooterHeight = 0;
        tbView.sectionHeaderHeight = 0;
        
        tbView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, JKAlertScreenW, CGFLOAT_MIN)];
        tbView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, JKAlertScreenW, CGFLOAT_MIN)];
        
        SEL selector = NSSelectorFromString(@"setContentInsetAdjustmentBehavior:");
        
        if ([tbView respondsToSelector:selector]) {
            
            IMP imp = [tbView methodForSelector:selector];
            void (*func)(id, SEL, NSInteger) = (void *)imp;
            func(tbView, selector, 2);
            
            // [tbView performSelector:@selector(setContentInsetAdjustmentBehavior:) withObject:@(2)];
        }
        
        //        if (@available(iOS 11.0, *)) {
        //            tbView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        //        }
        
        _tableView = tbView;
    }
    return _tableView;
}

- (UIButton *)cancelButton{
    if (!_cancelButton) {
        
        UIButton *cancelButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [self.scrollView addSubview:cancelButton];
        
        cancelButton.backgroundColor = [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:0.7];
        cancelButton.titleLabel.font = [UIFont systemFontOfSize:17];
        [cancelButton setTitleColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1] forState:(UIControlStateNormal)];
        [cancelButton addTarget:self action:@selector(dismiss) forControlEvents:(UIControlEventTouchUpInside)];
        
        [cancelButton setBackgroundImage:JKAlertCreateImageWithColor([UIColor colorWithRed:217.0/255.0 green:217.0/255.0 blue:217.0/255.0 alpha:1], 1, 1, 0) forState:(UIControlStateHighlighted)];
        
        _cancelButton = cancelButton;
    }
    return _cancelButton;
}

- (UIButton *)collectionButton{
    if (!_collectionButton) {
        UIButton *collectionButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
        collectionButton.backgroundColor = [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:0.7];
        [self.scrollView addSubview:collectionButton];
        collectionButton.titleLabel.font = [UIFont systemFontOfSize:17];
        [collectionButton setTitleColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1] forState:(UIControlStateNormal)];
        [collectionButton addTarget:self action:@selector(collectionButtonClick) forControlEvents:(UIControlEventTouchUpInside)];
        [collectionButton setBackgroundImage:JKAlertCreateImageWithColor([UIColor colorWithRed:217.0/255.0 green:217.0/255.0 blue:217.0/255.0 alpha:1], 1, 1, 0) forState:(UIControlStateHighlighted)];
        
        _collectionButton = collectionButton;
    }
    return _collectionButton;
}

- (UIPageControl *)pageControl{
    if (!_pageControl) {
        UIPageControl *pageControl = [[UIPageControl alloc] init];
        pageControl.backgroundColor = [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:0.7];
        pageControl.pageIndicatorTintColor = [UIColor colorWithRed:217.0/255.0 green:217.0/255.0 blue:217.0/255.0 alpha:1];
        pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1];
        pageControl.userInteractionEnabled = NO;
        
        [self.scrollView addSubview:pageControl];
        
        _pageControl = pageControl;
    }
    return _pageControl;
}

- (UICollectionView *)collectionView{
    if (!_collectionView) {
        [self.sheetContainerView insertSubview:self.scrollView atIndex:1];
        self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, JKAlertAdjustHomeIndicatorHeight, 0);
        self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *scrollViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[scrollView]-0-|" options:0 metrics:nil views:@{@"scrollView" : self.scrollView}];
        [self addConstraints:scrollViewCons1];
        
        NSArray *scrollViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[scrollView]-0-|" options:0 metrics:nil views:@{@"scrollView" : self.scrollView}];
        [self addConstraints:scrollViewCons2];
        
        // title和message的容器view
        self.textContainerView.backgroundColor = [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:0.7];
        [self.scrollView addSubview:self.textContainerView];
        
        [self.textContainerView addSubview:self.titleTextView];
        
        UICollectionViewFlowLayout *flowlayout = [[UICollectionViewFlowLayout alloc] init];
        flowlayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _flowlayout = flowlayout;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.textContainerView.frame), JKAlertScreenW, 80) collectionViewLayout:flowlayout];
        collectionView.backgroundColor = [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:0.7];
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        
        collectionView.dataSource = self;
        collectionView.delegate = self;
        
        collectionView.scrollsToTop = NO;
        
        [collectionView registerClass:[JKAlertCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([JKAlertCollectionViewCell class])];
        
        SEL selector = NSSelectorFromString(@"setContentInsetAdjustmentBehavior:");
        
        if ([collectionView respondsToSelector:selector]) {
            
            IMP imp = [collectionView methodForSelector:selector];
            void (*func)(id, SEL, NSInteger) = (void *)imp;
            func(collectionView, selector, 2);
            
            // [tbView performSelector:@selector(setContentInsetAdjustmentBehavior:) withObject:@(2)];
        }
        
        [self.scrollView insertSubview:collectionView belowSubview:self.textContainerView];
        
        [self cancelButton];
        
        _collectionView = collectionView;
    }
    return _collectionView;
}

- (UICollectionView *)collectionView2{
    if (!_collectionView2) {
        
        UICollectionViewFlowLayout *flowlayout = [[UICollectionViewFlowLayout alloc] init];
        flowlayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _flowlayout2 = flowlayout;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_flowlayout2];
        collectionView.backgroundColor = [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:0.7];
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        
        collectionView.dataSource = self;
        collectionView.delegate = self;
        
        collectionView.scrollsToTop = NO;
        
        [collectionView registerClass:[JKAlertCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([JKAlertCollectionViewCell class])];
        
        SEL selector = NSSelectorFromString(@"setContentInsetAdjustmentBehavior:");
        
        if ([collectionView respondsToSelector:selector]) {
            
            IMP imp = [collectionView methodForSelector:selector];
            void (*func)(id, SEL, NSInteger) = (void *)imp;
            func(collectionView, selector, 2);
            
            // [tbView performSelector:@selector(setContentInsetAdjustmentBehavior:) withObject:@(2)];
        }
        
        [self.scrollView addSubview:collectionView];
        
        _collectionView2 = collectionView;
    }
    return _collectionView2;
}

- (UIView *)plainView{
    if (!_plainView) {
        UIView *plainView = [[UIView alloc] init];
        plainView.clipsToBounds = YES;
        plainView.layer.cornerRadius = 8;
        plainView.backgroundColor = [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:0.6];//[UIColor whiteColor];
        plainView.frame = CGRectMake((JKAlertScreenW - PlainViewWidth) * 0.5, (JKAlertScreenH - 200) * 0.5, PlainViewWidth, 200);
        
        //        UIView *titleContentView = [[UIView alloc] init];
        //        titleContentView.backgroundColor = [UIColor whiteColor];
        //        [plainView addSubview:titleContentView];
        //        _titleContentView = titleContentView;
        
        [plainView addSubview:self.textContainerView];
        
        [self.textContainerView addSubview:self.titleTextView];
        
        [self.textContainerView addSubview:self.messageTextView];
        
        self.dismissButton.userInteractionEnabled = NO;
        
        [plainView addSubview:self.scrollView];
        
        [plainView insertSubview:self.scrollView belowSubview:self.textContainerView];
            
        if (_alertStyle == JKAlertStylePlain) {
            
            // 分隔线
            CALayer *hline = [CALayer layer];
            hline.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
            [self.textContainerView.layer addSublayer:hline];
            _bottomLineLayer = hline;
        }
        
        [self addSubview:plainView];
        _plainView = plainView;
        
        // 背景
        [self backGroundView];
    }
    return _plainView;
}

#pragma mark - 初始化------------------------
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initialization];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        [self initialization];
    }
    return self;
}

- (void)initialization{
    
    _HUDHeight = -1;
    _enableDeallocLog = NO;
    _dismissTimeInterval = 1;
    _textViewUserInteractionEnabled = YES;
    _iPhoneXLandscapeTextMargin = ((JKAlertIsIphoneX && JKAlertScreenW > JKAlertScreenH) ? 44 : 0);
    
    TBMargin = 20;
    PlainViewWidth = 290;
    AutoAdjustHomeIndicator = YES;
    JKAlertTitleMessageMargin = 7;
    CancelMargin = ((JKAlertScreenW > 321) ? 7 : 5);
    JKAlertSeparatorLineWH = (1 / [UIScreen mainScreen].scale);
    textContainerViewCurrentMaxH_ = (JKAlertScreenH - 100 - JKAlertButtonH * 4);
    
    self.flowlayoutItemWidth = 76;
    self.textViewLeftRightMargin = 20;
    self.titleTextViewAlignment = NSTextAlignmentCenter;
    self.messageTextViewAlignment = NSTextAlignmentCenter;
    
    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    [self insertSubview:contentView atIndex:0];
    self.contentView = contentView;
    
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *contentViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[contentView]-0-|" options:0 metrics:nil views:@{@"contentView" : contentView}];
    [self addConstraints:contentViewCons1];
    
    NSArray *contentViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[contentView]-0-|" options:0 metrics:nil views:@{@"contentView" : contentView}];
    [self addConstraints:contentViewCons2];
    
    UIButton *dismissButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    dismissButton.backgroundColor = [UIColor clearColor];
    [self.contentView insertSubview:dismissButton atIndex:0];
    self.dismissButton = dismissButton;
    
    dismissButton.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *dismissButtonCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[dismissButton]-0-|" options:0 metrics:nil views:@{@"dismissButton" : dismissButton}];
    [self.contentView addConstraints:dismissButtonCons1];
    
    NSArray *dismissButtonCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[dismissButton]-0-|" options:0 metrics:nil views:@{@"dismissButton" : dismissButton}];
    [self.contentView addConstraints:dismissButtonCons2];
    
    [dismissButton addTarget:self action:@selector(dismiss) forControlEvents:(UIControlEventTouchUpInside)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismiss) name:JKAlertDismissNotification object:nil];
}

- (void)setAlertStyle:(JKAlertStyle)alertStyle{
    _alertStyle = alertStyle;
    
    switch (_alertStyle) {
        case JKAlertStylePlain:
        {
            [self plainView];
        }
            break;
            
        case JKAlertStyleActionSheet:
        {
            [self tableView];
        }
            break;
            
        case JKAlertStyleCollectionSheet:
        {
            CancelMargin = 10;
            
            [self collectionView];
        }
            break;
            
        case JKAlertStyleHUD:
        {
            [self plainView];
        }
            break;
            
        default:
            break;
    }
}

/** 设置默认的取消action，不需要自带的可以自己设置，不可置为nil */
- (void)setCancelAction:(JKAlertAction *)cancelAction{
    
    if (cancelAction == nil) {
        return;
    }
    
    _cancelAction = cancelAction;
}

/**
 * 设置collection的itemSize的宽度
 * 最大不可超过屏幕宽度的一半
 * 注意图片的宽高是设置的宽度-30，即图片在cell中是左右各15的间距
 * 自动计算item之间间距，最小为0，可自己计算该值设置每屏显示个数
 * 默认的高度是宽度-6，暂不支持自定义高度
 */
- (void)setFlowlayoutItemWidth:(CGFloat)flowlayoutItemWidth{
    
    _flowlayoutItemWidth = flowlayoutItemWidth > JKAlertScreenW * 0.5 ? JKAlertScreenW * 0.5 : flowlayoutItemWidth;
}

- (void)setCustomHUD:(UIView *)customHUD{
    _customHUD = customHUD;
    
    [self.plainView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [self.plainView addSubview:_customHUD];
    
    [self relayout];
}

- (void)setCustomCollectionTitleView:(UIView *)customCollectionTitleView{
    _customCollectionTitleView = customCollectionTitleView;
    
    if (!_customCollectionTitleView) {
        return;
    }
    
    _titleTextView.hidden = YES;
    _messageTextView.hidden = YES;
    [_textContainerView addSubview:_customCollectionTitleView];
}

- (void)setCustomPlainTitleView:(UIView *)customPlainTitleView{
    _customPlainTitleView = customPlainTitleView;
    
    if (!_customPlainTitleView) {
        return;
    }
    
    if (!_customPlainTitleScrollView) {
        
        UIScrollView *scrollView = [[UIScrollView alloc] init];
        [_textContainerView insertSubview:scrollView atIndex:0];
        _customPlainTitleScrollView = scrollView;
        
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *scrollViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[scrollView]-0-|" options:0 metrics:nil views:@{@"scrollView" : scrollView}];
        [_textContainerView addConstraints:scrollViewCons1];
        
        NSArray *scrollViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[scrollView]-0-|" options:0 metrics:nil views:@{@"scrollView" : scrollView}];
        [_textContainerView addConstraints:scrollViewCons2];
    }
    
    _titleTextView.hidden = YES;
    _messageTextView.hidden = YES;
    
    [_customPlainTitleScrollView addSubview:_customPlainTitleView];
}

- (void)setHUDCenterOffsetY:(CGFloat)HUDCenterOffsetY{
    
    _HUDCenterOffsetY = HUDCenterOffsetY;
        
    _plainView.center = CGPointMake(JKAlertScreenW * 0.5, JKAlertScreenH * 0.5 + _HUDCenterOffsetY);
}

- (void)setHUDHeight:(CGFloat)HUDHeight{
    
    if (_alertStyle != JKAlertStyleHUD) {
        return;
    }
    
    _HUDHeight = HUDHeight;
    
    CGRect rect = _plainView.frame;
    rect.size.height = _HUDHeight >= 0 ? _HUDHeight : _textContainerView.frame.size.height;
    _plainView.frame = rect;
    
    _textContainerView.center = CGPointMake(_plainView.frame.size.width * 0.5, _plainView.frame.size.height * 0.5);
    
    _plainView.center = CGPointMake(JKAlertScreenW * 0.5, JKAlertScreenH * 0.5 + _HUDCenterOffsetY);
}

- (void)setBackGroundView:(UIView *)backGroundView{
    
    if (backGroundView == nil) {
        return;
    }
    
    [_backGroundView removeFromSuperview];
    
    _backGroundView = backGroundView;
    
    [_sheetContainerView insertSubview:_backGroundView atIndex:0];
    [_plainView insertSubview:_backGroundView atIndex:0];
    
    backGroundView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *cons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[sheetBackGroundView]-0-|" options:0 metrics:nil views:@{@"sheetBackGroundView" : backGroundView}];
    [_sheetContainerView addConstraints:cons1];
    [_plainView addConstraints:cons1];
    
    NSArray *cons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[sheetBackGroundView]-0-|" options:0 metrics:nil views:@{@"sheetBackGroundView" : backGroundView}];
    [_sheetContainerView addConstraints:cons2];
    [_plainView addConstraints:cons2];
}

#pragma mark - 链式setter------------------------

/**
 * 设置自定义的父控件
 * 默认添加到keywindow上
 * customSuperView在show之前有效
 * customSuperViewsize最好和屏幕大小一致，否则可能出现问题
 */
- (JKAlertView *(^)(UIView *customSuperView))setCustomSuperView{
    
    return ^(UIView *customSuperView){
        
        self.customSuperView = customSuperView;
        
        return self;
    };
}

/** 设置默认的取消action，不需要自带的可以自己设置，不可置为nil */
- (JKAlertView *(^)(JKAlertAction *action))setCancelAction{
    
    return ^(JKAlertAction *action){
        
        self.cancelAction = action;
        
        return self;
    };
}

/** collection样式默认有一个取消按钮，设置这个可以在取消按钮的上面再添加一个按钮 */
- (JKAlertView *(^)(JKAlertAction *action))setCollectionAction{
    
    return ^(JKAlertAction *action){
        
        self.collectionAction = action;
        
        return self;
    };
}

/**
 * 设置titleTextColor
 * plain默认RGB都为0.1，其它0.35
 */
- (JKAlertView *(^)(UIColor *textColor))setTitleTextColor{
    
    return ^(UIColor *textColor){
        
        self->titleTextColor = textColor;
        
        return self;
    };
}

/**
 * 设置titleTextFont
 * plain默认 bold 17，其它17
 */
- (JKAlertView *(^)(UIFont *font))setTitleTextFont{
    
    return ^(UIFont *font){
        
        self->titleFont = font;
        
        return self;
    };
}

/**
 * 设置messageTextColor
 * plain默认RGB都为0.55，其它0.3
 */
- (JKAlertView *(^)(UIColor *textColor))setMessageTextColor{
    
    return ^(UIColor *textColor){
        
        self->messageTextColor = textColor;
        
        return self;
    };
}

/**
 * 设置messageTextFont
 * plain默认14，其它13
 * action样式在没有title的时候，自动改为15，设置该值后将始终为该值，不自动修改
 */
- (JKAlertView *(^)(UIFont *font))setMessageTextFont{
    
    return ^(UIFont *font){
        
        self->messageFont = font;
        
        return self;
    };
}

/** 设置titleTextViewDelegate */
- (JKAlertView *(^)(id<UITextViewDelegate> delegate))setTitleTextViewDelegate{
    
    return ^(id<UITextViewDelegate> delegate){
        
        self.titleTextViewDelegate = delegate;
        
        return self;
    };
}

/** 设置messageTextViewDelegate */
- (JKAlertView *(^)(id<UITextViewDelegate> delegate))setMessageTextViewDelegate{
    
    return ^(id<UITextViewDelegate> delegate){
        
        self.messageTextViewDelegate = delegate;
        
        return self;
    };
}

/** 设置title和message是否可以响应事件，默认YES 如无必要不建议设置为NO */
- (JKAlertView *(^)(BOOL userInteractionEnabled))setTextViewUserInteractionEnabled{
    
    return ^(BOOL userInteractionEnabled){
        
        self.textViewUserInteractionEnabled = userInteractionEnabled;
        
        return self;
    };
}

/** 设置title和message是否可以选择文字，默认NO */
- (JKAlertView *(^)(BOOL canselectText))setTextViewCanSelectText{
    
    return ^(BOOL canSelectText){
        
        self.textViewCanSelectText = canSelectText;
        
        return self;
    };
}

/** 设置titleTextView的文字水平样式 */
- (JKAlertView *(^)(NSTextAlignment textAlignment))setTitleTextViewAlignment{
    
    return ^(NSTextAlignment textAlignment){
        
        self.titleTextViewAlignment = textAlignment;
        
        return self;
    };
}

/** 设置messageTextView的文字水平样式 */
- (JKAlertView *(^)(NSTextAlignment textAlignment))setMessageTextViewAlignment{
    
    return ^(NSTextAlignment textAlignment){
        
        self.messageTextViewAlignment = textAlignment;
        
        return self;
    };
}

/** 设置title和message的左右间距 默认15 */
- (JKAlertView *(^)(CGFloat margin))setTextViewLeftRightMargin{
    
    return ^(CGFloat margin){
        
        self.textViewLeftRightMargin = margin;
        
        return self;
    };
}

/** 设置title和message的上下间距 默认15 */
- (JKAlertView *(^)(CGFloat margin))setTextViewTopBottomMargin{
    
    return ^(CGFloat margin){
        
        self->TBMargin = margin;
        
        return self;
    };
}

/** 设置colletion样式的底部按钮左右间距 */
- (JKAlertView *(^)(CGFloat margin))setCollectionButtonLeftRightMargin{
    
    return ^(CGFloat margin){
        
        self.collectionButtonLeftRightMargin = margin;
        
        return self;
    };
}

/** 设置action和colletion样式的底部按钮上下间距 不可小于0 */
- (JKAlertView *(^)(CGFloat margin))setBottomButtonMargin{
    
    return ^(CGFloat margin){
        
        self->CancelMargin = margin < 0 ? 0 : margin;
        
        return self;
    };
}

/**
 * 设置plain样式的宽度
 * 默认290
 * 不可小于0，不可大于屏幕宽度
 */
- (JKAlertView *(^)(CGFloat width))setPlainWidth{
    
    return ^(CGFloat width){
        
        self->PlainViewWidth = width < 0 ? 0 : (width > MIN(JKAlertScreenW, JKAlertScreenH) ? MIN(JKAlertScreenW, JKAlertScreenH) : width);
        
        return self;
    };
}

/**
 * 设置是否将两个collection合体
 * 设为YES可让两个collection同步滚动
 * 设置YES时会自动让两个collection的action数量保持一致，即向少的一方添加空的action
 */
- (JKAlertView *(^)(BOOL compoundCollection))setCompoundCollection{
    
    return ^(BOOL compoundCollection){
        
        self.compoundCollection = compoundCollection;
        
        return self;
    };
}

/** 设置collection是否分页 */
- (JKAlertView *(^)(BOOL collectionPagingEnabled))setCollectionPagingEnabled{
    
    return ^(BOOL collectionPagingEnabled){
        
        self.collectionPagingEnabled = collectionPagingEnabled;
        
        return self;
    };
}

/** 设置是否自动适配 iPhone X homeIndicator 默认YES */
- (JKAlertView *(^)(BOOL autoAdjust))setAutoAdjustHomeIndicator{
    
    return ^(BOOL autoAdjust){
        
        self->AutoAdjustHomeIndicator = autoAdjust;
        
        return self;
    };
}

/**
 * 设置是否显示pageControl
 * 如果只有一组collection，则必须设置分页为YES才有效
 * 如果有两组collection，则仅在分页和合体都为YES时才有效
 * 注意自己计算好每页显示的个数相等
 * 可以添加空的action来保证每页显示个数相等
 * JKAlertAction使用类方法初始化时每个参数传nil或者直接自己实例化一个即为空action
 */
- (JKAlertView *(^)(BOOL showPageControl))setShowPageControl{
    
    return ^(BOOL showPageControl){
        
        self.showPageControl = showPageControl;
        
        return self;
    };
}

/**
 * 设置HUD样式dismiss的时间，默认1s
 * 小于等于0表示不自动隐藏
 */
- (JKAlertView *(^)(CGFloat dismissTimeInterval))setDismissTimeInterval{
    
    return ^(CGFloat dismissTimeInterval){
        
        self.dismissTimeInterval = dismissTimeInterval;
        
        return self;
    };
}

/**
 * 设置HUD样式centerY的偏移
 * 正数表示向下偏移，负数表示向上偏移
 */
- (JKAlertView *(^)(CGFloat centerOffsetY))setHUDCenterOffsetY{
    
    return ^(CGFloat centerOffsetY){
        
        self.HUDCenterOffsetY = centerOffsetY;
        
        return self;
    };
}

/**
 * 设置plain样式centerY的偏移
 * 正数表示向下偏移，负数表示向上偏移
 */
- (JKAlertView *(^)(CGFloat centerOffsetY, BOOL animated))setPlainCenterOffsetY{
    
    return ^(CGFloat centerOffsetY, BOOL animated){
        
        if (_plainView == nil) {
            return self;
        }
        
        if (animated) {
            
            [UIView animateWithDuration:0.25 animations:^{
               
                self.plainView.center = CGPointMake(self.plainView.center.x, self.plainView.center.y + centerOffsetY);
            }];
            
        }else{
            
            self.plainView.center = CGPointMake(self.plainView.center.x, self.plainView.center.y + centerOffsetY);
        }
        
        return self;
    };
}

/**
 * 设置HUD样式高度，不包含customHUD
 * 小于0将没有效果，默认-1
 */
- (JKAlertView *(^)(CGFloat height))setHUDHeight{
    
    return ^(CGFloat height){
        
        self.HUDHeight = height;
        
        return self;
    };
}

/**
 * 设置collection的item的宽度
 * 注意图片的宽高是设置的宽度-30
 * 最大不可超过屏幕宽度的一半
 * 自动计算item之间间距，最小为0，可自己计算该值设置每屏显示个数
 */
- (JKAlertView *(^)(CGFloat width))setFlowlayoutItemWidth{
    
    return ^(CGFloat width){
        
        self.flowlayoutItemWidth = width;
        
        return self;
    };
}

/**
 * 设置collection样式添加自定义的titleView
 * frmae给出高度即可，宽度将自适应
 * 请将该自定义view视为容器view，推荐使用自动布局在其上约束子控件
 */
- (JKAlertView *(^)(UIView *(^customView)(void)))addCustomCollectionTitleView{
    
    return ^(UIView *(^customView)(void)){
        
        self.customCollectionTitleView = !customView ? nil : customView();
        
        return self;
    };
}

/**
 * 设置plain样式添加自定义的titleView
 * frame给出高度即可，宽度自适应plain宽度
 * 请将自定义view视为容器view，推荐使用自动布局约束其子控件
 */
- (JKAlertView *(^)(UIView *(^customView)(void)))addCustomPlainTitleView{
    
    return ^(UIView *(^customView)(void)){
        
        self.customPlainTitleView = !customView ? nil : customView();
        
        return self;
    };
}

- (JKAlertView *(^)(CGFloat margin))setTitleMessageMargin{
    
    return ^(CGFloat margin){
        
        self->JKAlertTitleMessageMargin = margin;
        
        return self;
    };
}

- (JKAlertView *(^)(UIView *(^backGroundView)(void)))setBackGroundView{
    
    return ^(UIView *(^backGroundView)(void)){
        
        self.backGroundView = !backGroundView ? nil : backGroundView();
        
        return self;
    };
}

#pragma mark - 监听屏幕旋转------------------------
- (void)orientationChanged:(NSNotification *)noti{
    
    switch ([UIApplication sharedApplication].statusBarOrientation){
        case UIInterfaceOrientationPortrait:{
            
            //        orientationLabel.text = "面向设备保持垂直，Home键位于下部"
            [self relayout];
        }
            break;
        case UIInterfaceOrientationPortraitUpsideDown:{
            
            //            orientationLabel.text = "面向设备保持垂直，Home键位于上部"
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            
            //            orientationLabel.text = "面向设备保持水平，Home键位于左侧"
            [self relayout];
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            
            //            orientationLabel.text = "面向设备保持水平，Home键位于右侧"
            [self relayout];
        }
            break;
        default:{
            
            //            orientationLabel.text = "方向未知"
        }
            break;
    }
}

#pragma mark - 添加action------------------------

/** 添加action */
- (JKAlertView *(^)(JKAlertAction *action))addAction{
    
    return ^(JKAlertAction *action){
        
        [self addAction:action];
        
        return self;
    };
}

/** 添加第二个collectionView的action */
- (JKAlertView *(^)(JKAlertAction *action))addSecondCollectionAction{
    
    return ^(JKAlertAction *action){
        
        [self addSecondCollectionAction:action];
        
        return self;
    };
}

/** 添加action */
- (void)addAction:(JKAlertAction *)action{
    
    [self.actions addObject:action];
}

/** 添加第二个collectionView的action */
- (void)addSecondCollectionAction:(JKAlertAction *)action{
    
    [self.actions2 addObject:action];
}

#pragma mark - 显示------------------------

/** 显示 */
- (id<JKAlertViewProtocol>(^)(void))show{
    
    if (Showed) {
        
        return ^{
            
            return self;
        };
    }
    
    Showed = YES;
    
    switch (self.alertStyle) {
        case JKAlertStylePlain:
        {
            [self showPlain];
        }
            break;
            
        case JKAlertStyleActionSheet:
        {
            [self showAcitonSheet];
        }
            break;
            
        case JKAlertStyleCollectionSheet:
        {
            [self showCollectionSheet];
        }
            break;
            
        case JKAlertStyleHUD:
        {
            [self showPlain];
        }
            break;
            
        default:
            break;
    }
    
    if (self.customSuperView != nil) {
        
        [self.customSuperView addSubview:self];
        
    }else{
        
        [[UIApplication sharedApplication].delegate.window addSubview:self];
    }
    
    return ^{
        
        return self;
    };
}

/** 监听JKAlertView显示动画完成 */
- (id<JKAlertViewProtocol>(^)(void(^showAnimationComplete)(JKAlertView *view)))setShowAnimationComplete{
    
    return ^(void(^showAnimationComplete)(JKAlertView *view)){
        
        self.showAnimationComplete = showAnimationComplete;
        
        return self;
    };
}

/** 显示并监听JKAlertView消失动画完成 */
- (void(^)(void(^dismissComplete)(void)))showWithDismissComplete{
    
    return ^(void(^dismissComplete)(void)){
        
        [self show];
        
        self.dismissComplete = dismissComplete;
    };
}

/** 监听JKAlertView消失动画完成 */
- (void(^)(void(^dismissComplete)(void)))setDismissComplete{
    
    return ^(void(^dismissComplete)(void)){
        
        self.dismissComplete = dismissComplete;
    };
}

/** 设置dealloc时会调用的block */
- (void(^)(void(^deallocBlock)(void)))setDeallocBlock{
    
    return ^(void(^deallocBlock)(void)){
        
        self.deallocBlock = deallocBlock;
    };
}

// plain样式 alert
- (void)showPlain{
    
    if (_alertStyle == JKAlertStyleHUD) {
        
        [self relayout];
        
        [_scrollView removeFromSuperview];
        
        CGRect rect = _plainView.frame;
        rect.size.height = _HUDHeight >= 0 ? _HUDHeight : _textContainerView.frame.size.height;
        _plainView.frame = rect;
        
        _plainView.center = CGPointMake(JKAlertScreenW * 0.5, JKAlertScreenH * 0.5 + self.HUDCenterOffsetY);
        
        return;
    }
    
    NSInteger count = self.actions.count;
    
    if (count == 0) {
        
        if (!self.cancelAction) {
            
            self.cancelAction = [JKAlertAction actionWithTitle:@"取消" style:(JKAlertActionStyleDefault) handler:^(JKAlertAction *action) {}];
        }
        
        [self addAction:self.cancelAction];
        
        count = 1;
    }
    
    for (NSInteger i = 0; i < count; i++) {
        
        CGFloat X = (count == 2 ? i * PlainViewWidth * 0.5 : 0);
        CGFloat Y = (count == 2 ? 0 : (i == 0 ? 0 : CGRectGetMaxY([self.scrollView viewWithTag:JKAlertPlainButtonBeginTag + i - 1].frame)));
        CGFloat W = (count == 2 ? PlainViewWidth * 0.5 : PlainViewWidth);
        
        JKAlertAction *action = self.actions[i];
        
        UIButton *btn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [self.scrollView addSubview:btn];
        btn.frame = CGRectMake(X, Y, W, JKAlertButtonH);
        
        [btn setBackgroundImage:JKAlertCreateImageWithColor([UIColor colorWithRed:217.0/255.0 green:217.0/255.0 blue:217.0/255.0 alpha:1], 1, 1, 0) forState:(UIControlStateHighlighted)];
        
        btn.tag = JKAlertPlainButtonBeginTag + i;
        
        if (action.titleColor == nil) {
            
            switch (action.alertActionStyle) {
                case JKAlertActionStyleDefault:
                    
                    action.setTitleColor([UIColor colorWithRed:0 green:119.0/255.0 blue:251.0/255.0 alpha:1]);
                    break;
                    
                case JKAlertActionStyleCancel:
                    
                    action.setTitleColor([UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1]);
                    break;
                    
                case JKAlertActionStyleDestructive:
                    
                    action.setTitleColor([UIColor redColor]);
                    break;
                    
                default:
                    break;
            }
        }
        
        if (action.titleFont == nil) {
            
            action.setTitleFont([UIFont systemFontOfSize:17]);
        }
        
        btn.titleLabel.font = action.titleFont;
        [btn setTitleColor:action.titleColor forState:(UIControlStateNormal)];
        
        if ([self.actions[i] customView] != nil) {
            
            btn.frame = CGRectMake(X, Y, W, [self.actions[i] customView].frame.size.height);
            [btn addSubview:[self.actions[i] customView]];
            [self.actions[i] customView].frame = btn.bounds;
            
        }else{
            
            if (action.attributedTitle) {
                
                [btn setAttributedTitle:action.attributedTitle forState:(UIControlStateNormal)];
            }
            
            if (action.title) {
                
                [btn setTitle:action.title forState:(UIControlStateNormal)];
            }
        }
        
        if (i == 1 && count == 2) {
            
            btn.frame = CGRectMake(X, Y, W, [self.scrollView viewWithTag:JKAlertPlainButtonBeginTag].frame.size.height);
        }
        
        [btn addTarget:self action:@selector(plainButtonClick:) forControlEvents:(UIControlEventTouchUpInside)];
        
        if (action.separatorLineHidden) {
            continue;
        }
        
        if (count == 2 && i == 1) {
            
            if (action.separatorLineHidden) { continue; }
            
            CALayer *vline = [CALayer layer];
            vline.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
            vline.frame = CGRectMake(0, -0.2, JKAlertSeparatorLineWH, JKAlertButtonH);
            [btn.layer addSublayer:vline];
        }
        
        if (count <= 2 || i == 0) { continue;  }
        
        if (action.separatorLineHidden) { continue; }
        
        CALayer *hline = [CALayer layer];
        hline.frame = CGRectMake(0.3, 0, btn.frame.size.width, JKAlertSeparatorLineWH);
        hline.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
        [btn.layer addSublayer:hline];
    }
    
    [self relayout];
}

// sheet样式
- (void)showAcitonSheet{
    
    if (!self.cancelAction) {
        
        self.cancelAction = [JKAlertAction actionWithTitle:@"取消" style:(JKAlertActionStyleDefault) handler:^(JKAlertAction *action) {}];
        self.cancelAction.setTitleFont([UIFont systemFontOfSize:17]);
        self.cancelAction.setTitleColor([UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1]);
    }
    
    self.cancelAction.setSeparatorLineHidden(YES);
    [self.actions.lastObject setSeparatorLineHidden:YES];
    
    [self relayout];
    
    [_tableView reloadData];
}

// collectionSheet样式
- (void)showCollectionSheet{
    
    if (!self.cancelAction) {
        
        self.cancelAction = [JKAlertAction actionWithTitle:@"取消" style:(JKAlertActionStyleDefault) handler:^(JKAlertAction *action) {}];
        self.cancelAction.setTitleFont([UIFont systemFontOfSize:17]);
        self.cancelAction.setTitleColor([UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1]);
    }
    
    if (self.cancelAction.customView) {
        
        [self.cancelButton addSubview:self.cancelAction.customView];
        
    }else{
        
        [self adjustButton:self.cancelButton action:self.cancelAction];
        
        if (self.cancelAction.attributedTitle) {
            
            [self.cancelButton setAttributedTitle:self.cancelAction.attributedTitle forState:(UIControlStateNormal)];
        }
        
        if (self.cancelAction.title) {
            
            [self.cancelButton setTitle:self.cancelAction.title forState:(UIControlStateNormal)];
        }
    }
    
    if (self.collectionAction == nil) {
        
        [self relayout];
        
        [_collectionView reloadData];
        
        return;
    }
    
    if (self.collectionAction.customView) {
        
        [self.collectionButton addSubview:self.collectionAction.customView];
        
    }else{
        
        [self adjustButton:self.collectionButton action:self.collectionAction];
        
        if (self.collectionAction.attributedTitle) {
            
            [self.collectionButton setAttributedTitle:self.collectionAction.attributedTitle forState:(UIControlStateNormal)];
        }
        
        if (self.collectionAction.title) {
            
            [self.collectionButton setTitle:self.collectionAction.title forState:(UIControlStateNormal)];
        }
    }
    
    [self relayout];
    
    [_collectionView reloadData];
}

- (void)adjustButton:(UIButton *)button action:(JKAlertAction *)action{
    
    if (action.titleColor == nil) {
    
    switch (action.alertActionStyle) {
        case JKAlertActionStyleDefault:
            
            action.setTitleColor([UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1]);
            break;
            
        case JKAlertActionStyleCancel:
            
            action.setTitleColor([UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1]);
            break;
            
        case JKAlertActionStyleDestructive:
            
            action.setTitleColor([UIColor redColor]);
            break;
            
        default:
            break;
    }
}
    
    if (action.titleFont == nil) {
        
        action.setTitleFont([UIFont systemFontOfSize:17]);
    }
    
    button.titleLabel.font = action.titleFont;
    [button setTitleColor:action.titleColor forState:(UIControlStateNormal)];
}

#pragma mark - 计算frame------------------------------------
- (void)relayout{
    
    self.frame = [UIScreen mainScreen].bounds;
    
    if (_customHUD) {
        
        [self layoutCustomHUD];
        
        return;
    }
    
    _iPhoneXLandscapeTextMargin = ((JKAlertIsIphoneX && JKAlertScreenW > JKAlertScreenH) ? 44 : 0);
    
    _titleTextView.textAlignment = self.titleTextViewAlignment;
    _messageTextView.textAlignment = self.messageTextViewAlignment;
    
    _titleTextView.userInteractionEnabled = self.textViewUserInteractionEnabled;
    _messageTextView.userInteractionEnabled = self.textViewUserInteractionEnabled;
    
    _titleTextView.canSelectText = self.textViewCanSelectText;
    _messageTextView.canSelectText = self.textViewCanSelectText;
    
    _titleTextView.textColor = titleTextColor ? titleTextColor : _titleTextView.textColor;
    _messageTextView.textColor = messageTextColor ? messageTextColor : _messageTextView.textColor;
    
    _titleTextView.font = titleFont ? titleFont : _titleTextView.font;
    _messageTextView.font = messageFont ? messageFont : _messageTextView.font;
    
    if (self.alertAttributedTitle) {
        
        _titleTextView.attributedText = self.alertAttributedTitle;
        
    }else if (self.alertTitle) {
        
        _titleTextView.text = self.alertTitle;
        
    }else{
        
        _titleTextView.hidden = YES;
    }
    
    if (self.attributedMessage) {
        
        _messageTextView.attributedText = self.attributedMessage;
        
    }else if (self.message) {
        
        _messageTextView.text = self.message;
        
    }else{
        
        _messageTextView.hidden = YES;
    }
    
    if (_alertStyle == JKAlertStyleHUD) {
        
        _messageTextView.hidden = YES;
    }
    
    switch (self.alertStyle) {
        case JKAlertStylePlain:
        {
            [self layoutPlain];
        }
            break;
            
        case JKAlertStyleActionSheet:
        {
            [self layoutActionSheet];
        }
            break;
            
        case JKAlertStyleCollectionSheet:
        {
            [self layoutCollectionSheet];
        }
            break;
            
        case JKAlertStyleHUD:
        {
            [self layoutPlain];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - 布局plain
- (void)layoutPlain{
    
    _plainView.frame = CGRectMake((JKAlertScreenW - PlainViewWidth) * 0.5, (JKAlertScreenH - 200) * 0.5, PlainViewWidth, 200);
    _textContainerView.frame = CGRectMake(0, 0, PlainViewWidth, TBMargin + JKAlertMinTitleLabelH + JKAlertTitleMessageMargin + JKAlertMinMessageLabelH + TBMargin);
    
    NSInteger count = self.actions.count;
    
    [self.titleTextView calculateFrameWithMaxWidth:PlainViewWidth - self.textViewLeftRightMargin * 2 minHeight:JKAlertMinTitleLabelH originY:TBMargin superView:self.textContainerView];
    
    [self.messageTextView calculateFrameWithMaxWidth:PlainViewWidth - self.textViewLeftRightMargin * 2 minHeight:JKAlertMinMessageLabelH originY:CGRectGetMaxY(self.titleTextView.frame) + JKAlertTitleMessageMargin superView:self.textContainerView];
    
    CGRect rect = self.textContainerView.frame;
    rect.size.height = TBMargin + self.titleTextView.frame.size.height + JKAlertTitleMessageMargin + self.messageTextView.frame.size.height + TBMargin;
    
    if (self.titleTextView.hidden && self.messageTextView.hidden) {
        
        rect.size.height = 0;
        
    }else if (self.titleTextView.hidden && !self.messageTextView.hidden) {
        
        self.messageTextView.frame = CGRectMake((PlainViewWidth - self.messageTextView.frame.size.width) * 0.5, 0, self.messageTextView.frame.size.width, self.messageTextView.frame.size.height);
        
        rect.size.height = TBMargin + (self.messageTextView.frame.size.height < 30 ? 30 : self.messageTextView.frame.size.height) + TBMargin;
        self.messageTextView.center = CGPointMake(rect.size.width * 0.5, rect.size.height * 0.5);
        
    }else if (self.messageTextView.hidden && !self.titleTextView.hidden) {
        
        self.titleTextView.frame = CGRectMake((PlainViewWidth - self.titleTextView.frame.size.width) * 0.5, 0, self.titleTextView.frame.size.width, self.titleTextView.frame.size.height);
        
        rect.size.height = TBMargin + (self.titleTextView.frame.size.height < 30 ? 30 : self.titleTextView.frame.size.height) + TBMargin;
        self.titleTextView.center = CGPointMake(rect.size.width * 0.5, rect.size.height * 0.5);
    }
    
    // 自定义
    if (_customPlainTitleView) {
        
        rect.size.height = _customPlainTitleView.frame.size.height;
        _customPlainTitleView.frame = rect;
        _customPlainTitleScrollView.contentSize = rect.size;
    }
    
    self.textContainerView.frame = rect;
    
    CGFloat H = 0;
    
    for (NSInteger i = 0; i < count; i++) {
        
        H += [self.scrollView viewWithTag:JKAlertPlainButtonBeginTag + i].frame.size.height;
    }
    
    H = (count == 2 ? [self.scrollView viewWithTag:JKAlertPlainButtonBeginTag].frame.size.height :H);
    
    rect = CGRectMake(0, CGRectGetMaxY(self.textContainerView.frame), self.plainView.frame.size.width, H);
    self.scrollView.contentSize = rect.size;
    self.scrollView.frame = rect;
    
    [self adjustPlainViewFrame];
    
    rect = self.plainView.frame;
    rect.size.height = self.textContainerView.frame.size.height + self.scrollView.frame.size.height;
    self.plainView.frame = rect;
    
    self.plainView.center = CGPointMake(JKAlertScreenW * 0.5, JKAlertScreenH * 0.5 + self.HUDCenterOffsetY);
    
    _bottomLineLayer.frame = CGRectMake(0, self.textContainerView.frame.size.height - JKAlertSeparatorLineWH, self.textContainerView.frame.size.width, JKAlertSeparatorLineWH);
    
    _bottomLineLayer.hidden = self.textContainerView.frame.size.height <= 0;
}

- (void)adjustPlainViewFrame{
    
    CGRect frame = CGRectZero;
    
    if (self.textContainerView.frame.size.height > JKAlertTextContainerViewMaxH && self.scrollView.frame.size.height > JKAlertScrollViewMaxH) {
        
        frame = self.textContainerView.frame;
        frame.size.height = JKAlertTextContainerViewMaxH;
        self.textContainerView.frame = frame;
        
        frame = self.scrollView.frame;
        frame.origin.y = self.textContainerView.frame.size.height;
        frame.size.height = JKAlertScrollViewMaxH;
        self.scrollView.frame = frame;
        
    }else if (self.textContainerView.frame.size.height > JKAlertTextContainerViewMaxH) {
        
        frame = self.textContainerView.frame;
        frame.size.height = (frame.size.height + self.scrollView.frame.size.height) > JKAlertPlainViewMaxH ? JKAlertPlainViewMaxH - self.scrollView.frame.size.height : frame.size.height;
        self.textContainerView.frame = frame;
        
    }else if (self.scrollView.frame.size.height > JKAlertScrollViewMaxH) {
        
        frame = self.scrollView.frame;
        frame.origin.y = self.textContainerView.frame.size.height;
        frame.size.height = (frame.size.height + self.textContainerView.frame.size.height) > JKAlertPlainViewMaxH ? JKAlertPlainViewMaxH - self.textContainerView.frame.size.height : frame.size.height;
        self.scrollView.frame = frame;
    }
    
    frame = self.scrollView.frame;
    frame.origin.y = self.textContainerView.frame.size.height;
    self.scrollView.frame = frame;
    
    textContainerViewCurrentMaxH_ = self.textContainerView.frame.size.height;
    
    [self adjustTextContainerViewFrame];
}

- (void)adjustTextContainerViewFrame{
    
    CGRect frame = CGRectZero;
    
    if (self.messageTextView.hidden) {
        
        frame = self.titleTextView.frame;
        frame.size.height = frame.size.height > textContainerViewCurrentMaxH_ - TBMargin * 2 ? textContainerViewCurrentMaxH_ - TBMargin * 2 : frame.size.height;
        self.titleTextView.frame = frame;
        
        return;
    }
    
    if (self.titleTextView.hidden) {
        
        frame = self.messageTextView.frame;
        frame.size.height = frame.size.height > textContainerViewCurrentMaxH_ - TBMargin * 2 ? textContainerViewCurrentMaxH_ - TBMargin * 2 : frame.size.height;
        self.messageTextView.frame = frame;
        
        return;
    }
    
    CGFloat maxH = (textContainerViewCurrentMaxH_ - TBMargin - JKAlertTitleMessageMargin - TBMargin) * 0.5;
    
    if (self.titleTextView.frame.size.height > maxH && self.messageTextView.frame.size.height > maxH) {
        
        frame = self.titleTextView.frame;
        frame.size.height = maxH;
        self.titleTextView.frame = frame;
        
        frame = self.messageTextView.frame;
        frame.origin.y = CGRectGetMaxY(self.titleTextView.frame) + JKAlertTitleMessageMargin;
        frame.size.height = maxH;
        self.messageTextView.frame = frame;
        
    }else if (self.titleTextView.frame.size.height > maxH) {
        
        frame = self.titleTextView.frame;
        frame.size.height = textContainerViewCurrentMaxH_ - TBMargin - JKAlertTitleMessageMargin - TBMargin - self.messageTextView.frame.size.height;
        self.titleTextView.frame = frame;
        
        frame = self.messageTextView.frame;
        frame.origin.y = CGRectGetMaxY(self.titleTextView.frame) + JKAlertTitleMessageMargin;
        self.messageTextView.frame = frame;
        
    }else if (self.messageTextView.frame.size.height > maxH) {
        
        frame = self.messageTextView.frame;
        frame.origin.y = CGRectGetMaxY(self.titleTextView.frame) + JKAlertTitleMessageMargin;
        frame.size.height = textContainerViewCurrentMaxH_ - TBMargin - JKAlertTitleMessageMargin - TBMargin - self.titleTextView.frame.size.height;
        self.messageTextView.frame = frame;
    }
}

#pragma mark - 布局actionSheet
- (void)layoutActionSheet{
    
    self.titleTextView.scrollEnabled = NO;
    self.messageTextView.scrollEnabled = NO;
    
    if (self.message && !self.alertTitle && !self.alertAttributedTitle) {
        
        self.messageTextView.font = [UIFont systemFontOfSize:15];
    }
    
    _textContainerView.frame = CGRectMake(_iPhoneXLandscapeTextMargin, 0, JKAlertScreenW - _iPhoneXLandscapeTextMargin * 2, JKAlertRowHeight);
    
    CGFloat tableViewH = 0;
    
    for (JKAlertAction *action in self.actions) {
        
        tableViewH += action.rowHeight;
    }
    
    tableViewH += (self.cancelAction.rowHeight + CancelMargin + JKAlertAdjustHomeIndicatorHeight);
    
    _tableView.frame = CGRectMake(0, CGRectGetMaxY(_textContainerView.frame), JKAlertScreenW, tableViewH);
    
    _sheetContainerView.frame = CGRectMake(0, JKAlertScreenH, JKAlertScreenW, _textContainerView.frame.size.height + _tableView.frame.size.height);
    
    [self.titleTextView calculateFrameWithMaxWidth:_textContainerView.frame.size.width - self.textViewLeftRightMargin * 2 minHeight:JKAlertMinTitleLabelH originY:JKAlertSheetTitleMargin superView:_textContainerView];
    
    [self.messageTextView calculateFrameWithMaxWidth:_textContainerView.frame.size.width - self.textViewLeftRightMargin * 2 minHeight:JKAlertMinMessageLabelH originY:CGRectGetMaxY(self.titleTextView.frame) + JKAlertSheetTitleMargin superView:_textContainerView];
    
    CGRect rect = _textContainerView.frame;
    rect.size.height = JKAlertSheetTitleMargin + self.titleTextView.frame.size.height + JKAlertSheetTitleMargin + self.messageTextView.frame.size.height + JKAlertSheetTitleMargin;
    
    if (self.titleTextView.hidden && self.messageTextView.hidden) {
        
        rect.size.height = 0;
        _bottomLineLayer.hidden = YES;
        
    }else if (self.titleTextView.hidden && !self.messageTextView.hidden) {
        
        rect.size.height = JKAlertSheetTitleMargin + self.messageTextView.frame.size.height + JKAlertSheetTitleMargin;
        rect.size.height = rect.size.height < JKAlertRowHeight ? JKAlertRowHeight : rect.size.height;
        
        self.messageTextView.center = CGPointMake(self.textContainerView.frame.size.width * 0.5, rect.size.height * 0.5);
        
    }else if (self.messageTextView.hidden && !self.titleTextView.hidden) {
        
        rect.size.height = JKAlertSheetTitleMargin + self.titleTextView.frame.size.height + JKAlertSheetTitleMargin;
        rect.size.height = rect.size.height < JKAlertRowHeight ? JKAlertRowHeight : rect.size.height;
        
        self.titleTextView.center = CGPointMake(self.textContainerView.frame.size.width * 0.5, rect.size.height * 0.5);
    }
    
    _textContainerView.frame = rect;
    _scrollView.contentSize = rect.size;
    
    [self adjustSheetFrame];
    
    _sheetContainerView.frame = CGRectMake(0, JKAlertScreenH - (_textContainerView.frame.size.height + _tableView.frame.size.height), JKAlertScreenW, _textContainerView.frame.size.height + _tableView.frame.size.height);
    _scrollView.frame = CGRectMake(0, 0, _textContainerView.bounds.size.width, _textContainerView.bounds.size.height);
    
    _tableView.scrollEnabled = _tableView.frame.size.height < tableViewH;
    
    _bottomLineLayer.frame = CGRectMake(0, self.textContainerView.frame.size.height - JKAlertSeparatorLineWH, self.textContainerView.frame.size.width, JKAlertSeparatorLineWH);
}

- (void)adjustSheetFrame{
    
    CGRect frame = CGRectZero;
    
    if (self.textContainerView.frame.size.height > JKAlertSheetMaxH * 0.5 && self.tableView.frame.size.height > JKAlertSheetMaxH * 0.5) {
        
        frame = self.textContainerView.frame;
        frame.size.height = JKAlertSheetMaxH * 0.5;
        self.textContainerView.frame = frame;
        
        frame = self.tableView.frame;
        frame.origin.y = self.textContainerView.frame.size.height;
        frame.size.height = JKAlertSheetMaxH * 0.5;
        self.tableView.frame = frame;
        
    }else if (self.textContainerView.frame.size.height > JKAlertSheetMaxH * 0.5) {
        
        frame = self.textContainerView.frame;
        frame.size.height = (frame.size.height + self.tableView.frame.size.height) > JKAlertSheetMaxH ? JKAlertSheetMaxH - self.tableView.frame.size.height : frame.size.height;
        self.textContainerView.frame = frame;
        
    }else if (self.tableView.frame.size.height > JKAlertSheetMaxH * 0.5) {
        
        frame = self.tableView.frame;
        frame.origin.y = self.textContainerView.frame.size.height;
        frame.size.height = (frame.size.height + self.textContainerView.frame.size.height) > JKAlertSheetMaxH ? JKAlertSheetMaxH - self.textContainerView.frame.size.height : frame.size.height;
        self.tableView.frame = frame;
    }
    
    frame = self.tableView.frame;
    frame.origin.y = self.textContainerView.frame.size.height;
    self.tableView.frame = frame;
}

#pragma mark - 布局collectionSheet
- (void)layoutCollectionSheet{
    
    NSInteger count = self.actions.count;
    NSInteger count2 = self.actions2.count;
    
    if (count <= 0 && count2 > 0) {
        
        [self.actions addObjectsFromArray:self.actions2];
        
        [self.actions2 removeAllObjects];
        
        count = count2;
        count2 = 0;
        
        self.compoundCollection = NO;
    }
    
    if (count == 0 && count2 == 0) {
        
        self.compoundCollection = NO;
    }
    
    // 合体
    if (self.compoundCollection && count2 > 0 && count != count2) {
        
        if (count > count2) {
            
            for (NSInteger i = 0; i < count - count2; i++) {
                
                [self addSecondCollectionAction:[JKAlertAction actionWithTitle:nil style:(0) handler:nil]];
            }
            
            count2 = count;
            
        }else{
            
            for (NSInteger i = 0; i < count2 - count; i++) {
                
                [self addAction:[JKAlertAction actionWithTitle:nil style:(0) handler:nil]];
            }
            
            count = count2;
        }
    }
    
    CGRect rect = [self.titleTextView calculateFrameWithMaxWidth:JKAlertScreenW - self.textViewLeftRightMargin * 2 - _iPhoneXLandscapeTextMargin * 2 minHeight:JKAlertMinTitleLabelH originY:0 superView:self.textContainerView];
    
    if (JKAlertScreenH * 0.8 - 395 > JKAlertMinTitleLabelH) {
        
        rect.size.height = rect.size.height > JKAlertScreenH * 0.8 - 395 ? JKAlertScreenH * 0.8 - 395 : rect.size.height;
    }
    
    rect.size.height = self.titleTextView.hidden ? -TBMargin * 2 : rect.size.height;
    
    self.titleTextView.frame = rect;
    
    self.textContainerView.frame = CGRectMake(0, 0, JKAlertScreenW, TBMargin + rect.size.height + TBMargin);
    self.titleTextView.center = CGPointMake(self.textContainerView.frame.size.width * 0.5, self.textContainerView.frame.size.height * 0.5);
    
    if (_customCollectionTitleView) {
        
        self.textContainerView.frame = CGRectMake(0, 0, JKAlertScreenW, _customCollectionTitleView.frame.size.height);
        _customCollectionTitleView.frame = CGRectMake(_iPhoneXLandscapeTextMargin, 0, JKAlertScreenW - _iPhoneXLandscapeTextMargin * 2, _customCollectionTitleView.frame.size.height);
    }
    
    self.collectionView.frame = CGRectMake(0, CGRectGetMaxY(self.textContainerView.frame), JKAlertScreenW, self.flowlayoutItemWidth - 6 + 10);
    self.flowlayout.itemSize = CGSizeMake(self.flowlayoutItemWidth, self.flowlayoutItemWidth - 6);
    self.flowlayout.sectionInset = UIEdgeInsetsMake(self.flowlayout.itemSize.height - self.collectionView.frame.size.height, 0, 0, 0);
    
    if (count2 > 0) {
        
        self.collectionView2.frame = CGRectMake(0, CGRectGetMaxY(self.collectionView.frame), JKAlertScreenW, self.collectionView.frame.size.height);
        
        self.flowlayout2.itemSize = CGSizeMake(self.flowlayoutItemWidth, self.flowlayoutItemWidth - 6);
        self.flowlayout2.sectionInset = UIEdgeInsetsMake(self.flowlayout2.itemSize.height - self.collectionView2.frame.size.height, 0, 0, 0);
    }
    
    if (_showPageControl && _collectionPagingEnabled) {
        
        if (count2 <= 0) {
            
            self.pageControl.frame = CGRectMake(0, CGRectGetMaxY(self.collectionView.frame), self.sheetContainerView.frame.size.width, 27);
            
        }else{
            
            if (_compoundCollection) {
                
                self.pageControl.frame = CGRectMake(0, CGRectGetMaxY(self.collectionView2.frame), self.sheetContainerView.frame.size.width, 27);
            }
        }
    }
    
    CGRect frame = CGRectZero;
    
    if (self.collectionAction) {
        
         frame = CGRectMake(self.collectionButtonLeftRightMargin + _iPhoneXLandscapeTextMargin, CGRectGetMaxY(_pageControl ? _pageControl.frame : (_collectionView2 ? _collectionView2.frame : _collectionView.frame)) + CancelMargin, JKAlertScreenW - self.collectionButtonLeftRightMargin * 2 - _iPhoneXLandscapeTextMargin * 2, JKAlertButtonH);
        
        if (self.collectionAction.customView) {
            
            frame.size.height = self.collectionAction.customView.frame.size.height;
        }
        
        self.collectionButton.frame = frame;
        
        self.collectionAction.customView.frame = self.collectionButton.bounds;
    }
    
    frame = CGRectMake(self.collectionButtonLeftRightMargin + _iPhoneXLandscapeTextMargin, CGRectGetMaxY(_collectionButton ? _collectionButton.frame : (_collectionView2 ? _collectionView2.frame : _collectionView.frame)) + CancelMargin, JKAlertScreenW - self.collectionButtonLeftRightMargin * 2 - _iPhoneXLandscapeTextMargin * 2, JKAlertButtonH);
    
    if (self.cancelAction.customView) {
        
        frame.size.height = self.cancelAction.customView.frame.size.height;
    }
    
    self.cancelButton.frame = frame;
    
    self.cancelAction.customView.frame = self.cancelButton.bounds;
    
    rect = CGRectMake(0, JKAlertScreenH - (CGRectGetMaxY(self.cancelButton.frame) + JKAlertAdjustHomeIndicatorHeight), JKAlertScreenW, CGRectGetMaxY(self.cancelButton.frame) + JKAlertAdjustHomeIndicatorHeight);
    
    self.scrollView.contentSize = rect.size;
    
    if (rect.size.height > JKAlertScreenH * 0.8) {
        
        rect.size.height = JKAlertScreenH * 0.8;
        rect.origin.y = JKAlertScreenH * 0.2;
    }
    
    self.sheetContainerView.frame = rect;
    
    CGFloat itemMargin = (JKAlertScreenW - self.flowlayout.itemSize.width * count) / count;
    
    itemMargin = itemMargin < 0 ? 0 : itemMargin;
    
    if (count2 > 0) {
        
        CGFloat itemMargin2 = (JKAlertScreenW - self.flowlayout2.itemSize.width * count2) / count2;
        itemMargin2 = itemMargin2 < 0 ? 0 : itemMargin2;
        
        itemMargin = MIN(itemMargin, itemMargin2);
        
        self.flowlayout2.sectionInset = UIEdgeInsetsMake(self.flowlayout2.sectionInset.top, itemMargin * 0.5, 0, itemMargin * 0.5);
        self.flowlayout2.minimumLineSpacing = itemMargin;
        self.flowlayout2.minimumInteritemSpacing = itemMargin;
    }
    
    self.flowlayout.sectionInset = UIEdgeInsetsMake(self.flowlayout.sectionInset.top, itemMargin * 0.5, 0, itemMargin * 0.5);
    self.flowlayout.minimumLineSpacing = itemMargin;
    self.flowlayout.minimumInteritemSpacing = itemMargin;
    
    _pageControl.numberOfPages = ceil((itemMargin + _flowlayout.itemSize.width) * count / JKAlertScreenW);
    
    // 处理iPhoneX并且横屏的情况
    _collectionView.contentInset = (JKAlertIsIphoneX && JKAlertScreenW > JKAlertScreenH && itemMargin < 44) ? UIEdgeInsetsMake(0, 44 - itemMargin, 0, 44 - itemMargin) : UIEdgeInsetsZero;
    _collectionView2.contentInset = _collectionView.contentInset;
    
    // 分页
    _collectionView.pagingEnabled = self.collectionPagingEnabled && _pageControl.numberOfPages > 1;
    _collectionView2.pagingEnabled = _collectionView.pagingEnabled;
}

#pragma mark - 布局自定义HUD
- (void)layoutCustomHUD{
    
    if (!_customHUD) {
        return;
    }
    
    self.plainView.frame = _customHUD.bounds;
    self.plainView.center = CGPointMake(JKAlertScreenW * 0.5, JKAlertScreenH * 0.5 + self.HUDCenterOffsetY);
}

#pragma mark - 动画弹出来------------------------
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
    
    if (!self.superview) {
        return;
    }
    
    self.window.userInteractionEnabled = NO;
    
    _plainView.alpha = 0;
    _plainView.transform = CGAffineTransformMakeScale(1.2, 1.2);
    
    _sheetContainerView.frame = CGRectMake(_sheetContainerView.frame.origin.x, JKAlertScreenH, _sheetContainerView.frame.size.width, _sheetContainerView.frame.size.height);
    
    [UIView animateWithDuration:0.25 animations:^{
        
        [self showAnimationOperation];
        
    } completion:^(BOOL finished) {
        
        self.window.userInteractionEnabled = YES;
        
        self->_titleTextView.delegate = self.titleTextViewDelegate;
        self->_messageTextView.delegate = self.messageTextViewDelegate;
        
        !self.showAnimationComplete ? : self.showAnimationComplete(self);
        
        if (self.dismissTimeInterval > 0 && (self.alertStyle == JKAlertStyleHUD || self.customHUD)) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.dismissTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [self dismiss];
            });
        }
    }];
}

- (void)showAnimationOperation{
    
    self.contentView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    
    CGRect rect = _sheetContainerView.frame;
    rect.origin.y = JKAlertScreenH - _sheetContainerView.frame.size.height;
    _sheetContainerView.frame = rect;
    
    _plainView.transform = CGAffineTransformIdentity;
    _plainView.alpha = 1;
}

#pragma mark - 退出------------------------
- (void(^)(void))dismiss{
    
    self.window.userInteractionEnabled = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [UIView animateWithDuration:0.25 animations:^{
        
        [self dismissAnimationOperation];
        
    } completion:^(BOOL finished) {
        
        [self dismissAnimationComplete];
    }];
    
    return ^{};
}

- (void)dismissAnimationOperation{
    
    self.contentView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    CGRect rect = _sheetContainerView.frame;
    rect.origin.y = JKAlertScreenH;
    _sheetContainerView.frame = rect;
    
    _plainView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    _plainView.alpha = 0;
}

- (void)dismissAnimationComplete{
    
    self.window.userInteractionEnabled = YES;
    
    !self.dismissComplete ? : self.dismissComplete();
    
    [self.actions removeAllObjects];
    self.actions = nil;
    
    [self.actions2 removeAllObjects];
    self.actions2 = nil;
    
    _cancelAction = nil;
    _collectionAction = nil;
    
    [self removeFromSuperview];
}

- (void)collectionButtonClick{
    
    !self.collectionAction.handler ? : self.collectionAction.handler(self.collectionAction);
    
    [self dismiss];
}

#pragma mark - 强制更改frame为屏幕尺寸
- (void)setFrame:(CGRect)frame{
    frame = CGRectMake(0, 0, JKAlertScreenW, JKAlertScreenH);
    [super setFrame:frame];
}

#pragma mark - UITableViewDataSource------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.alertStyle == JKAlertStyleActionSheet ? 2 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return section == 0 ? self.actions.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    JKAlertTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([JKAlertTableViewCell class])];
    
    if (cell == nil) {
        
        cell = [[JKAlertTableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:NSStringFromClass([JKAlertTableViewCell class])];
    }
    
    if (indexPath.section == 0) {
        
        cell.action = self.actions[indexPath.row];
        
    }else{
        
        cell.action = self.cancelAction;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    JKAlertAction *action = indexPath.section == 0 ? self.actions[indexPath.row] : self.cancelAction;
    
    return action.rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return (section == 0) ? CancelMargin : CGFLOAT_MIN;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    JKAlertAction *action = indexPath.section == 0 ? self.actions[indexPath.row] : self.cancelAction;
    
    !action.handler ? : action.handler(action);
    
    if (action.isEmpty) {
        return;
    }
    
    [self dismiss];
}

#pragma mark - UICollectionViewDataSource------------------------
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return collectionView == self.collectionView ? self.actions.count : self.actions2.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    JKAlertCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([JKAlertCollectionViewCell class]) forIndexPath:indexPath];
    
    cell.action = collectionView == self.collectionView ? self.actions[indexPath.item] : self.actions2[indexPath.item];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate------------------------
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    JKAlertAction *action = collectionView == self.collectionView ? self.actions[indexPath.item] : self.actions2[indexPath.item];
    
    !action.handler ? : action.handler(action);
    
    if (action.isEmpty) {
        return;
    }
    
    [self dismiss];
}

#pragma mark - UIScrollViewDelegate------------------------
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (!self.compoundCollection) {
        return;
    }
    
    _collectionView.contentOffset = scrollView.contentOffset;
    
    _collectionView2.contentOffset = scrollView.contentOffset;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    _pageControl.currentPage = ceil(scrollView.contentOffset.x / JKAlertScreenW);
}

#pragma mark - plain样式按钮点击------------------------
- (void)plainButtonClick:(UIButton *)button{
    
    JKAlertAction *action = self.actions[button.tag - JKAlertPlainButtonBeginTag];
    
    !action.handler ? : action.handler(action);
    
    [self dismiss];
}

#pragma mark - dealloc------------------------
/** 允许dealloc打印，用于检查循环引用 */
- (JKAlertView *(^)(BOOL enable))enableDeallocLog{
    
    return ^(BOOL enable){
        
        self->_enableDeallocLog = enable;
        
        return self;
    };
}

- (void)dealloc{
    
    if (_enableDeallocLog) {
        
        NSLog(@"%d, %s",__LINE__, __func__);
    }
    
    !self.deallocBlock ? : self.deallocBlock();
}

UIImage * JKAlertCreateImageWithColor (UIColor *color, CGFloat width, CGFloat height, CGFloat cornerRadius) {
    
    if (width <= 0 || height <= 0 || !color) { return nil; }
    
    CGRect rect = CGRectMake(0.0f, 0.0f, width, height);
    
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    
    CGContextFillRect(context, rect);
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    if (cornerRadius > 0) {
        
        // NO代表透明
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
        
        // 获取上下文
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        // 添加一个圆
        //CGContextAddEllipseInRect(ctx, rect);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:(UIRectCornerAllCorners) cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
        
        CGContextAddPath(ctx, path.CGPath);
        
        // 裁剪
        CGContextClip(ctx);
        
        // 将图片画上去
        [theImage drawInRect:rect];
        
        theImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    return theImage;
}
@end

