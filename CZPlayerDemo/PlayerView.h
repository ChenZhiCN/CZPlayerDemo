//
//  PlayerView.m
//  AVPlayer定制播放器
//
//  Created by cz on 16/10/19.
//  Copyright © 2016年 cz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^VideoEndPlayCallBack)(void);
typedef void(^FullScreenCallBack)(void);

@interface PlayerView : UIView 


@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, copy) VideoEndPlayCallBack videoEndPlayCallBack;
@property (nonatomic, copy) FullScreenCallBack fullScreenCallBack;

- (void)playWithUrl:(NSURL *)url;

- (void)play;

- (void)pause;

- (void)releasePlayer;

- (void)setFullScreenCallBack:(FullScreenCallBack)fullScreenCallBack;



@end
