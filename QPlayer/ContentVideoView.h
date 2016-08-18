//
//  ContentVideoView.h
//  QPlayer
//
//  Created by pactera on 16/7/19.
//  Copyright © 2016年 com.storyboard.pactera. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContentVideoView : UIView
//停止视频的播放
- (void)reset;

/** 进入最小化状态 */
@property (nonatomic, copy)void(^playerVeiwBackOrientationPortrait)(void);

/** 进入全屏状态 */
@property (nonatomic, copy)void(^playerVeiwChangeToFullscreenMode)(void);


@end
