//
//  QVideoPlayerViewController.h
//  QPlayer
//
//  Created by pactera on 16/7/18.
//  Copyright © 2016年 com.storyboard.pactera. All rights reserved.
//格式支持：MOV、MP4、M4V、与3GP等格式

#import <UIKit/UIKit.h>

@import MediaPlayer;

@interface QVideoPlayerViewController : MPMoviePlayerController
/** video.view 消失 */
@property (nonatomic, copy)void(^dimissCompleteBlock)(void);

/** 进入最小化状态 */
@property (nonatomic, copy)void(^willBackOrientationPortrait)(void);

/** 进入全屏状态 */
@property (nonatomic, copy)void(^willChangeToFullscreenMode)(void);

@property (nonatomic, assign) CGRect frame;

- (instancetype)initWithFrame:(CGRect)frame titleLabelTitlte:(NSString *)title;
- (void)showInWindow;
- (void)dismiss;

/**
 *  获取视频截图
 */
+ (UIImage*) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;

@end
