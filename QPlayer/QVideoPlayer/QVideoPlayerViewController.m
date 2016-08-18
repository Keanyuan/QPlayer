//
//  QVideoPlayerViewController.m
//  QPlayer
//
//  Created by pactera on 16/7/18.
//  Copyright © 2016年 com.storyboard.pactera. All rights reserved.
//

#import "QVideoPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "QPlayerView.h"

static const CGFloat kVideoPlayerControllerAnimationTimeinterval = 0.3f;
static const CGFloat VolumeStep = 0.1f;


@interface QVideoPlayerViewController ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) QPlayerView *videoControl;
@property (nonatomic, strong) UIView *movieBackgroundView;
@property (nonatomic, assign) BOOL isFullscreenMode;
@property (nonatomic, assign) CGRect originFrame;
@property (nonatomic, strong) NSTimer *durationTimer;
@property (nonatomic, strong) UIView *originView;


//记录起始点
@property (assign, nonatomic) float lastX;
@property (assign, nonatomic) float lastY;
//手势状态
@property (nonatomic, assign) int gestureStatus;

//记录进度条手势快进秒数
//@property (nonatomic, assign) double second;

//快进的时候显示时间提示
//@property (nonatomic, strong) UIView *showTimeView;

//timeShowLabel
//@property (nonatomic, strong) UILabel *timeShowLabel;


@end
@implementation QVideoPlayerViewController

- (instancetype)initWithFrame:(CGRect)frame titleLabelTitlte:(NSString *)title{
    self = [super init];
    if (self) {
        self.gestureStatus = -1;
        self.view.frame = frame;
        self.view.backgroundColor = [UIColor blackColor];
        //控制方式
        self.controlStyle = MPMovieControlStyleNone;
        [self.view addSubview:self.videoControl];
        self.videoControl.frame = self.view.bounds;
        [self.videoControl.titleLabel setText:title];
        [self configObserver];
        [self configControlAction];
        //        [self ListeningRotating];
        [self setSwipeGesture];
        
    }
    return self;
}

#pragma mark - Override Method
//覆盖方法
- (void)setContentURL:(NSURL *)contentURL
{
    [self stop];
    [super setContentURL:contentURL];
    [self play];
    [self.videoControl.indicatorView startAnimating];
    self.videoControl.playButton.enabled = NO;
    self.videoControl.pauseButton.enabled = NO;
}

#pragma mark - Publick Method
- (void)showInWindow
{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (!keyWindow) {
        keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
    }
    [keyWindow addSubview:self.view];
    self.view.alpha = 0.0;
    [UIView animateWithDuration:kVideoPlayerControllerAnimationTimeinterval animations:^{
        self.view.alpha = 1.0;
    } completion:^(BOOL finished) {
        
    }];
    //隐藏状态栏
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

//关闭
- (void)dismiss
{
    [self stop];
    [self stopDurationTimer];
    
    __weak typeof(self) __weakMe = self;
    if (self.willBackOrientationPortrait) {
        self.willBackOrientationPortrait();
    }
    [UIView animateWithDuration:kVideoPlayerControllerAnimationTimeinterval animations:^{
        __weakMe.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        
    }];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}


#pragma mark - Private Method
- (void)configObserver
{
    //播放器的状态通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerPlaybackStateDidChangeNotification) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    //视频加载状态改变通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerLoadStateDidChangeNotification) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    //视频显示状态改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerReadyForDisplayDidChangeNotification) name:MPMoviePlayerReadyForDisplayDidChangeNotification object:nil];
    //确定了媒体播放时长后
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMovieDurationAvailableNotification) name:MPMovieDurationAvailableNotification object:nil];
    //播放完成
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerPlaybackFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
}

