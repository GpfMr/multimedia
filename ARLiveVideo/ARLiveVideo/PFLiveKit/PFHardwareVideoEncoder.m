//
//  PFHardwareVideoEncoder.m
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import "PFHardwareVideoEncoder.h"
#import <VideoToolbox/VideoToolbox.h>
#import "PFLiveVideoConfiguration.h"
#import "PFVideoFrame.h"

@interface PFHardwareVideoEncoder (){
    VTCompressionSessionRef compressionSession;
    NSInteger frameCount;
    NSData *sps;
    NSData *pps;
    FILE *fp;
    BOOL enabledWriteVideoFile;
}

@property (nonatomic, strong) PFLiveVideoConfiguration *configuration;
@property (nonatomic, weak) id<PFVideoEncodingDelegate> h264Delegate;
@property (nonatomic) NSInteger currentVideoBitRate;
@property (nonatomic) BOOL isBackGround;

@end

@implementation PFHardwareVideoEncoder

- (instancetype)initWithVideoStreamConfiguration:(PFLiveVideoConfiguration *)configuration
{
    if (self = [super init]) {
        _configuration = configuration;
        [self resetCompressionSession];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

// 创建视频编码器并设置其参数
- (void)resetCompressionSession {
    if (compressionSession) {
        // 当需要主动停止编码时，可调用下面方法来强制停止编码器
        VTCompressionSessionCompleteFrames(compressionSession, kCMTimeInvalid);
        // 释放编码会话及内存
        VTCompressionSessionInvalidate(compressionSession);
//        CFRelease(compressionSession);
        compressionSession = NULL;
    }
    
    //创建编码会话session
    OSStatus status = VTCompressionSessionCreate(NULL, _configuration.videoSize.width, _configuration.videoSize.height, kCMVideoCodecType_H264, NULL, NULL, NULL, VideoCompressonOutputCallback, (__bridge void *)self, &compressionSession);
    if (status != noErr) {
        return;
    }
    
    _currentVideoBitRate = _configuration.videoBitRate;
    
    // 关键帧之间的最大间隔，也称为关键帧速率
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(_configuration.videoMaxKeyframeInterval));
    // 从这个关键帧到下一个关键帧的最长持续时间
    
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, (__bridge CFTypeRef)@(_configuration.videoMaxKeyframeInterval/_configuration.videoFrameRate));
    
    // 预期的帧速率
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(_configuration.videoFrameRate));
    
    // 期望的平均比特率，以比特/秒为单位
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(_configuration.videoBitRate));
    
    //
    NSArray *limit = @[@(_configuration.videoBitRate * 1.5/8), @(1)];
    
    // 码率上限
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)limit);
    
    // 表示是否建议视频编码器实时执行压缩
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    
    // 编码比特流的配置文件和级别
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel);
    
    // 指示是否启用了帧重新排序
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanTrue);
    
    // H.264 压缩的熵编码模式，可以设置为 CAVLC 或者 CABAC
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC);
     
    // 在进行数据的编码之前，可手动调用下面的方法来申请必要的资源，如果不手动调用，则会在第一次进行数据编码时自动调用
    VTCompressionSessionPrepareToEncodeFrames(compressionSession);

}

// 设置码率
- (void)setVideoBitRate:(NSInteger)videoBitRate {
    if(_isBackGround) return;
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(videoBitRate));
    // 以字节为单位
    NSArray *limit = @[@(videoBitRate * 1.5/8), @(1)];
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)limit);
    _currentVideoBitRate = videoBitRate;
}

- (NSInteger)videoBitRate {
    return _currentVideoBitRate;
}

