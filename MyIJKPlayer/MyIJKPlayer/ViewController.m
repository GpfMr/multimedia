//
//  ViewController.m
//  MyIJKPlayer
//
//  Created by Gpf 郭 on 2022/9/28.
//

#import "ViewController.h"
#import <IJKMediaFramework/IJKMediaFramework.h>

@interface ViewController ()
@property (atomic, retain) id <IJKMediaPlayback> player;
@property (weak, nonatomic) IBOutlet UIView *playView;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *rateBtn;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
@property (weak, nonatomic) IBOutlet UIButton *definitionBtn;
@property (strong, nonatomic) UISlider *slider;
@property (nonatomic, strong) UIView *playerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /**
     * 苹果拉流地址：http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8
     *  MP4地址：http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4       //网络mp4
     */
    
    // 播放网络视频并进行缓存
    IJKFFOptions * options = nil;
    NSURL * playUrl = nil;
    if (YES){
        // 缓存并播放远程视频
        NSString * url = @"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4";
        NSString *libraryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
        libraryPath = [libraryPath stringByAppendingString:@"/Caches/"];
        NSString *fileName = [url.pathComponents lastObject];
        libraryPath = [libraryPath stringByAppendingString:fileName];
        NSString *mapPath = [libraryPath stringByAppendingString:@"/map/"];
        mapPath = [mapPath stringByAppendingString:fileName];
        mapPath = [mapPath stringByAppendingString:@".mp4"];

        options = [IJKFFOptions optionsByDefault];
        [options setFormatOptionValue:libraryPath forKey:@"cache_file_path"];
        [options setFormatOptionValue:mapPath forKey:@"cache_map_path"];
        [options setFormatOptionIntValue:1 forKey:@"parse_cache_map"];
        [options setFormatOptionIntValue:1 forKey:@"auto_save_map"];
        NSString *strCacheUrl = @"ijkio:cache:ffio:";
        strCacheUrl = [strCacheUrl stringByAppendingString:url];
        playUrl = [NSURL URLWithString:strCacheUrl];
    }
    
    if (NO) {
        // 播放本地/资源包中的视频
        NSString *string = [[NSBundle mainBundle] pathForResource:@"video01" ofType:@"mp4"];
        playUrl = [NSURL URLWithString:string];
    }
    
    if (NO) {
        // 直播
        options = [IJKFFOptions optionsByDefault];
        // Param for living
        //最大缓存大小是3秒，可以依据自己的需求修改
        [options setPlayerOptionIntValue:3000 forKey:@"max_cached_duration"];
        //无限读
        [options setPlayerOptionIntValue:1 forKey:@"infbuf"];
        //关闭播放器缓冲
        [options setPlayerOptionIntValue:0 forKey:@"packet-buffering"];
        playUrl = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
    }
    
    
