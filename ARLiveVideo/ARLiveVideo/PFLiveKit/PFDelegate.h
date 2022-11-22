//
//  PFDelegate.h
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "PFVideoFrame.h"
#import "PFLiveVideoConfiguration.h"
#import "PFAudioFrame.h"
#import "PFLiveAudioConfiguration.h"

@protocol PFVideoEncoding;

/// 编码器编码后回调
@protocol PFVideoEncodingDelegate <NSObject>
@required
- (void)videoEncoder:(nullable id<PFVideoEncoding>)encoder videoFrame:(nullable PFVideoFrame *)frame;
@end


@protocol PFVideoEncoding <NSObject>
@required
- (void)encodeVideoData:(nullable CVPixelBufferRef)pixelBuffer timeStamp:(uint64_t)timeStamp;

@optional
@property (nonatomic, assign) NSInteger videoBitRate;
- (nullable instancetype)initWithVideoStreamConfiguration:(nullable PFLiveVideoConfiguration *)configuration;
- (void)setDelegate:(nullable id<PFVideoEncodingDelegate>)delegate;
- (void)stopEncoder;

@end

#pragma mark -- 音频代理
@protocol PFAudioEncoding;
/// 编码器编码后回调
@protocol PFAudioEncodingDelegate <NSObject>
@required
- (void)audioEncoder:(nullable id<PFAudioEncoding>)encoder audioFrame:(nullable PFAudioFrame *)frame;
@end

/// 编码器抽象的接口
@protocol PFAudioEncoding <NSObject>
@required
- (void)encodeAudioData:(nullable NSData*)audioData timeStamp:(uint64_t)timeStamp;
- (void)stopEncoder;
@optional
- (nullable instancetype)initWithAudioStreamConfiguration:(nullable PFLiveAudioConfiguration *)configuration;
- (void)setDelegate:(nullable id<PFAudioEncodingDelegate>)delegate;
- (nullable NSData *)adtsData:(NSInteger)channel rawDataLength:(NSInteger)rawDataLength;
@end




