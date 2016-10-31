//
//  PlayerView.m
//  AVPlayer定制播放器
//
//  Created by cz on 16/10/19.
//  Copyright © 2016年 cz. All rights reserved.
//

#import "PlayerView.h"

#define kTimeFont [UIFont systemFontOfSize:11]
#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface PlayerView ()
{
    CGRect _currentFrame;
    UIView *_superView;
}

@property (nonatomic, strong) UIButton *playOrPauseBtn;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, weak) UIView *bgView;
@property (weak, nonatomic)  UIProgressView *bufferProgessView;
@property (weak, nonatomic)  UISlider *progessSlider;
@property (weak, nonatomic)  UILabel *timeLabel;
@property (weak, nonatomic)  UILabel *totalTimeLabel;
@property (weak, nonatomic)  UIButton *fullScreen;
@property (nonatomic, assign) NSTimeInterval duration;
@property (weak, nonatomic)  UILabel *partLabel;

@property (weak, nonatomic) UIButton *hiddenBtn;
@property (weak, nonatomic) UIButton *backBtn;
@property (nonatomic, weak) UIActivityIndicatorView *loadIndicator;

@end

@implementation PlayerView

- (void)releasePlayer
{
    [self removeVideoKVO];
    [_player.currentItem cancelPendingSeeks];
    [_player.currentItem.asset cancelLoading];
    [self pause];
    _playerItem = nil;
    _player = nil;
    [self removeFromSuperview];

}

- (void)play
{
    [self btnClick:1];
    _playOrPauseBtn.selected = YES;
    
}

- (void)pause
{
    [self btnClick:0];
    _playOrPauseBtn.selected = NO;
}


- (void)playWithUrl:(NSURL *)url
{
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    [self setPlayerItem:item];
}

#pragma mark - 设置播放的视频
- (void)setPlayerItem:(AVPlayerItem *)playerItem
{
    if (_playerItem) {
        [self removeVideoKVO];
    }
    _playerItem = playerItem;
//    NSLog(@"%@", playerItem);
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    [self addVideoKVO];
    [self play];
    
}

- (void)removeVideoKVO
{
    if (_playerItem) {
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    }

}

- (void)addVideoKVO
{
    //侦听_playerItem的status属性，如果当属性值发生变化后就会触发Observer方法。
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //观察缓冲数据
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
     
                                             selector:@selector(playerItemDidReachEnd)
     
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
     
                                               object:_playerItem];
}



- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configUI];
    }
    return self;
}

- (void)configUI
{
    _currentFrame = self.frame;
    _player = [[AVPlayer alloc] init];
    //安放播放器
    AVPlayerLayer *layer = (AVPlayerLayer *)self.layer;
    layer.player = _player;
    
    _playOrPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playOrPauseBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [_playOrPauseBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateSelected];
    [_playOrPauseBtn addTarget:self action:@selector(selectPlayBtn:)  forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_playOrPauseBtn];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [UIColor blackColor];
    view.alpha = 0.85;
    [self addSubview:view];_bgView = view;
    
    UIProgressView *progress = [[UIProgressView alloc] init];
    [self.bgView addSubview:progress];_bufferProgessView = progress;
    
    UISlider *slider = [[UISlider alloc] init];
    UIImage * image = [UIImage imageNamed:@"dot"];
    
    [slider setThumbImage:image forState:UIControlStateNormal];
    [slider addTarget:self action:@selector(progessSliderHandle:) forControlEvents:UIControlEventValueChanged];
    [self.bgView addSubview:slider]; _progessSlider = slider;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"00:00";
    label.font =kTimeFont;
    label.textColor = [UIColor whiteColor];
    [self.bgView addSubview:label]; _timeLabel = label;
    
    UILabel *label1 = [[UILabel alloc] init];
    label1.text = @"00:00";
    label1.font = kTimeFont;
    label1.textColor = [UIColor whiteColor];
    [self.bgView addSubview:label1]; _totalTimeLabel = label1;
    
    UILabel *label2 = [[UILabel alloc] init];
    label2.text = @"/";
    label2.font = [UIFont systemFontOfSize:11];
    label2.textColor = [UIColor whiteColor];
    [self.bgView addSubview:label2];_partLabel = label2;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@"nonfullscreen"] forState:UIControlStateSelected];
    [btn addTarget:self action:@selector(toFullScreen:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:btn]; _fullScreen = btn;
    
    //修改滑块的样式
    [self.progessSlider setMaximumTrackTintColor:[UIColor clearColor]];
    [self.progessSlider setMinimumTrackTintColor:[UIColor lightGrayColor]];
    
    UIButton *hiddenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    hiddenBtn.backgroundColor = [UIColor clearColor];
    [hiddenBtn addTarget:self action:@selector(pushBgView) forControlEvents:UIControlEventTouchDown];
    hiddenBtn.hidden = YES;
    [self addSubview:hiddenBtn];
    _hiddenBtn =hiddenBtn;
    
    
    //加菊花
    UIActivityIndicatorView *loadIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self addSubview:loadIndicator];
    _loadIndicator = loadIndicator;
    [_loadIndicator startAnimating];

    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.backgroundColor = [UIColor clearColor];
    [backBtn setImage:[UIImage imageNamed:@"ba_back"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(goBackSmallScreen) forControlEvents:UIControlEventTouchDown];
    backBtn.hidden = YES;
    [self addSubview:backBtn];
    _backBtn = backBtn;
}

