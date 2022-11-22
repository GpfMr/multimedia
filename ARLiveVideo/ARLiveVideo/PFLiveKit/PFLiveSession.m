//
//  PFLiveSession.m
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import "PFLiveSession.h"
#import "PFHardwareVideoEncoder.h"
#import "PFCaptureDelegate.h"
#import "PFHardwareAudioEncoder.h"
#import "PFStreamRTMPSocket.h"

@interface PFLiveSession () <PFVideoEncodingDelegate, PFAudioEncodingDelegate, PFStreamSocketDelegate>
/// 音频配置
@property (nonatomic, strong) PFLiveAudioConfiguration *audioConfiguration;
/// 视频配置
@property (nonatomic, strong) PFLiveVideoConfiguration *videoConfiguration;

/// 音频编码
@property (nonatomic, strong) id<PFAudioEncoding> audioEncoder;
/// 视频编码
@property (nonatomic, strong) id<PFVideoEncoding> videoEncoder;
/// 上传
@property (nonatomic, strong) id<PFStreamSocket> socket;

#pragma mark -- 内部标识
/// 调试信息
@property (nonatomic, strong) PFLiveDebug *debugInfo;
/// 流信息
@property (nonatomic, strong) PFLiveStreamInfo *streamInfo;
/// 是否开始上传
@property (nonatomic, assign) BOOL uploading;
/// 当前状态
@property (nonatomic, assign, readwrite) PFLiveState state;
/// 当前直播type
@property (nonatomic, assign, readwrite) PFLiveCaptureTypeMask captureType;
/// 时间戳锁
@property (nonatomic, strong) dispatch_semaphore_t lock;

@end

@interface PFLiveSession ()

/// 上传相对时间戳
@property (nonatomic, assign) uint64_t relativeTimestamps;
/// 音视频是否对齐
@property (nonatomic, assign) BOOL AVAlignment;
/// 当前是否采集到了音频
@property (nonatomic, assign) BOOL hasCaptureAudio;
/// 当前是否采集到了关键帧
@property (nonatomic, assign) BOOL hasKeyFrameVideo;

@end


/**  时间戳 */
#define NOW (CACurrentMediaTime()*1000)
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@implementation PFLiveSession
#pragma mark -- LifeCycle
- (instancetype)initWithAudioConfiguration:(nullable PFLiveAudioConfiguration *)audioConfiguration videoConfiguration:(nullable PFLiveVideoConfiguration *)videoConfiguration {
    return [self initWithAudioConfiguration:audioConfiguration videoConfiguration:videoConfiguration captureType:PFLiveCaptureDefaultMask];
}

- (nullable instancetype)initWithAudioConfiguration:(nullable PFLiveAudioConfiguration *)audioConfiguration videoConfiguration:(nullable PFLiveVideoConfiguration *)videoConfiguration captureType:(PFLiveCaptureTypeMask)captureType{
    if((captureType & PFLiveCaptureMaskAudio || captureType & PFLiveInputMaskAudio) && !audioConfiguration) @throw [NSException exceptionWithName:@"LFLiveSession init error" reason:@"audioConfiguration is nil " userInfo:nil];
    if((captureType & PFLiveCaptureMaskVideo || captureType & PFLiveInputMaskVideo) && !videoConfiguration) @throw [NSException exceptionWithName:@"LFLiveSession init error" reason:@"videoConfiguration is nil " userInfo:nil];
    if (self = [super init]) {
        _audioConfiguration = audioConfiguration;
        _videoConfiguration = videoConfiguration;
        _adaptiveBitrate = NO;
        _captureType = captureType;
    }
    return self;
}

#pragma mark -- PFVideoEncodingDelegate
- (void)videoEncoder:(id<PFVideoEncoding>)encoder videoFrame:(PFVideoFrame *)frame
{
    //<上传 时间戳对齐
    if (self.uploading){
        if(frame.isKeyFrame && self.hasCaptureAudio) {
            self.hasKeyFrameVideo = YES;
        }

        if(self.AVAlignment) {
            [self pushSendBuffer:frame];
        }
    }
}

- (void)audioEncoder:(id<PFAudioEncoding>)encoder audioFrame:(PFAudioFrame *)frame
{
    //<上传  时间戳对齐
    if (self.uploading){
        self.hasCaptureAudio = YES;
        if(self.AVAlignment) {
            [self pushSendBuffer:frame];
        }
    }
}

#pragma mark -- PrivateMethod
// 推送数据
- (void)pushSendBuffer:(PFFrame*)frame{
    if(self.relativeTimestamps == 0){
        self.relativeTimestamps = frame.timestamp;
    }
    frame.timestamp = [self uploadTimestamp:frame.timestamp];
    [self.socket sendFrame:frame];
}

#pragma mark -- PFStreamTcpSocketDelegate， socket状态变化回调
- (void)socketStatus:(nullable id<PFStreamSocket>)socket status:(PFLiveState)status {
    // 已连接的状态
    if (status == PFLiveStart) {
        if (!self.uploading) {
            self.AVAlignment = NO;
            self.hasCaptureAudio = NO;
            self.hasKeyFrameVideo = NO;
            self.relativeTimestamps = 0;
            self.uploading = YES;
            }
    } // 链接断开或者出错的状态
    else if(status == PFLiveStop || status == PFLiveError){
        self.uploading = NO;
    }
    // 将状态返回给前端
    dispatch_async(dispatch_get_main_queue(), ^{
        self.state = status;
        if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:liveStateDidChange:)]) {
            [self.delegate liveSession:self liveStateDidChange:status];
        }
    });
}