//设置点击状态
- (void)configControlAction
{
    
    [self.videoControl.playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.pauseButton addTarget:self action:@selector(pauseButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.closeButton addTarget:self action:@selector(closeButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.backButton addTarget:self action:@selector(shrinkScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.fullScreenButton addTarget:self action:@selector(fullScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.shrinkScreenButton addTarget:self action:@selector(shrinkScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpOutside];
    [self setProgressSliderMaxMinValues];
    [self monitorVideoPlayback];
}

//设置进度条最大最小值
- (void)setProgressSliderMaxMinValues {
    CGFloat duration = self.duration;
    self.videoControl.progressSlider.minimumValue = 0.f;
    self.videoControl.progressSlider.maximumValue = duration;
}

//播放器的状态通知
- (void)onMPMoviePlayerPlaybackStateDidChangeNotification
{
    /*
     MPMoviePlaybackStateStopped, 停止0
     MPMoviePlaybackStatePlaying, 播放1
     MPMoviePlaybackStatePaused, 暂停
     MPMoviePlaybackStateInterrupted,//中断
     MPMoviePlaybackStateSeekingForward, //快进
     MPMoviePlaybackStateSeekingBackward//快退
     */
    NSLog(@"%s %ld",__func__, (long)self.playbackState);
    if (self.playbackState == MPMoviePlaybackStatePlaying) {
        self.videoControl.pauseButton.hidden = NO;
        self.videoControl.playButton.hidden = YES;
        [self startDurationTimer];
        [self.videoControl.indicatorView stopAnimating];
        self.videoControl.playButton.enabled = YES;
        self.videoControl.pauseButton.enabled = YES;
        [self.videoControl autoFadeOutControlBar];
    } else {
        self.videoControl.pauseButton.hidden = YES;
        self.videoControl.playButton.hidden = NO;
        [self stopDurationTimer];
        if (self.playbackState == MPMoviePlaybackStateStopped) {
            [self.videoControl animateShow];
        }
    }
}

//视频加载状态改变通知
- (void)onMPMoviePlayerLoadStateDidChangeNotification
{
    NSLog(@"%s loadState = %ld",__func__, (long)self.loadState);
    /**
     *  MPMovieLoadStateUnknown        = 0,
     MPMovieLoadStatePlayable       = 1 << 0,
     MPMovieLoadStatePlaythroughOK  = 1 << 1, // Playback will be automatically started in this state when shouldAutoplay is YES
     MPMovieLoadStateStalled        = 1 << 2, // Playback will be automatically paused
     */
    if (self.loadState & MPMovieLoadStateStalled) {
        [self.videoControl.indicatorView startAnimating];
    } else if (self.loadState & MPMovieLoadStatePlaythroughOK) {
        [self.videoControl.indicatorView stopAnimating];
    }
    
}

//视频显示状态改变
- (void)onMPMoviePlayerReadyForDisplayDidChangeNotification
{
    NSLog(@"%s",__func__);
}

//确定了媒体播放时长后
- (void)onMPMovieDurationAvailableNotification
{
    [self setProgressSliderMaxMinValues];
}

//播放完成
-(void)mediaPlayerPlaybackFinished:(NSNotification *)notification{
    NSLog(@"播放完成.%li",self.playbackState);
}


- (void)playButtonClick
{
    [self play];
    self.videoControl.playButton.hidden = YES;
    self.videoControl.pauseButton.hidden = NO;
}

- (void)pauseButtonClick
{
    [self pause];
    self.videoControl.playButton.hidden = NO;
    self.videoControl.pauseButton.hidden = YES;
}

- (void)closeButtonClick
{
    //    [self dismiss];
    __weak typeof(self) __weakMe = self;
    if (__weakMe.dimissCompleteBlock) {
        __weakMe.dimissCompleteBlock();
    }
}

- (void)fullScreenButtonClick
{
    if (self.isFullscreenMode) {
        return;
    }
    self.videoControl.titleLabel.hidden = NO;
    self.videoControl.closeButton.hidden = NO;
    [self setDeviceOrientationLandscapeRight];
}
- (void)shrinkScreenButtonClick
{
    if (!self.isFullscreenMode) {
        return;
    }
    self.videoControl.titleLabel.hidden = YES;
    self.videoControl.closeButton.hidden = NO;
    [self backOrientationPortrait];
    
}

- (void)progressSliderValueChanged:(UISlider *)slider {
    double currentTime = floor(slider.value);
    double totalTime = floor(self.duration);
    [self setTimeLabelValues:currentTime totalTime:totalTime];
}

- (void)progressSliderTouchBegan:(UISlider *)slider {
    [self pause];
    [self.videoControl cancelAutoFadeOutControlBar];
}

- (void)progressSliderTouchEnded:(UISlider *)slider {
    [self setCurrentPlaybackTime:floor(slider.value)];
    [self play];
    [self.videoControl autoFadeOutControlBar];
}


#pragma mark -- 设备旋转监听 改变视频全屏状态显示方向 --
//监听设备旋转方向
- (void)ListeningRotating{
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil
     ];
    
}
- (void)onDeviceOrientationChange{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
            /**        case UIInterfaceOrientationUnknown:
             NSLog(@"未知方向");
             break;
             */
        case UIInterfaceOrientationPortraitUpsideDown:{
            NSLog(@"第3个旋转方向---电池栏在下");
            [self backOrientationPortrait];
        }
            break;
        case UIInterfaceOrientationPortrait:{
            NSLog(@"第0个旋转方向---电池栏在上");
            [self backOrientationPortrait];
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            NSLog(@"第2个旋转方向---电池栏在右");
            
            [self setDeviceOrientationLandscapeLeft];
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            
            NSLog(@"第1个旋转方向---电池栏在左");
            
            [self setDeviceOrientationLandscapeRight];
            
        }
            break;
            
        default:
            break;
    }
    
}

//返回小屏幕
- (void)backOrientationPortrait{
    if (!self.isFullscreenMode) {
        return;
    }
    if (self.willBackOrientationPortrait) {
        self.willBackOrientationPortrait();
    }
    self.videoControl.backButton.hidden = YES;
    [self.originView addSubview:self.view];
    [UIView animateWithDuration:0.3f animations:^{
        [self.view setTransform:CGAffineTransformIdentity];
        self.frame = self.originFrame;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    } completion:^(BOOL finished) {
        self.isFullscreenMode = NO;
        self.videoControl.fullScreenButton.hidden = NO;
        self.videoControl.shrinkScreenButton.hidden = YES;
    }];
}

//电池栏在左全屏
- (void)setDeviceOrientationLandscapeRight{
    if (self.isFullscreenMode) {
        return;
    }
    
    self.originFrame = self.view.frame;
    CGFloat height = [[UIScreen mainScreen] bounds].size.width;
    CGFloat width = [[UIScreen mainScreen] bounds].size.height;
    CGRect frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (!keyWindow) {
        keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
    }
    self.originView = self.view.superview;
    [keyWindow addSubview:self.view];
    [UIView animateWithDuration:0.3f animations:^{
        self.frame = frame;
        [self.view setTransform:CGAffineTransformMakeRotation(M_PI_2)];
    } completion:^(BOOL finished) {
        self.isFullscreenMode = YES;
        self.videoControl.fullScreenButton.hidden = YES;
        self.videoControl.shrinkScreenButton.hidden = NO;
        self.videoControl.backButton.hidden = NO;
        if (self.willChangeToFullscreenMode) {
            self.willChangeToFullscreenMode();
        }
    }];
    
}


//电池栏在右全屏
- (void)setDeviceOrientationLandscapeLeft{
    if (self.isFullscreenMode) {
        return;
    }
    self.originFrame = self.view.frame;
    CGFloat height = [[UIScreen mainScreen] bounds].size.width;
    CGFloat width = [[UIScreen mainScreen] bounds].size.height;
    CGRect frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (!keyWindow) {
        keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
    }
    self.originView = self.view.superview;
    [UIView animateWithDuration:0.3f animations:^{
        self.frame = frame;
        [self.view setTransform:CGAffineTransformMakeRotation(-M_PI_2)];
    } completion:^(BOOL finished) {
        self.isFullscreenMode = YES;
        self.videoControl.fullScreenButton.hidden = YES;
        self.videoControl.shrinkScreenButton.hidden = NO;
        if (self.willChangeToFullscreenMode) {
            self.willChangeToFullscreenMode();
        }
    }];
}



//开始计时
- (void)startDurationTimer
{
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(monitorVideoPlayback) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.durationTimer forMode:NSDefaultRunLoopMode];
}

//监控录像回放
- (void)monitorVideoPlayback
{
    double currentTime = floor(self.currentPlaybackTime);
    double totalTime = floor(self.duration);
    //设置时间
    [self setTimeLabelValues:currentTime totalTime:totalTime];
    self.videoControl.progressSlider.value = ceil(currentTime);
}

- (void)setTimeLabelValues:(double)currentTime totalTime:(double)totalTime {
    double minutesElapsed = floor(currentTime / 60.0);
    double secondsElapsed = fmod(currentTime, 60.0);
    NSString *timeElapsedString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesElapsed, secondsElapsed];
    
    double minutesRemaining = floor(totalTime / 60.0);;
    double secondsRemaining = floor(fmod(totalTime, 60.0));;
    NSString *timeRmainingString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesRemaining, secondsRemaining];
    
    self.videoControl.timeLabel.text = [NSString stringWithFormat:@"%@/%@",timeElapsedString,timeRmainingString];
}