- (void)toFullScreen:(UIButton *)sender
{
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        [self removeFromSuperview];
        self.transform = CGAffineTransformMakeRotation(M_PI_2);
//        NSLog(@"%f", M_PI_2);
        self.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
        self.layer.frame =  CGRectMake(0,0, kScreenWidth, kScreenHeight);
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        [[UIApplication sharedApplication].keyWindow bringSubviewToFront:self];
        [UIApplication sharedApplication].statusBarHidden = YES;
        self.backBtn.hidden = NO;
    }
    else
    {
        [self goBackSmallScreen];
    }
}

- (void)goBackSmallScreen
{
    [UIApplication sharedApplication].statusBarHidden = NO;
    self.transform = CGAffineTransformMakeRotation(0);
    self.frame = _currentFrame;
    self.backBtn.hidden = YES;
    self.fullScreen.selected = NO;
//    [self removeFromSuperview];
    if (_fullScreenCallBack)
    {
        _fullScreenCallBack();
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    NSLog(@"%ld", _playerItem.status);
    //播放的状态改变了
    if ([keyPath isEqualToString:@"status"])
    {
        //AVPlayerItemStatusReadyToPlay:可以播放了
        [_loadIndicator stopAnimating];
        if ([change[NSKeyValueChangeNewKey] integerValue] == AVPlayerItemStatusReadyToPlay)
        {
            //获取总时间
            CMTime durationTime = _playerItem.duration;
            //把CMTime转化为秒
            _duration = CMTimeGetSeconds(durationTime);
            //_duration = durationTime.value / durationTime.timescale;
            
            //赋值
            self.totalTimeLabel.text = [self timeFormaterWithSeconds:_duration];
            
            //刷新当前的进度
            [self updatePlayerProgess];
        }
        //由于网络，缓冲数据导致AVPlayer会暂停，暂停需要手动启动。
        else if ([change[NSKeyValueChangeNewKey] integerValue] == AVPlayerItemStatusFailed)
        {
            [self pause];
            [_loadIndicator startAnimating];
            //延迟5秒钟播放或者根据缓冲butter > currentTime
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (_player.timeControlStatus == AVPlayerTimeControlStatusPaused) {
                    [self play];
                }
            });
        }
    }
    //有缓冲数据
    else if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        //_playerItem.loadedTimeRanges -> NSArray<NSValue *>
        
        //获取缓冲数据
        CMTimeRange timeRange = [[change[NSKeyValueChangeNewKey] firstObject] CMTimeRangeValue];
        //获取缓冲的时间 =  start + duration
        NSTimeInterval buffer = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
        
        //修改缓冲条的比例
        self.bufferProgessView.progress = buffer / _duration;
        
        /*
         if (暂停)
         {
         在播放
         }
         */
    }
}

/**
 *  刷新当前的进度
 */