// socket出错
- (void)socketDidError:(nullable id<PFStreamSocket>)socket errorCode:(PFLiveSocketErrorCode)errorCode {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:errorCode:)]) {
            [self.delegate liveSession:self errorCode:errorCode];
        }
    });
}

// debug开启状态下的回调
- (void)socketDebug:(nullable id<PFStreamSocket>)socket debugInfo:(nullable PFLiveDebug *)debugInfo {
    self.debugInfo = debugInfo;
    if (self.showDebugInfo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:debugInfo:)]) {
                [self.delegate liveSession:self debugInfo:debugInfo];
            }
        });
    }
}


// socket发送数据数据包回调
- (void)socketBufferStatus:(nullable id<PFStreamSocket>)socket status:(PFLiveBuffferState)status {
    
    if((self.captureType & PFLiveCaptureMaskVideo || self.captureType & PFLiveInputMaskVideo) && self.adaptiveBitrate){
        // 获取当前码率
        NSUInteger videoBitRate = [self.videoEncoder videoBitRate];
        // 根据网络状态调整传输码率的大小
        if (status == PFLiveBuffferDecline) {
            // 根据当前码率和最大码率相比较，如果当前码率低于设置的最大码率就增加传输数据量
            if (videoBitRate < _videoConfiguration.videoMaxBitRate) {
                videoBitRate = videoBitRate + 50 * 1000;
                [self.videoEncoder setVideoBitRate:videoBitRate];
                NSLog(@"Increase bitrate %@", @(videoBitRate));
            }
        } else {
            // 在网络较差的情况下如果当前码率高于设置的最低码率就适当降低码率
            if (videoBitRate > self.videoConfiguration.videoMinBitRate) {
                videoBitRate = videoBitRate - 100 * 1000;
                [self.videoEncoder setVideoBitRate:videoBitRate];
                NSLog(@"Decline bitrate %@", @(videoBitRate));
            }
        }
    }
}

#pragma mark -- CustomMethod
- (void)startLive:(PFLiveStreamInfo *)streamInfo {
    if (!streamInfo) return;
    _streamInfo = streamInfo;
    _streamInfo.videoConfiguration = _videoConfiguration;
    _streamInfo.audioConfiguration = _audioConfiguration;
    [self.socket start];
}

- (void)stopLive {
    self.uploading = NO;
    [self.socket stop];
    self.socket = nil;
}



#pragma mark -- PFCaptureDelegate
- (void)captureOutputAudioData:(nullable CMSampleBufferRef)sampleBuffer {
    //获取pcm数据大小
    size_t size = CMSampleBufferGetTotalSampleSize(sampleBuffer);
    int8_t *audio_data = (int8_t *)malloc(size);
    memset(audio_data, 0, size);
    //获取CMBlockBuffer, 这里面保存了PCM数据
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    //将数据copy到我们分配的空间中
    CMBlockBufferCopyDataBytes(blockBuffer, 0, size, audio_data);
    //PCM data->NSData
    NSData *data = [NSData dataWithBytes:audio_data length:size];
    free(audio_data);
    [self.audioEncoder encodeAudioData:data timeStamp:CACurrentMediaTime()];
}

// 视频数据回调
- (void)captureOutputPixelBuffer:(nullable CVPixelBufferRef)pixelBuffer {
    [self.videoEncoder encodeVideoData:pixelBuffer timeStamp:CACurrentMediaTime()];
}

#pragma mark -- lazy load
- (id<PFVideoEncoding>)videoEncoder
{
    if (!_videoEncoder) {
        _videoEncoder = [[PFHardwareVideoEncoder alloc] initWithVideoStreamConfiguration:_videoConfiguration];
        [_videoEncoder setDelegate:self];
    }
    return _videoEncoder;
}

- (id<PFAudioEncoding>)audioEncoder {
    if (!_audioEncoder) {
        _audioEncoder = [[PFHardwareAudioEncoder alloc] initWithAudioStreamConfiguration:_audioConfiguration];
        [_audioEncoder setDelegate:self];
    }
    return _audioEncoder;
}


// 懒加载socket
- (id<PFStreamSocket>)socket {
    if (!_socket) {
        _socket = [[PFStreamRTMPSocket alloc] initWithStream:self.streamInfo reconnectInterval:self.reconnectInterval reconnectCount:self.reconnectCount];
        [_socket setDelegate:self];
    }
    return _socket;
}

// 流信息工具，仅用来进行信息存储
- (PFLiveStreamInfo *)streamInfo {
    if (!_streamInfo) {
        _streamInfo = [[PFLiveStreamInfo alloc] init];
    }
    return _streamInfo;
}

- (dispatch_semaphore_t)lock{
    if(!_lock){
        _lock = dispatch_semaphore_create(1);
    }
    return _lock;
}

- (uint64_t)uploadTimestamp:(uint64_t)captureTimestamp{
    dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
    uint64_t currentts = 0;
    currentts = captureTimestamp - self.relativeTimestamps;
    dispatch_semaphore_signal(self.lock);
    return currentts;
}

- (BOOL)AVAlignment{
    if((self.captureType & PFLiveCaptureMaskAudio || self.captureType & PFLiveInputMaskAudio) &&
       (self.captureType & PFLiveCaptureMaskVideo || self.captureType & PFLiveInputMaskVideo)
       ){
        if(self.hasCaptureAudio && self.hasKeyFrameVideo) {
            return YES;
        } else {
            return NO;
        }
    }else{
        return YES;
    }
}

@end