//    NSURL *url = [NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"];
    _player = [[IJKFFMoviePlayerController alloc] initWithContentURL:playUrl withOptions:options];
    _player.playbackRate = 1;   // 调节播放速率
    _player.playbackVolume = 3; // 调节声音大小
    _player.scalingMode = IJKMPMovieScalingModeAspectFit;   // 展示模式
    
    /**
     //  关于option的一些设置
     -------------CodecOption-------------
     //解码参数，画面更清晰
     [options setCodecOptionIntValue:IJK_AVDISCARD_DEFAULT forKey:@"skip_loop_filter"];
     [options setCodecOptionIntValue:IJK_AVDISCARD_DEFAULT forKey:@"skip_frame"];
    
     -------------PlayerOption-------------
     //在视频帧处理不过来的时候丢弃一些帧达到同步的效果
     //跳帧开关，如果cpu解码能力不足，可以设置成5，否则会引起音视频不同步，也可以通过设置它来跳帧达到倍速播放
     [options setPlayerOptionIntValue:5 forKey:@"framedrop"];
     //最大fps
     [options setPlayerOptionIntValue:30 forKey:@"max-fps"];
     //帧速率(fps) 可以改，确认非标准桢率会导致音画不同步，所以只能设定为15或者29.97
     [options setPlayerOptionIntValue:29.97 forKey:@"r"];
     //设置音量大小，256为标准音量。（要设置成两倍音量时则输入512，依此类推）
     [options setPlayerOptionIntValue:512 forKey:@"vol"];
     //指定最大宽度
     [options setPlayerOptionIntValue:960 forKey:@"videotoolbox-max-frame-width"];
     //开启/关闭 硬解码（硬件解码CPU消耗低。软解，更稳定）
     [options setPlayerOptionIntValue:0 forKey:@"videotoolbox"];
     //是否有声音
     [options setPlayerOptionIntValue:1  forKey:@"an"];
     //是否有视频
     [options setPlayerOptionIntValue:1  forKey:@"vn"];
     //每处理一个packet之后刷新io上下文
     [options setPlayerOptionIntValue:1 forKey:@"flush_packets"];
     //是否禁止图像显示(只输出音频)
     [options setPlayerOptionIntValue:1 forKey:@"nodisp"];
     //
     [options setPlayerOptionIntValue:0 forKey:@"start-on-prepared"];
     //
     [options setPlayerOptionIntValue:@"fcc-_es2" forKey:@"overlay-format"];
     //
     [options setPlayerOptionIntValue:3 forKey:@"video-pictq-size"];
     //
     [options setPlayerOptionIntValue:25 forKey:@"min-frames"];
     -------------FormatOption-------------
     //如果是rtsp协议，可以优先用tcp(默认是用udp)
     [options setFormatOptionValue:@"tcp" forKey:@"rtsp_transport"];
     //播放前的探测Size，默认是1M, 改小一点会出画面更快
     [options setFormatOptionIntValue:1024*16*0.5 forKey:@"probsize"];
     //播放前的探测时间
     [options setFormatOptionIntValue:50000 forKey:@"analyzeduration"];
     //自动转屏开关
     [options setFormatOptionIntValue:0 forKey:@"auto_convert"];
     //重连次数
     [options setFormatOptionIntValue:1 forKey:@"reconnect"];
     //超时时间，timeout参数只对http设置有效。若果你用rtmp设置timeout，ijkplayer内部会忽略timeout参数。rtmp的timeout参数含义和http的不一样。
     [options setFormatOptionIntValue:30 * 1000 * 1000 forKey:@"timeout"];
     //
     [options setFormatOptionIntValue:@"nobuffer" forKey:@"fflags"];
     //
     [options setFormatOptionIntValue:@"ijkplayer" forKey:@"user-agent"];
     //
     [options setFormatOptionIntValue:0 forKey:@"safe"];
     //
     [options setFormatOptionIntValue:0 forKey:@"http-detect-range-support"];
     //
     [options setFormatOptionIntValue:4628439040 forKey:@"ijkapplication"];
     //
     [options setFormatOptionIntValue:6176477408 forKey:@"ijkiomanager"];

     
     skip_loop_filter参数相关
     // for codec option 'skip_loop_filter' and 'skip_frame'
     typedef enum IJKAVDiscard {
          We leave some space between them for extensions (drop some
          * keyframes for intra-only or drop just some bidir frames).
         IJK_AVDISCARD_NONE    =-16, ///< discard nothing
         IJK_AVDISCARD_DEFAULT =  0, ///< discard useless packets like 0 size packets in avi
         IJK_AVDISCARD_NONREF  =  8, ///< discard all non reference     是抛弃非参考帧（I帧）
         IJK_AVDISCARD_BIDIR   = 16, ///< discard all bidirectional frames      抛弃B帧
         IJK_AVDISCARD_NONKEY  = 32, ///< discard all frames except keyframes   抛弃除关键帧以外的，比如B，P帧
         IJK_AVDISCARD_ALL     = 48, ///< discard all
     } IJKAVDiscard;

     前面两个都看得懂
     第三个是抛弃非参考帧（I帧）
     第四个是抛弃B帧
     第五个是抛弃除关键帧以外的，比如B，P帧
     第六个是抛弃所有的帧，这我就奇怪了，之前Android默认的就是48，难道把所有帧都丢了？
     那就没有视频帧了，所以应该不是这么理解，应该是skip_loop_filter和skip_frame的对象要过滤哪些帧类型。

     skip_loop_filter这个是解码的一个参数，叫环路滤波，设置成48和0，图像清晰度对比，0比48清楚，理解起来就是，0是开启了环路滤波，过滤的是大部分，而48基本没启用环路滤波，所以清晰度更低，但是解码性能开销小
     skip_loop_filter（环路滤波）简言之：
     a:环路滤波器可以保证不同水平的图像质量。
     b:环路滤波器更能增加视频流的主客观质量，同时降低解码器的复杂度。
     
     参考：https://superdanny.link/2017/05/09/iOS-IJKPlayer/
     */
    
    
    
    [self.playBtn addTarget:self action:@selector(clickedAction:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
    
    CADisplayLink * link = [CADisplayLink displayLinkWithTarget:self selector:@selector(linkAction)];
    [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.playerView = [_player view];
    self.playerView.frame = CGRectMake(0, 0, self.playView.frame.size.width, self.playView.frame.size.height);
    [self.playView addSubview:self.playerView];
    
    self.slider = [[UISlider alloc] initWithFrame:CGRectMake(0, self.playView.frame.size.height - 50, self.playView.frame.size.width, 30)];
    [self.playView addSubview:self.slider];
}


- (void)linkAction
{
    if (_player.isPlaying && _player.playableDuration > 0) {
        NSLog(@"%f", _player.duration);
        NSLog(@"%f", _player.currentPlaybackTime);
        _slider.value = _player.currentPlaybackTime / _player.duration;
    }
}

- (void)loadStateDidChange:(NSNotification*)notification
{
    IJKMPMovieLoadState loadState = _player.loadState;

    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStatePlaythroughOK: %d\n", (int)loadState);   // 准备好播放
    } else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackDidFinish:(NSNotification*)notification
{
    int reason = [[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason)
    {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);    // 播放结束停止播放
            [self.playBtn setTitle:@"重播" forState:UIControlStateNormal];
            break;
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);   // 用户退出停止播放
            break;
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);    // 播放出现错误停止播放
            break;
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification
{
    NSLog(@"mediaIsPreparedToPlayDidChange\n");
    NSLog(@"总时长%f", _player.duration);
    NSLog(@"总时长%f", _player.playableDuration);
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification
{
    switch (_player.playbackState)
    {
        case IJKMPMoviePlaybackStateStopped: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);  // 停止播放/播放结束
            break;
        }
        case IJKMPMoviePlaybackStatePlaying: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState); // 开始播放
            break;
        }
        case IJKMPMoviePlaybackStatePaused: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);  // 暂停播放
            break;
        }
        case IJKMPMoviePlaybackStateInterrupted: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}


-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (![_player isPlaying]) {
        [self.player prepareToPlay];
    }
}

// 支持设备自动旋转
- (BOOL)shouldAutorotate
{
    return YES;
}

/**
 *  设置特殊的界面支持的方向,这里特殊界面只支持Home在右侧的情况
 */
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}


-(void)clickedAction:(id)sender {
    if (![_player isPlaying]) {
        [self.player play];
        [self.playBtn setTitle:@"暂停" forState:UIControlStateNormal];
    }else {
        [self.player pause];
        [self.playBtn setTitle:@"播放" forState:UIControlStateNormal];
    }
}




@end
