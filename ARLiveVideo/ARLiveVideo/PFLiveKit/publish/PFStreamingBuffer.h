//
//  PFStreamingBuffer.h
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import "PFAudioFrame.h"
#import "PFVideoFrame.h"

/** current buffer status */
typedef NS_ENUM (NSUInteger, PFLiveBuffferState) {
    PFLiveBuffferUnknown = 0,      //< 未知
    PFLiveBuffferIncrease = 1,    //< 缓冲区状态差应该降低码率
    PFLiveBuffferDecline = 2      //< 缓冲区状态好应该提升码率
};

@class PFStreamingBuffer;
/** this two method will control videoBitRate */
@protocol PFStreamingBufferDelegate <NSObject>
@optional
/** 当前buffer变动（增加or减少） 根据buffer中的updateInterval时间回调*/
- (void)streamingBuffer:(nullable PFStreamingBuffer *)buffer bufferState:(PFLiveBuffferState)state;
@end

@interface PFStreamingBuffer : NSObject

/** The delegate of the buffer. buffer callback */
@property (nullable, nonatomic, weak) id <PFStreamingBufferDelegate> delegate;

/** current frame buffer   当前缓冲区*/
@property (nonatomic, strong, readonly) NSMutableArray <PFFrame *> *_Nonnull list;

/** buffer count max size default 1000  缓冲区最大数据数量默认为1000 */
@property (nonatomic, assign) NSUInteger maxCount;

/** count of drop frames in last time  上次丢帧数量*/
@property (nonatomic, assign) NSInteger lastDropFrames;

/** add frame to buffer   向缓冲区添加数据*/
- (void)appendObject:(nullable PFFrame *)frame;

/** pop the first frome buffer   缓冲区吐出首个数据*/
- (nullable PFFrame *)popFirstObject;

/** remove all objects from Buffer  清空缓冲区*/
- (void)removeAllObject;

@end