- (void)updatePlayerProgess
{
    
    __weak PlayerView *weakSelf = self;
    
    //类似定时器
    /*
     参数1：多久刷新一次
     参数2：usingBlock在哪个队列里面执行
     参数3：每隔多久会执行的代码
     */
    /*
     value(当前帧) / timeScale(帧率) = 总秒数
     
     CMTimeMake(当前帧, 帧率)
     */
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {

        //修改当前时间   self <-> block
        NSTimeInterval currentSecond = CMTimeGetSeconds(weakSelf.playerItem.currentTime);
        
        //修改当前时间
        weakSelf.timeLabel.text = [weakSelf timeFormaterWithSeconds:currentSecond];
        //修改进度
        weakSelf.progessSlider.value = currentSecond / weakSelf.duration;
    }];
}

/**
 *  时间格式化，转化为mm:ss

 */
- (NSString *)timeFormaterWithSeconds:(NSTimeInterval)seconds
{
    int m = seconds/60;
    int s = (int)seconds % 60;
    
    return [NSString stringWithFormat:@"%02d:%02d",m,s];
}



#pragma mark - 更新当前时间
- (void)progessSliderHandle:(UISlider *)sender
{
    CGFloat value = sender.value;
    /*
     value/timeScale = 总秒数
     X / timeScale = 总秒数 ====>  X = timeScale * 总秒数
     */
    CMTime time = _playerItem.currentTime;
    //修改当前帧
    time.value = time.timescale * (_duration * value);
    
    //跳转到指定的time
    [_playerItem seekToTime:time];
    
}


- (void)selectPlayBtn:(UIButton *)sender
{
    sender.selected = !sender.isSelected;
    
    if (sender.selected)
    {
        [self btnClick:1];
    }
    else
    {
        [self btnClick:0];
    }
}

- (void)btnClick:(BOOL)play
{

    if (play) {
        //播放
        [_player play];
        //1s后按钮图片隐藏
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:1 animations:^{
                _playOrPauseBtn.hidden = YES;
                _hiddenBtn.hidden = NO;
                _bgView.hidden = YES;
                _backBtn.hidden = YES;
            }];
        });
    }
    else
    {
        //暂停
        [_player pause];

    }


}

- (void)pushBgView
{
    if(_backBtn.hidden && _fullScreen.selected)
    {
        _backBtn.hidden = NO;
    }
    _bgView.hidden = NO;
    _hiddenBtn.hidden = YES;
    if (_playOrPauseBtn.hidden) {
        _playOrPauseBtn.hidden = NO;
    }
}

/**
 *  修改当前layer的类为AVPlayerLayer
 */
+ (Class)layerClass
{
    return [AVPlayerLayer class];
}



- (void)playerItemDidReachEnd
{
    //播放完毕,移除这个View,刷新tbView
    if (self.videoEndPlayCallBack)
    {
        self.videoEndPlayCallBack();
    }

    self.hidden = YES;
    if (_fullScreen.selected) {
        [self goBackSmallScreen];
    }
    
}


- (void)layoutSubviews
{
    _playOrPauseBtn.frame = self.bounds;
    _playOrPauseBtn.imageView.contentMode = UIViewContentModeCenter;
    
    self.backgroundColor = [UIColor blackColor];
    _bgView.frame = CGRectMake(0, self.bounds.size.height - 30, self.bounds.size.width, 30);
    _bufferProgessView.frame = CGRectMake(40, 15, self.bounds.size.width - 40 - 120, 30);
    _timeLabel.frame = CGRectMake(CGRectGetMaxX(_bufferProgessView.frame) + 5 , 0, 35, 30);
    _partLabel.frame = CGRectMake(CGRectGetMaxX(_timeLabel.frame), 0, 5, 30);
    _totalTimeLabel.frame = CGRectMake(CGRectGetMaxX(_timeLabel.frame) + 5 , 0, 35, 30);
    _fullScreen.frame = CGRectMake(CGRectGetMaxX(_totalTimeLabel.frame)+ 5, 0, 30, 30);
    CGRect rect = _bufferProgessView.frame;
    rect.origin.x -= 2.5;
    rect.size.width += 2.5;
    _progessSlider.frame = rect;
    _hiddenBtn.frame = self.bounds;
    _loadIndicator.frame = CGRectMake(self.bounds.size.width/2 - 20, self.bounds.size.height/2 - 20, 40, 40);
    
    _backBtn.frame = CGRectMake(10, 10, 30, 30);
}

@end
