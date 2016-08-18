# QPlayer
基于MPMoviePlayerController
视频播放器  可修改声音 亮度   （快进注释掉了）
支持大屏小屏播放

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