- (void)stopDurationTimer
{
    [self.durationTimer invalidate];
}

- (void)fadeDismissControl
{
    [self.videoControl animateHide];
}
#pragma mark - Property
- (QPlayerView *)videoControl
{
    if (!_videoControl) {
        _videoControl = [[QPlayerView alloc] init];
    }
    return _videoControl;
}

- (UIView *)movieBackgroundView
{
    if (!_movieBackgroundView) {
        _movieBackgroundView = [UIView new];
        _movieBackgroundView.alpha = 0.0;
        _movieBackgroundView.backgroundColor = [UIColor blackColor];
    }
    return _movieBackgroundView;
}

- (void)setFrame:(CGRect)frame
{
    [self.view setFrame:frame];
    [self.videoControl setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.videoControl setNeedsLayout];
    [self.videoControl layoutIfNeeded];
}
#pragma mark - UISwipeGestureRecognizer
- (void)setSwipeGesture {
    /*
     //添加轻扫手势
     UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGesture:)];
     //设置轻扫的方向
     swipeGesture.direction = UISwipeGestureRecognizerDirectionUp; //默认向上
     [self.videoControl.rightView addGestureRecognizer:swipeGesture];
     //添加轻扫手势
     UISwipeGestureRecognizer *swipeGestureDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGesture:)];
     //设置轻扫的方向
     swipeGestureDown.direction = UISwipeGestureRecognizerDirectionDown; //默认向下
     [self.videoControl.rightView addGestureRecognizer:swipeGestureDown];
     
     //添加轻扫手势
     UISwipeGestureRecognizer *brightnessSwipeGestureUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(brightnessSwipeGesture:)];
     //设置轻扫的方向
     brightnessSwipeGestureUp.direction = UISwipeGestureRecognizerDirectionUp; //默认向上
     [self.videoControl.leftView addGestureRecognizer:brightnessSwipeGestureUp];
     //添加轻扫手势
     UISwipeGestureRecognizer *brightnesssSwipeGestureDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(brightnessSwipeGesture:)];
     //设置轻扫的方向
     brightnesssSwipeGestureDown.direction = UISwipeGestureRecognizerDirectionDown; //默认向下
     [self.videoControl.leftView addGestureRecognizer:brightnesssSwipeGestureDown];
     */
    
    
    //滑动手势
    UIPanGestureRecognizer *brightnessPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(brightnessMoveAction:)];
    [brightnessPanRecognizer setMinimumNumberOfTouches:1];
    [brightnessPanRecognizer setMaximumNumberOfTouches:1];
    [brightnessPanRecognizer setDelegate:self];
    [self.videoControl.leftView addGestureRecognizer:brightnessPanRecognizer];
    
    //音量滑动手势
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveAction:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelegate:self];
    [self.videoControl.rightView addGestureRecognizer:panRecognizer];
    
    
    
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    NSLog(@"点击");
    CGPoint translatedPointLeftView = [gestureRecognizer locationInView:self.videoControl.leftView];
    CGPoint translatedPointRightView = [gestureRecognizer locationInView:self.videoControl.rightView];
    
    NSLog(@"%f,%f\n %f,%f",translatedPointLeftView.x,translatedPointLeftView.y,translatedPointRightView.x,translatedPointRightView.y);
    self.lastX = 0;
    self.lastY = 0;
    self.gestureStatus = -1;
    return YES;
}

