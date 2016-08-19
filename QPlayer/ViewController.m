//
//  ViewController.m
//  QPlayer
//
//  Created by pactera on 16/7/18.
//  Copyright © 2016年 com.storyboard.pactera. All rights reserved.
//

#import "ViewController.h"
#import "QVideoPlayerViewController.h"
#import "ContentVideoView.h"


@interface ViewController ()
@property (nonatomic, strong) QVideoPlayerViewController  *videoController;
@property (nonatomic, strong) ContentVideoView *videoView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    self.videoView = [[ContentVideoView alloc]init];
    self.videoView.frame = CGRectMake(0, 64, width, width*(9.0/16.0));
    __weak typeof(self)weakSelf = self;
    
    [self.videoView setPlayerVeiwBackOrientationPortrait:^{
        [weakSelf toolbarHidden:NO];
        
    }];
    [self.videoView setPlayerVeiwChangeToFullscreenMode:^{
        [weakSelf toolbarHidden:YES];
    }];
    
    [self.view addSubview:self.videoView];

    
    // Do any additional setup after loading the view, typically from a nib.
//    [self playVideo];
}

- (void)playVideo{
    NSURL *url = [NSURL URLWithString:@"http://wvideo.spriteapp.cn/video/2016/0718/578c468a9cedb_wpd.mp4"];
    [self addVideoPlayerWithURL:url];
}
- (void)addVideoPlayerWithURL:(NSURL *)url{
    if (!self.videoController) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        self.videoController = [[QVideoPlayerViewController alloc] initWithFrame:CGRectMake(0, 64, width, width*(9.0/16.0)) titleLabelTitlte:@"titleLabel"];
        __weak typeof(self)weakSelf = self;
        [self.videoController setDimissCompleteBlock:^{
            weakSelf.videoController = nil;
        }];
        
        [self.videoController setWillBackOrientationPortrait:^{
            [weakSelf toolbarHidden:NO];
        }];

        [self.videoController setWillChangeToFullscreenMode:^{
            [weakSelf toolbarHidden:YES];
        }];
        [self.view addSubview:self.videoController.view];
    }
    self.videoController.contentURL = url;

}

//隐藏navigation tabbar 电池栏
- (void)toolbarHidden:(BOOL)Bool{
    self.navigationController.navigationBar.hidden = Bool;
    self.tabBarController.tabBar.hidden = Bool;
    [[UIApplication sharedApplication] setStatusBarHidden:Bool withAnimation:UIStatusBarAnimationFade];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
