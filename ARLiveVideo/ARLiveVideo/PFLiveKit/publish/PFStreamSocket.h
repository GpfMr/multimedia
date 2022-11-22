//
//  PFStreamSocket.h
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/15.
//

#import <Foundation/Foundation.h>
#import "PFLiveStreamInfo.h"
#import "PFStreamingBuffer.h"
#import "PFLiveDebug.h"


@protocol PFStreamSocket;
@protocol PFStreamSocketDelegate <NSObject>

/** callback buffer current status (回调当前缓冲区情况，可实现相关切换帧率 码率等策略)*/
- (void)socketBufferStatus:(nullable id <PFStreamSocket>)socket status:(PFLiveBuffferState)status;
/** callback socket current status (回调当前网络情况) */
- (void)socketStatus:(nullable id <PFStreamSocket>)socket status:(PFLiveState)status;
/** callback socket errorcode */
- (void)socketDidError:(nullable id <PFStreamSocket>)socket errorCode:(PFLiveSocketErrorCode)errorCode;
@optional
/** callback debugInfo */
- (void)socketDebug:(nullable id <PFStreamSocket>)socket debugInfo:(nullable PFLiveDebug *)debugInfo;
@end

@protocol PFStreamSocket <NSObject>
- (void)start;
- (void)stop;
- (void)sendFrame:(nullable PFFrame *)frame;
- (void)setDelegate:(nullable id <PFStreamSocketDelegate>)delegate;
@optional
- (nullable instancetype)initWithStream:(nullable PFLiveStreamInfo *)stream;
- (nullable instancetype)initWithStream:(nullable PFLiveStreamInfo *)stream reconnectInterval:(NSInteger)reconnectInterval reconnectCount:(NSInteger)reconnectCount;
@end