// called before touchesBegan:withEvent: is called on the gesture recognizer for a new touch. return NO to prevent the gesture recognizer from seeing this touch
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return YES;
}

-(void)moveAction:(UIPanGestureRecognizer*)gestureRecognizer {
    CGPoint translatedPoint = [gestureRecognizer translationInView:self.videoControl.rightView];
    NSLog(@"%f,%f",translatedPoint.x,translatedPoint.y);
    if (self.gestureStatus == -1) {//刚刚触发拖动
        if (translatedPoint.x*translatedPoint.x>translatedPoint.y*translatedPoint.y) {
            //触发进度
            self.gestureStatus = 1;
            //            self.second = floor(self.currentPlaybackTime);
        } else {
            //触发音量
            self.gestureStatus = 0;
        }
    } else if (self.gestureStatus == 0){//音量
        MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
        if (self.lastY>translatedPoint.y&&musicPlayer.volume<0.99) {
            musicPlayer.volume = musicPlayer.volume+0.02;
        }
        if (self.lastY<translatedPoint.y&&musicPlayer.volume>0.01) {
            musicPlayer.volume = musicPlayer.volume-0.02;
        }
        self.lastY = translatedPoint.y;
    }
    /*
     else if (self.gestureStatus == 1){//进度
     [self pause];
     [self.videoControl cancelAutoFadeOutControlBar];
     if (self.showTimeView == nil) {
     UIView *showTimeView = [[UIView alloc]initWithFrame:CGRectMake(200, 100, 200, 100)];
     self.showTimeView = showTimeView;
     }
     [self.showTimeView setAlpha:0.7f];
     [self.showTimeView setBackgroundColor:[UIColor blackColor]];
     [self.showTimeView.layer setCornerRadius:8];
     [self.view addSubview:self.showTimeView];
     [self.showTimeView setHidden:NO];
     if (self.lastX<translatedPoint.x && self.second < floor(self.duration)) {
     self.second =self.second + floor(self.duration) *0.005;
     }
     if (self.lastX>translatedPoint.x && self.second >0) {
     self.second = self.second - floor(self.duration)*0.005;
     }
     self.lastX = translatedPoint.x;
     if (self.timeShowLabel == nil) {
     UILabel *timeShowLabel = [[UILabel alloc]initWithFrame:self.showTimeView.bounds];
     self.timeShowLabel = timeShowLabel;
     [self.showTimeView addSubview:self.timeShowLabel];
     [self.timeShowLabel setFont:[UIFont boldSystemFontOfSize:18]];
     [self.timeShowLabel setTextAlignment:NSTextAlignmentCenter];
     [self.timeShowLabel setBackgroundColor:[UIColor clearColor]];
     [self.timeShowLabel setTextColor:[UIColor whiteColor]];
     }
     [self.timeShowLabel setText:[NSString stringWithFormat:@"%@ / %@",[self secondTimeChange:[NSString stringWithFormat:@"%f",self.second]] ,[self secondTimeChange:[NSString stringWithFormat:@"%f",floor(self.duration)]]]];
     }
     if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
     NSLog(@"手指离开");
     if (self.gestureStatus == 1) {
     
     
     double currentTime = self.second;
     double totalTime = floor(self.duration);
     //设置时间
     [self setTimeLabelValues:currentTime totalTime:totalTime];
     self.videoControl.progressSlider.value = ceil(currentTime);
     [self setCurrentPlaybackTime:currentTime];
     [self play];
     [self.videoControl autoFadeOutControlBar];
     }
     [self.showTimeView setHidden:YES];
     }
     */
}

