//
//  ViewController.m
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/13.
//

#import "ViewController.h"
#import <ARKit/ARKit.h>
#import <Metal/Metal.h>
#import <Metal/MTLTexture.h>
#import "PFDelegate.h"
#import "PFHardwareVideoEncoder.h"
#import "PFLiveKit.h"

@interface ViewController ()<ARSCNViewDelegate, ARSessionDelegate, ARSessionObserver, PFLiveSessionDelegate>

@property (nonatomic, strong) ARSCNView * scnView;
@property (nonatomic, strong) SCNScene * scene;
@property (nonatomic, strong) SCNNode * sunNode;
@property (nonatomic, strong) ARSession * session;
@property (nonatomic, strong) ARWorldTrackingConfiguration * config;
@property (nonatomic, strong) PFLiveSession * videoSession;
@property (nonatomic, assign) BOOL isPushing;
@property (nonatomic, assign) BOOL isRecoding;
@property (nonatomic, assign) BOOL isFilterOpen;


@property (weak, nonatomic) IBOutlet UIButton *liveingBtn;
@property (weak, nonatomic) IBOutlet UIButton *recodingBtn;
@property (weak, nonatomic) IBOutlet UIButton *filterBtn;
@property (weak, nonatomic) IBOutlet UIButton *switchCamera;

@end

#define ScreenSize [UIScreen mainScreen].bounds.size

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadScnView];
    [self configEncoderSession];
    [self configView];
}

- (void)loadScnView
{
    self.scnView = [[ARSCNView alloc] initWithFrame:CGRectMake(0, 0, ScreenSize.width, ScreenSize.height)];
    [self.view addSubview:self.scnView];
//    self.scnView.allowsCameraControl = YES;
    self.scnView.showsStatistics = YES;
    self.scnView.delegate = self;

    
    self.session = [[ARSession alloc] init];
    self.scnView.session = self.session;
    self.scnView.session.delegate = self;
    self.session.delegate = self;
    
    [self loadMode];
    
    self.config = [[ARWorldTrackingConfiguration alloc] init];
    self.config.planeDetection = ARPlaneDetectionHorizontal;    // 设置主要监测平面
    self.config.lightEstimationEnabled = YES;   // 是否支持现实光照补给
    self.config.providesAudioData = YES;    // 配置支持音频
    [self.session runWithConfiguration:self.config];
    
}

