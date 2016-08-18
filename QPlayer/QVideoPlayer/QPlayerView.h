//
//  QPlayerView.h
//  QPlayer
//
//  Created by pactera on 16/7/18.
//  Copyright © 2016年 com.storyboard.pactera. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QPlayerView : UIView

@property (nonatomic, strong, readonly) UIView *topBar;

@property (nonatomic, strong, readonly) UIView *bottomBar;

@property (nonatomic, strong, readonly) UIButton *playButton;

@property (nonatomic, strong, readonly) UIButton *pauseButton;

@property (nonatomic, strong, readonly) UILabel *titleLabel;

@property (nonatomic, strong, readonly) UIView *leftView;

@property (nonatomic, strong, readonly) UIView *rightView;

/**
 *  放大按钮
 */
@property (nonatomic, strong, readonly) UIButton *fullScreenButton;

/**
 *  所需按钮
 */
@property (nonatomic, strong, readonly) UIButton *shrinkScreenButton;

/**
 *  进度条滑动圆
 */
@property (nonatomic, strong, readonly) UISlider *progressSlider;
/**
 *  返回按钮
 */
@property (nonatomic, strong, readonly) UIButton *backButton;


/**
 *  关闭按钮
 */
@property (nonatomic, strong, readonly) UIButton *closeButton;

/**
 *  时间
 */
@property (nonatomic, strong, readonly) UILabel *timeLabel;

/**
 *  加载
 */
@property (nonatomic, strong, readonly) UIActivityIndicatorView *indicatorView;
/**
 *  动画隐藏
 */
- (void)animateHide;

//@property (nonatomic, assign) BOOL isBarShowing;


/**
 *  动画显示
 */
- (void)animateShow;

- (void)autoFadeOutControlBar;

- (void)cancelAutoFadeOutControlBar;
@end