-(void)brightnessMoveAction:(UIPanGestureRecognizer*)gestureRecognizer {
    CGPoint translatedPoint = [gestureRecognizer translationInView:self.videoControl.leftView];
    NSLog(@"%f,%f",translatedPoint.x,translatedPoint.y);
    float value = [UIScreen mainScreen].brightness;
    if (self.gestureStatus == -1) {//刚刚触发拖动
        if (translatedPoint.x*translatedPoint.x>translatedPoint.y*translatedPoint.y) {
            //触发进度
            self.gestureStatus = 1;
            //            self.second = floor(self.currentPlaybackTime);
        } else {
            //触发音量
            self.gestureStatus = 0;
        }
    } else if (self.gestureStatus == 0){//音量
        MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
        if (self.lastY>translatedPoint.y&&value<0.99) {
            value = value + 0.02;
        }
        if (self.lastY<translatedPoint.y&&value>0.01) {
            value = value - 0.02;
        }
        //    设置系统屏幕的亮度值
        [[UIScreen mainScreen] setBrightness:value];
        
        self.lastY = translatedPoint.y;
    }
    /*
     else if (self.gestureStatus == 1){//进度
     [self pause];
     [self.videoControl cancelAutoFadeOutControlBar];
     if (self.showTimeView == nil) {
     UIView *showTimeView = [[UIView alloc]initWithFrame:CGRectMake(200, 100, 200, 100)];
     self.showTimeView = showTimeView;
     }
     [self.showTimeView setAlpha:0.7f];
     [self.showTimeView setBackgroundColor:[UIColor blackColor]];
     [self.showTimeView.layer setCornerRadius:8];
     [self.view addSubview:self.showTimeView];
     [self.showTimeView setHidden:NO];
     if (self.lastX<translatedPoint.x && self.second < floor(self.duration)) {
     self.second =self.second + floor(self.duration) *0.005;
     }
     if (self.lastX>translatedPoint.x && self.second >0) {
     self.second = self.second - floor(self.duration)*0.005;
     }
     self.lastX = translatedPoint.x;
     if (self.timeShowLabel == nil) {
     UILabel *timeShowLabel = [[UILabel alloc]initWithFrame:self.showTimeView.bounds];
     self.timeShowLabel = timeShowLabel;
     [self.showTimeView addSubview:self.timeShowLabel];
     [self.timeShowLabel setFont:[UIFont boldSystemFontOfSize:18]];
     [self.timeShowLabel setTextAlignment:NSTextAlignmentCenter];
     [self.timeShowLabel setBackgroundColor:[UIColor clearColor]];
     [self.timeShowLabel setTextColor:[UIColor whiteColor]];
     }
     [self.timeShowLabel setText:[NSString stringWithFormat:@"%@ / %@",[self secondTimeChange:[NSString stringWithFormat:@"%f",self.second]] ,[self secondTimeChange:[NSString stringWithFormat:@"%f",floor(self.duration)]]]];
     }
     if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
     NSLog(@"手指离开");
     if (self.gestureStatus == 1) {
     
     
     double currentTime = self.second;
     double totalTime = floor(self.duration);
     //设置时间
     [self setTimeLabelValues:currentTime totalTime:totalTime];
     self.videoControl.progressSlider.value = ceil(currentTime);
     [self setCurrentPlaybackTime:currentTime];
     [self play];
     [self.videoControl autoFadeOutControlBar];
     }
     [self.showTimeView setHidden:YES];
     }
     */
    
}