- (void)configView
{
    
    [self.view bringSubviewToFront:self.liveingBtn];
    [self.view bringSubviewToFront:self.recodingBtn];
    [self.view bringSubviewToFront:self.filterBtn];
    [self.view bringSubviewToFront:self.switchCamera];
    
    [self.liveingBtn addTarget:self action:@selector(begainLiveVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.recodingBtn addTarget:self action:@selector(recording:) forControlEvents:UIControlEventTouchUpInside];
    [self.filterBtn addTarget:self action:@selector(filter:) forControlEvents:UIControlEventTouchUpInside];
    [self.switchCamera addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
}


- (void)configEncoderSession
{
    PFLiveAudioConfiguration *audioConfiguration = [PFLiveAudioConfiguration new];  //
    // 设置音频相关
   audioConfiguration.numberOfChannels = 2;  // 设置声道数
   audioConfiguration.audioBitrate = PFLiveAudioBitRate_128Kbps;  // 设置音频的码率
   audioConfiguration.audioSampleRate = PFLiveAudioSampleRate_44100Hz;  //音频采样率

// 配置视频相关
    PFLiveVideoConfiguration *videoConfiguration = [PFLiveVideoConfiguration new];
   videoConfiguration.videoSize = ScreenSize;  // 视频尺寸
   videoConfiguration.videoBitRate = 800*1024;  //视频码率，比特率 Bit Rate或叫位速率，是单位时间内视频（或音频）的数据量，单位是 bps (bit per second，位每秒），一般使用 kbps（千位每秒）或Mbps（百万位每秒）。

   videoConfiguration.videoMaxBitRate = 1000*1024;  // 最大码率
   videoConfiguration.videoMinBitRate = 500*1024;  // 最小码率
   videoConfiguration.videoFrameRate = 15;  //  帧率，即fps
   videoConfiguration.videoMaxKeyframeInterval = 30;  // 最大关键帧间隔，可设定为 fps 的2倍，影响一个 gop 的大小
   videoConfiguration.outputImageOrientation = UIInterfaceOrientationPortrait;  //视频输出方向
   videoConfiguration.sessionPreset = PFCaptureSessionPreset360x640;  //视频分辨率(都是16：9 当此设备不支持当前分辨率，自动降低一级)
    
    self.videoSession = [[PFLiveSession alloc] initWithAudioConfiguration:audioConfiguration videoConfiguration:videoConfiguration];
    
    self.videoSession.delegate = self;
    self.videoSession.showDebugInfo = NO;
}

// 添加圆球
- (void)loadMode
{
    SCNSphere * sunSphere = [SCNSphere sphereWithRadius:0.2];
    sunSphere.firstMaterial.multiply.contents = @"art.scnassets/earth/sun.jpg";
    sunSphere.firstMaterial.diffuse.contents = @"art.scnassets/earth/sun.jpg";
    sunSphere.firstMaterial.multiply.intensity = 0.5;
    sunSphere.firstMaterial.lightingModelName = SCNLightingModelConstant;
    
    self.sunNode = [[SCNNode alloc] init];
    self.sunNode.geometry = sunSphere;
    
    self.sunNode.position = SCNVector3Make(0, 0, -2);
 
    [self.scnView.scene.rootNode addChildNode:self.sunNode];

    SCNAction * act = [SCNAction repeatActionForever:[SCNAction rotateByX:0 y:1 z:0 duration:1]];
    [_sunNode runAction:act];
    
}


- (void)session:(ARSession *)session didOutputAudioSampleBuffer:(CMSampleBufferRef)audioSampleBuffer
{
    [self.videoSession captureOutputAudioData:audioSampleBuffer];
}

// 通过该方法读取每一帧arkit处理后的图片，self.session.currentFrame.capturedImage获取的图片是未经处理的图片
- (void)renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time
{
    if (renderer.currentRenderPassDescriptor.colorAttachments[0].texture == nil) {
        return;
    }
    CVPixelBufferRef pixelBuffer = nil;
    if (renderer.currentRenderPassDescriptor.colorAttachments[0].texture.iosurface == nil) {
        return;
    }
    CVPixelBufferCreateWithIOSurface(kCFAllocatorDefault, renderer.currentRenderPassDescriptor.colorAttachments[0].texture.iosurface, nil, &pixelBuffer);
    
    [self.videoSession captureOutputPixelBuffer:pixelBuffer];
}

- (void)begainLiveVideo:(UIButton *)sender
{
    if (self.isPushing == YES) {
        [self.videoSession stopLive];
        self.isPushing = NO;
        [sender setTitle:@"开始直播" forState:UIControlStateNormal];
    } else {
        PFLiveStreamInfo *stream = [PFLiveStreamInfo new];
        stream.url = @"rtmp://192.168.2.160:1935/rtmplive/demo";
        [self.videoSession startLive:stream];
        self.isPushing = YES;
        [sender setTitle:@"关闭直播" forState:UIControlStateNormal];
    }
}

- (void)recording:(UIButton *)sender
{
    if (self.isRecoding == YES) {
        [sender setTitle:@"停止录制" forState:UIControlStateNormal];
    } else {
        [sender setTitle:@"开始录制" forState:UIControlStateNormal];
    }
}

- (void)filter:(UIButton *)sender
{
    if (self.isFilterOpen == YES) {
        [sender setTitle:@"关闭滤镜" forState:UIControlStateNormal];
    } else {
        [sender setTitle:@"打开滤镜" forState:UIControlStateNormal];
    }
}

- (void)switchCamera:(UIButton *)sender
{
    
}



@end