- (void)dealloc {
    if (compressionSession != NULL) {
        // 强制抛弃一些或所有挂起的帧
        VTCompressionSessionCompleteFrames(compressionSession, kCMTimeInvalid);

        // 完成压缩会话后，调用 VTCompressionSessionInvalid(_:)使其失效，并调用 CFrelease 释放其内存。
        VTCompressionSessionInvalidate(compressionSession);
        CFRelease(compressionSession);
        compressionSession = NULL;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -- LFVideoEncoder
- (void)encodeVideoData:(CVPixelBufferRef)pixelBuffer timeStamp:(uint64_t)timeStamp {
    if(_isBackGround) return;
    frameCount++;
    CMTime presentationTimeStamp = CMTimeMake(frameCount, (int32_t)_configuration.videoFrameRate);
    VTEncodeInfoFlags flags;
    CMTime duration = CMTimeMake(1, (int32_t)_configuration.videoFrameRate);

    NSDictionary *properties = nil;
    if (frameCount % (int32_t)_configuration.videoMaxKeyframeInterval == 0) {
        properties = @{(__bridge NSString *)kVTEncodeFrameOptionKey_ForceKeyFrame: @YES};
    }
    NSNumber *timeNumber = @(timeStamp);

    // 该函数调用一次之后，后续的调用将是无效的调用。调用此方法成功后触发回调函数完成编码;
    // 对视频帧进行编码，并在会话的 VTCompressionOutputCallback 中接收压缩的视频帧。
    OSStatus status = VTCompressionSessionEncodeFrame(compressionSession, pixelBuffer, presentationTimeStamp, duration, (__bridge CFDictionaryRef)properties, (__bridge_retained void *)timeNumber, &flags);
    if(status != noErr){
        [self resetCompressionSession];
    }
}

- (void)stopEncoder {
    // 停止编码
    VTCompressionSessionCompleteFrames(compressionSession, kCMTimeIndefinite);
}

- (void)setDelegate:(id<PFVideoEncodingDelegate>)delegate {
    _h264Delegate = delegate;
}

#pragma mark -- Notification
- (void)willEnterBackground:(NSNotification*)notification{
    _isBackGround = YES;
}

- (void)willEnterForeground:(NSNotification*)notification{
    [self resetCompressionSession];
    _isBackGround = NO;
}
#pragma mark -- VideoCallBack，编码成功的回调
static void VideoCompressonOutputCallback(void *VTref, void *VTFrameRef, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer){
    
    if (!sampleBuffer) return;
    // 从采集到的视频CMSampleBufferRef中获取CVImageBufferRef
    CFArrayRef array = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    if (!array) return;
    //
    CFDictionaryRef dic = (CFDictionaryRef)CFArrayGetValueAtIndex(array, 0);
    if (!dic) return;
    // kCMSampleAttachmentKey_NotSync  获取是否包含关键帧
    BOOL keyframe = !CFDictionaryContainsKey(dic, kCMSampleAttachmentKey_NotSync);
    
    uint64_t timeStamp = [((__bridge_transfer NSNumber *)VTFrameRef) longLongValue];
    
    PFHardwareVideoEncoder *videoEncoder = (__bridge PFHardwareVideoEncoder *)VTref;
    if (status != noErr) {
        return;
    }
    // keyframe标明为关键帧，videoEncoder->sps判定是否已经存在sps
    if (keyframe && !videoEncoder->sps) {
        NSLog(@"获取sps数据");
        // 获取数据格式描述，如果存在错误则返回NULL
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        // 创建用于记录sps数据长度
        size_t sparameterSetSize, sparameterSetCount;
        // 定义的sps set用来存储sps数据
        const uint8_t *sparameterSet;
        // 并从中返回给定索引处的 NAL 单元。这些 NAL 单元通常是参数集（例如 SPS、PPS）。此处传入0以获取sps数据
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0);
        if (statusCode == noErr) {
            // 获取pps相关数据
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0);
            if (statusCode == noErr) {
                // 将sps和pps赋值到LFHardwareVideoEncoder上
                videoEncoder->sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                videoEncoder->pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                // 对sps和pps进行拼接
                if (videoEncoder->enabledWriteVideoFile) {
                    // 对sps和pps进行头部拼接并写入地址，生成NALU
                    NSMutableData *data = [[NSMutableData alloc] init];
                    uint8_t header[] = {0x00, 0x00, 0x00, 0x01};
                    [data appendBytes:header length:4];
                    [data appendData:videoEncoder->sps];
                    [data appendBytes:header length:4];
                    [data appendData:videoEncoder->pps];
                    fwrite(data.bytes, 1, data.length, videoEncoder->fp);
                }
            }
        }
    }
    // 获取到的编码数据
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    // 读取dataBuffer中的数据到dataPointer中，
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4;
        // 进行循环读取dataBuffer中的数据
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            // Read the NAL unit length
            uint32_t NALUnitLength = 0;
            // 从dataPointer + bufferOffset开始copy AVCCHeaderLength个数据到 NALUnitLength中
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);

            // 进行大小端调整
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            // 进行格式配置
            PFVideoFrame *videoFrame = [PFVideoFrame new];
            videoFrame.timestamp = timeStamp;
            videoFrame.data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            videoFrame.isKeyFrame = keyframe;
            videoFrame.sps = videoEncoder->sps;
            videoFrame.pps = videoEncoder->pps;
            
            if (videoEncoder.h264Delegate && [videoEncoder.h264Delegate respondsToSelector:@selector(videoEncoder:videoFrame:)]) {
                [videoEncoder.h264Delegate videoEncoder:videoEncoder videoFrame:videoFrame];
            }

            // 进行数据写入，生成NALU
            if (videoEncoder->enabledWriteVideoFile) {
                NSMutableData *data = [[NSMutableData alloc] init];
                if (keyframe) { // 关键帧的处理
                    uint8_t header[] = {0x00, 0x00, 0x00, 0x01};
                    [data appendBytes:header length:4];
                } else {
                    // 非关键帧的处理
                    uint8_t header[] = {0x00, 0x00, 0x01};
                    [data appendBytes:header length:3];
                }
                // 进行数据拼接
                [data appendData:videoFrame.data];

                fwrite(data.bytes, 1, data.length, videoEncoder->fp);
            }

            // 对读取的数据进行++操作
            bufferOffset += AVCCHeaderLength + NALUnitLength;

        }
    }
}

// 设置默认存储路径
- (void)initForFilePath {
    NSString *path = [self GetFilePathByfileName:@"IOSCamDemo.h264"];
    NSLog(@"%@", path);
    self->fp = fopen([path cStringUsingEncoding:NSUTF8StringEncoding], "wb");
}

- (NSString *)GetFilePathByfileName:(NSString*)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:filename];
    return writablePath;
}


@end