//进度条秒数格式转换
- (NSString *)secondTimeChange:(NSString *)second
{
    int s = (int)[second doubleValue];
    int m = 0 ;
    int h = 0;
    if (s>=3600) {
        h = s/3600;
    }
    if ((s-h*3600)>=60) {
        m = (s-h*3600)/60;
    }
    s = s%60;
    
    NSString *string = [NSString stringWithFormat:@"%02d:%02d:%02d",h,m,s];
    return string;
}

/*
 
 //brightnessSwipeGesture
 -(void)brightnessSwipeGesture:(id)sender
 {
 
 UISwipeGestureRecognizer *swipe = sender;
 if (swipe.direction == UISwipeGestureRecognizerDirectionUp) {
 //向上轻扫做的事情
 [self brightnessAdd:VolumeStep * 2];
 }
 
 if (swipe.direction == UISwipeGestureRecognizerDirectionDown){
 //向下轻扫做的事情
 [self brightnessAdd:-VolumeStep * 2];
 }
 }
 
 //轻扫手势触发方法
 -(void)swipeGesture:(id)sender
 {
 UISwipeGestureRecognizer *swipe = sender;
 if (swipe.direction == UISwipeGestureRecognizerDirectionUp) {
 //向上轻扫做的事情
 [self volumeAdd:VolumeStep];
 }
 
 if (swipe.direction == UISwipeGestureRecognizerDirectionDown) {
 //向下轻扫做的事情
 [self volumeAdd:-VolumeStep];
 }
 }
 
 
 //声音增加
 - (void)volumeAdd:(CGFloat)step{
 [MPMusicPlayerController applicationMusicPlayer].volume += step;;
 }
 
 //亮度增加
 - (void)brightnessAdd:(CGFloat)step{
 //    获取系统屏幕当前的亮度值
 float value = [UIScreen mainScreen].brightness;
 value+= step;
 //    设置系统屏幕的亮度值
 [[UIScreen mainScreen] setBrightness:value];
 
 }
 */

#pragma mark - 取出视频图片
+ (UIImage*) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60) actualTime:NULL error:&thumbnailImageGenerationError];
    
    if (!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@", thumbnailImageGenerationError);
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
    
    return thumbnailImage;
}

- (void)dealloc
{
    [self cancelObserver];
}
- (void)cancelObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
