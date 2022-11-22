//
//  PFLiveStreamInfo.h
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import "PFLiveAudioConfiguration.h"
#import "PFLiveVideoConfiguration.h"

/// 流状态
typedef NS_ENUM (NSUInteger, PFLiveState){
    /// 准备
    PFLiveReady = 0,
    /// 连接中
    PFLivePending = 1,
    /// 已连接
    PFLiveStart = 2,
    /// 已断开
    PFLiveStop = 3,
    /// 连接出错
    PFLiveError = 4,
    ///  正在刷新
    PFLiveRefresh = 5
};

typedef NS_ENUM (NSUInteger, PFLiveSocketErrorCode) {
    PFLiveSocketError_PreView = 201,              ///< 预览失败
    PFLiveSocketError_GetStreamInfo = 202,        ///< 获取流媒体信息失败
    PFLiveSocketError_ConnectSocket = 203,        ///< 连接socket失败
    PFLiveSocketError_Verification = 204,         ///< 验证服务器失败
    PFLiveSocketError_ReConnectTimeOut = 205      ///< 重新连接服务器超时
};

@interface PFLiveStreamInfo : NSObject

@property (nonatomic, copy) NSString *streamId;

#pragma mark -- FLV
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) NSInteger port;
#pragma mark -- RTMP
@property (nonatomic, copy) NSString *url;          ///< 上传地址 (RTMP用就好了)
///音频配置
@property (nonatomic, strong) PFLiveAudioConfiguration *audioConfiguration;
///视频配置
@property (nonatomic, strong) PFLiveVideoConfiguration *videoConfiguration;


@end


