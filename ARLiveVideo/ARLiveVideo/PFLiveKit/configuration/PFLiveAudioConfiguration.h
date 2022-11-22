//
//  PFLiveAudioConfiguration.h
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import <Foundation/Foundation.h>

/// 音频码率 (默认96Kbps)
typedef NS_ENUM (NSUInteger, PFLiveAudioBitRate) {
    /// 32Kbps 音频码率
    PFLiveAudioBitRate_32Kbps = 32000,
    /// 64Kbps 音频码率
    PFLiveAudioBitRate_64Kbps = 64000,
    /// 96Kbps 音频码率
    PFLiveAudioBitRate_96Kbps = 96000,
    /// 128Kbps 音频码率
    PFLiveAudioBitRate_128Kbps = 128000,
    /// 默认音频码率，默认为 96Kbps
    PFLiveAudioBitRate_Default = PFLiveAudioBitRate_96Kbps
};

/// 音频采样率 (默认44.1KHz)
typedef NS_ENUM (NSUInteger, PFLiveAudioSampleRate){
    /// 16KHz 采样率
    PFLiveAudioSampleRate_16000Hz = 16000,
    /// 44.1KHz 采样率
    PFLiveAudioSampleRate_44100Hz = 44100,
    /// 48KHz 采样率
    PFLiveAudioSampleRate_48000Hz = 48000,
    /// 默认音频采样率，默认为 44.1KHz
    PFLiveAudioSampleRate_Default = PFLiveAudioSampleRate_44100Hz
};

///  Audio Live quality（音频质量）
typedef NS_ENUM (NSUInteger, PFLiveAudioQuality){
    /// 低音频质量 audio sample rate: 16KHz audio bitrate: numberOfChannels 1 : 32Kbps  2 : 64Kbps
    PFLiveAudioQuality_Low = 0,
    /// 中音频质量 audio sample rate: 44.1KHz audio bitrate: 96Kbps
    PFLiveAudioQuality_Medium = 1,
    /// 高音频质量 audio sample rate: 44.1MHz audio bitrate: 128Kbps
    PFLiveAudioQuality_High = 2,
    /// 超高音频质量 audio sample rate: 48KHz, audio bitrate: 128Kbps
    PFLiveAudioQuality_VeryHigh = 3,
    /// 默认音频质量 audio sample rate: 44.1KHz, audio bitrate: 96Kbps
    PFLiveAudioQuality_Default = PFLiveAudioQuality_High
};


@interface PFLiveAudioConfiguration : NSObject<NSCoding, NSCopying>
/// 默认音频配置
+ (instancetype)defaultConfiguration;
/// 音频配置
+ (instancetype)defaultConfigurationForQuality:(PFLiveAudioQuality)audioQuality;

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================
/// 声道数目(default 2)
@property (nonatomic, assign) NSUInteger numberOfChannels;
/// 采样率
@property (nonatomic, assign) PFLiveAudioSampleRate audioSampleRate;
/// 码率
@property (nonatomic, assign) PFLiveAudioBitRate audioBitrate;
/// flv编码音频头 44100 为0x12 0x10
@property (nonatomic, assign, readonly) char *asc;
/// 缓存区长度
@property (nonatomic, assign,readonly) NSUInteger bufferLength;

@end


