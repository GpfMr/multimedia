//
//  PFLiveSession.h
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import "PFLiveVideoConfiguration.h"
#import "PFLiveAudioConfiguration.h"
#import "PFDelegate.h"
#import "PFCaptureDelegate.h"
#import "PFLiveDebug.h"
#import "PFLiveStreamInfo.h"
#import "PFStreamSocket.h"

typedef NS_ENUM(NSInteger,PFLiveCaptureType) {
    PFLiveCaptureAudio,         ///< capture only audio
    PFLiveCaptureVideo,         ///< capture onlt video
    PFLiveInputAudio,           ///< only audio (External input audio)
    PFLiveInputVideo,           ///< only video (External input video)
};

///< 用来控制采集类型（可以内部采集也可以外部传入等各种组合，支持单音频与单视频,外部输入适用于录屏，无人机等外设介入）
typedef NS_ENUM(NSInteger,PFLiveCaptureTypeMask) {
    PFLiveCaptureMaskAudio = (1 << PFLiveCaptureAudio),                                 ///< only inner capture audio (no video)
    PFLiveCaptureMaskVideo = (1 << PFLiveCaptureVideo),                                 ///< only inner capture video (no audio)
    PFLiveInputMaskAudio = (1 << PFLiveInputAudio),                                     ///< only outer input audio (no video)
    PFLiveInputMaskVideo = (1 << PFLiveInputVideo),                                     ///< only outer input video (no audio)
    PFLiveCaptureMaskAll = (PFLiveCaptureMaskAudio | PFLiveCaptureMaskVideo),           ///< inner capture audio and video
    PFLiveInputMaskAll = (PFLiveInputMaskAudio | PFLiveInputMaskVideo),                 ///< outer input audio and video(method see pushVideo and pushAudio)
    PFLiveCaptureMaskAudioInputVideo = (PFLiveCaptureMaskAudio | PFLiveInputMaskVideo), ///< inner capture audio and outer input video(method pushVideo and setRunning)
    PFLiveCaptureMaskVideoInputAudio = (PFLiveCaptureMaskVideo | PFLiveInputMaskAudio), ///< inner capture video and outer input audio(method pushAudio and setRunning)
    PFLiveCaptureDefaultMask = PFLiveCaptureMaskAll                                     ///< default is inner capture audio and video
};


@class PFLiveSession;
@protocol PFLiveSessionDelegate <NSObject>

@optional
/** live status changed will callback */
- (void)liveSession:(nullable PFLiveSession *)session liveStateDidChange:(PFLiveState)state;
/** live debug info callback */
- (void)liveSession:(nullable PFLiveSession *)session debugInfo:(nullable PFLiveDebug *)debugInfo;
/** callback socket errorcode */
- (void)liveSession:(nullable PFLiveSession *)session errorCode:(PFLiveSocketErrorCode)errorCode;
@end



@interface PFLiveSession : NSObject<PFCaptureDelegate>

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================
/** The delegate of the capture. captureData callback */
@property (nullable, nonatomic, weak) id<PFLiveSessionDelegate> delegate;

/** The running control start capture or stop capture*/
@property (nonatomic, assign) BOOL running;

/** The preView will show OpenGL ES view*/
@property (nonatomic, strong, null_resettable) UIView *preView;

/** The captureDevicePosition control camraPosition ,default front*/
@property (nonatomic, assign) AVCaptureDevicePosition captureDevicePosition;

/** The beautyFace control capture shader filter empty or beautiy */
@property (nonatomic, assign) BOOL beautyFace;

/** The beautyLevel control beautyFace Level. Default is 0.5, between 0.0 ~ 1.0 */
@property (nonatomic, assign) CGFloat beautyLevel;

/** The brightLevel control brightness Level, Default is 0.5, between 0.0 ~ 1.0 */
@property (nonatomic, assign) CGFloat brightLevel;

/** The torch control camera zoom scale default 1.0, between 1.0 ~ 3.0 */
@property (nonatomic, assign) CGFloat zoomScale;

/** The torch control capture flash is on or off */
@property (nonatomic, assign) BOOL torch;

/** The mirror control mirror of front camera is on or off */
@property (nonatomic, assign) BOOL mirror;

/** The muted control callbackAudioData,muted will memset 0.*/
@property (nonatomic, assign) BOOL muted;

/*  The adaptiveBitrate control auto adjust bitrate. Default is NO */
@property (nonatomic, assign) BOOL adaptiveBitrate;

/** The stream control upload and package*/
@property (nullable, nonatomic, strong, readonly) PFLiveStreamInfo *streamInfo;

/** The status of the stream .*/
@property (nonatomic, assign, readonly) PFLiveState state;

/** The captureType control inner or outer audio and video .*/
@property (nonatomic, assign, readonly) PFLiveCaptureTypeMask captureType;

/** The showDebugInfo control streamInfo and uploadInfo(1s) *.*/
@property (nonatomic, assign) BOOL showDebugInfo;

/** The reconnectInterval control reconnect timeInterval(重连间隔) *.*/
@property (nonatomic, assign) NSUInteger reconnectInterval;

/** The reconnectCount control reconnect count (重连次数) *.*/
@property (nonatomic, assign) NSUInteger reconnectCount;

/*** The warterMarkView control whether the watermark is displayed or not ,if set ni,will remove watermark,otherwise add.
 set alpha represent mix.Position relative to outVideoSize.
 *.*/
@property (nonatomic, strong, nullable) UIView *warterMarkView;

/* The currentImage is videoCapture shot */
@property (nonatomic, strong,readonly ,nullable) UIImage *currentImage;

/* The saveLocalVideo is save the local video */
@property (nonatomic, assign) BOOL saveLocalVideo;

/* The saveLocalVideoPath is save the local video  path */
@property (nonatomic, strong, nullable) NSURL *saveLocalVideoPath;


#pragma mark - Initializer
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

- (nullable instancetype)initWithAudioConfiguration:(nullable PFLiveAudioConfiguration *)audioConfiguration videoConfiguration:(nullable PFLiveVideoConfiguration *)videoConfiguration;

- (nullable instancetype)initWithAudioConfiguration:(nullable PFLiveAudioConfiguration *)audioConfiguration videoConfiguration:(nullable PFLiveVideoConfiguration *)videoConfiguration captureType:(PFLiveCaptureTypeMask)captureType NS_DESIGNATED_INITIALIZER;


- (void)startLive:(nonnull PFLiveStreamInfo *)streamInfo;

/** The stop stream .*/
- (void)stopLive;

/** support outer input yuv or rgb video(set LFLiveCaptureTypeMask) .*/
- (void)pushVideo:(nullable CVPixelBufferRef)pixelBuffer;

/** support outer input pcm audio(set LFLiveCaptureTypeMask) .*/
- (void)pushAudio:(nullable NSData*)audioData;

@end

