//
//  ContentVideoView.m
//  QPlayer
//
//  Created by pactera on 16/7/19.
//  Copyright © 2016年 com.storyboard.pactera. All rights reserved.
//

#import "ContentVideoView.h"
#import "QVideoPlayerViewController.h"

static const CGFloat VideoPlayerBtnHeight = 70.0f;
@interface ContentVideoView ()
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UILabel *playCount;
@property (strong, nonatomic) UILabel *playTime;
@property (strong, nonatomic) UIButton *playBtn;
@property (nonatomic, strong) QVideoPlayerViewController  *videoController;
@end
@implementation ContentVideoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUI];
        [self setDate];
        [self configObserver];
    }
    return self;
}

- (void)setUI {
    self.autoresizingMask = UIViewAutoresizingNone;
    self.imageView.userInteractionEnabled = YES;
    [self.imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showPicture)]];
    [self addSubview:self.imageView];
    [self addSubview:self.playCount];
    [self addSubview:self.playTime];
    [self addSubview:self.playBtn];
}

-(void)showPicture {
//    QVideoPlayerViewController *showPicVc = [[XFDetailPictureController alloc]init];
//    showPicVc.topic = self.topic;
//    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:showPicVc animated:YES completion:nil];
}

- (void)setDate {
    self.playCount.text = [NSString stringWithFormat:@"%d次播放",10001];
    [self.imageView setImage:[UIImage imageNamed:@"bg.jpg"]];
    self.playTime.text = [NSString stringWithFormat:@"%02d:%02d", 10000 / 60, 10000 % 60];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    self.playCount.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetHeight(self.bounds) - VideoPlayerBtnHeight*0.4, VideoPlayerBtnHeight*1.5, VideoPlayerBtnHeight*0.4);
        self.playTime.frame = CGRectMake(CGRectGetWidth(self.bounds) - CGRectGetWidth(self.playCount.bounds), CGRectGetHeight(self.bounds) - CGRectGetHeight(self.playCount.bounds), CGRectGetWidth(self.playCount.bounds), CGRectGetHeight(self.playCount.bounds));
    self.playBtn.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    [self.playCount setNeedsLayout];
    [self.playCount layoutIfNeeded];
    [self.playTime setNeedsLayout];
    [self.playTime layoutIfNeeded];

    
}

- (void)configObserver {
    [self.playBtn addTarget:self action:@selector(playButtonClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)playButtonClick:(UIButton *)button {
    NSURL *url = [NSURL URLWithString:@"http://wvideo.spriteapp.cn/video/2016/0718/578c468a9cedb_wpd.mp4"];
//    NSURL *url = [NSURL URLWithString:@"http://content.viki.com/test_ios/ios_240.m3u8"];

    //http://content.viki.com/test_ios/ios_240.m3u8
//    NSURL *url = [NSURL URLWithString:@"http://bvideo.spriteapp.cn/video/2016/0717/578a6c7c06204_wpd.mp4"];
    //http://v.youku.com/player/getRealM3U8/vid/XNTY2MTAxOTUy/type/video.m3u8
    //@"http://bvideo.spriteapp.cn/video/2016/0717/578a6c7c06204_wpd.mp4"
    //@"http://bvideo.spriteapp.cn/video/2016/0706/577ce594e2b61_wpd.mp4"
    //@"http://bvideo.spriteapp.cn/video/2016/0719/578dd2c6b98f2_wpd.mp4"
    //@"http://bvideo.spriteapp.cn/video/2016/0718/578cbe7f961c5_wpd.mp4"
    //_videouri	__NSCFString *	@"http://bvideo.spriteapp.cn/video/2016/0718/578c4713032b4_wpd.mp4"	0x00007f8514019a20
    //_videouri	__NSCFString *	@"http://bvideo.spriteapp.cn/video/2016/0707/577dd1b237dce_wpd.mp4"	0x00007f8511cc7ff0
    //_videouri	__NSCFString *	@"http://bvideo.spriteapp.cn/video/2016/0719/578d9ee0b4d2f_wpd.mp4"	0x00007f8511cfad60
    //_videouri	__NSCFString *	@"http://bvideo.spriteapp.cn/video/2016/0719/578d04a396ada_wpd.mp4"	0x00007f8511ce0c00
    //_videouri	__NSCFString *	@"http://bvideo.spriteapp.cn/video/2016/0718/578cb4ed933dd_wpd.mp4"	0x00007fdd025541e0
    [self playVideoWithURL:url titleLabelTitlte:@"bvideo.spriteapp.cn"];

    [self addSubview:self.videoController.view];

}

//核心代码 
- (void)playVideoWithURL:(NSURL *)url titleLabelTitlte:(NSString *)title{
    if (!self.videoController) {
        self.videoController = [[QVideoPlayerViewController alloc] initWithFrame:self.imageView.bounds titleLabelTitlte:title];
        __weak typeof(self)weakSelf = self;
        [weakSelf.videoController setDimissCompleteBlock:^{
            [weakSelf.videoController dismiss];
            weakSelf.videoController = nil;
        }];
        [self.videoController setWillBackOrientationPortrait:^{
            if (weakSelf.playerVeiwBackOrientationPortrait) {
                weakSelf.playerVeiwBackOrientationPortrait();
            }
        }];
        
        [self.videoController setWillChangeToFullscreenMode:^{
            if (weakSelf.playerVeiwChangeToFullscreenMode) {
                weakSelf.playerVeiwChangeToFullscreenMode();
            }
        }];
    }
    self.videoController.contentURL = url;
    
}

//停止视频的播放
- (void)reset {
    [self.videoController dismiss];
    self.videoController = nil;
}


- (UIImageView *)imageView {
    if (!_imageView) {
        
        _imageView = [[UIImageView alloc]init];
        
    }
    return _imageView;
}

- (UILabel *)playCount {
    if (!_playCount) {
        _playCount = [[UILabel alloc]init];
        _playCount.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.5];
        _playCount.textAlignment = NSTextAlignmentCenter;
        _playCount.textColor = [UIColor whiteColor];
    }
    return _playCount;
}

- (UILabel *)playTime {
    if (!_playTime) {
        _playTime = [[UILabel alloc]init];
        _playTime.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.5];
        _playTime.textAlignment = NSTextAlignmentCenter;
        _playTime.textColor = [UIColor whiteColor];
        
    }
    return _playTime;
}

- (UIButton *)playBtn {
    if (!_playBtn) {
        
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage imageNamed:@"video-play"] forState:UIControlStateNormal];
        _playBtn.bounds = CGRectMake(0, 0, VideoPlayerBtnHeight, VideoPlayerBtnHeight);
    }
    return _playBtn;
}

@end
