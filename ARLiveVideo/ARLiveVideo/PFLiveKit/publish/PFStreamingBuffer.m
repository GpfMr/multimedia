//
//  PFStreamingBuffer.m
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import "PFStreamingBuffer.h"
#import "NSMutableArray+PFAdd.h"
static const NSUInteger defaultSortBufferMaxCount = 5;///< 排序10个内
static const NSUInteger defaultUpdateInterval = 1;///< 更新频率为1s
static const NSUInteger defaultCallBackInterval = 5;///< 5s计时一次     5秒为一个网络监控周期
static const NSUInteger defaultSendBufferMaxCount = 600;///< 最大缓冲区为600

@interface PFStreamingBuffer (){
    dispatch_semaphore_t _lock;
}

@property (nonatomic, strong) NSMutableArray <PFFrame *> *sortList;
@property (nonatomic, strong, readwrite) NSMutableArray <PFFrame *> *list;
@property (nonatomic, strong) NSMutableArray *thresholdList;

/** 处理buffer缓冲区情况 */
@property (nonatomic, assign) NSInteger currentInterval;    //
@property (nonatomic, assign) NSInteger callBackInterval;   //
@property (nonatomic, assign) NSInteger updateInterval;     //
@property (nonatomic, assign) BOOL startTimer;      // 开始时间

@end


@implementation PFStreamingBuffer

- (instancetype)init {
    if (self = [super init]) {
        
        _lock = dispatch_semaphore_create(1);
        self.updateInterval = defaultUpdateInterval;
        self.callBackInterval = defaultCallBackInterval;
        self.maxCount = defaultSendBufferMaxCount;
        self.lastDropFrames = 0;
        self.startTimer = NO;
    }
    return self;
}

#pragma mark -- Custom
- (void)appendObject:(PFFrame *)frame {
    if (!frame) return;
    if (!_startTimer) {
        _startTimer = YES;
        [self tick];    // 开启监控
    }

    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    if (self.sortList.count < defaultSortBufferMaxCount) {  // 当缓冲区小于设置的最大缓冲数量时将新的frame加入到缓冲区
        [self.sortList addObject:frame];
    } else {
        ///< 排序
        [self.sortList addObject:frame];
        [self.sortList sortUsingFunction:frameDataCompare context:nil]; // 将数据进行排序
        /// 丢帧
        [self removeExpireFrame];
        /// 添加至缓冲区
        PFFrame *firstFrame = [self.sortList pfPopFirstObject];

        if (firstFrame) [self.list addObject:firstFrame];
    }
    dispatch_semaphore_signal(_lock);
}

- (PFFrame *)popFirstObject {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    PFFrame *firstFrame = [self.list pfPopFirstObject];
    dispatch_semaphore_signal(_lock);
    return firstFrame;
}

- (void)removeAllObject {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [self.list removeAllObjects];
    dispatch_semaphore_signal(_lock);
}

//
- (void)removeExpireFrame {
    if (self.list.count < self.maxCount) return;    // 缓冲区数据小于设置的最大缓冲长度

    NSArray *pFrames = [self expirePFrames];///< 第一个P到第一个I之间的p帧
    self.lastDropFrames += [pFrames count];
    if (pFrames && pFrames.count > 0) {
        [self.list removeObjectsInArray:pFrames];
        return;
    }
    
    NSArray *iFrames = [self expireIFrames];///<  删除一个I帧（但一个I帧可能对应多个nal）
    self.lastDropFrames += [iFrames count];
    if (iFrames && iFrames.count > 0) {
        [self.list removeObjectsInArray:iFrames];
        return;
    }
    
    [self.list removeAllObjects];
}
// 获取过时的frame， 如果当前第一帧是I帧则删除当前I帧到下一个I帧之间的数据，如果当前帧不是I帧则删除第一个I帧之前的数据
- (NSArray *)expirePFrames {
    NSMutableArray *pframes = [[NSMutableArray alloc] init];
    for (NSInteger index = 0; index < self.list.count; index++) {
        PFFrame *frame = [self.list objectAtIndex:index];
        if ([frame isKindOfClass:[PFVideoFrame class]]) {
            PFVideoFrame *videoFrame = (PFVideoFrame *)frame;
            if (videoFrame.isKeyFrame && pframes.count > 0) {
                break;
            } else if (!videoFrame.isKeyFrame) {
                [pframes addObject:frame];
            }
        }
    }
    return pframes;
}

//
- (NSArray *)expireIFrames {
    NSMutableArray *iframes = [[NSMutableArray alloc] init];
    uint64_t timeStamp = 0;
    for (NSInteger index = 0; index < self.list.count; index++) {
        PFFrame *frame = [self.list objectAtIndex:index];
        // 获取当前第一个I帧
        if ([frame isKindOfClass:[PFVideoFrame class]] && ((PFVideoFrame *)frame).isKeyFrame) {
            if (timeStamp != 0 && timeStamp != frame.timestamp) {
                break;
            }
            [iframes addObject:frame];
            timeStamp = frame.timestamp;
        }
    }
    return iframes;
}

//
NSInteger frameDataCompare(id obj1, id obj2, void *context){
    PFFrame *frame1 = (PFFrame *)obj1;
    PFFrame *frame2 = (PFFrame *)obj2;

    if (frame1.timestamp == frame2.timestamp) {
        return NSOrderedSame;
    }else if (frame1.timestamp > frame2.timestamp){
        return NSOrderedDescending;
    }
    return NSOrderedAscending;
}

// 根据五次采样 self.List中数据量进行对比，如果其中的数据逐渐增加则increaseCount会增加，则需要降低码率
// 如果其中数据量越来越小，则decreaseCount会增加，需要增加码率
- (PFLiveBuffferState)currentBufferState {
    NSInteger currentCount = 0;
    NSInteger increaseCount = 0;
    NSInteger decreaseCount = 0;
    NSLog(@"个数：%ld", self.thresholdList.count);
    for (NSNumber *number in self.thresholdList) {
        NSLog(@"number:%ld--currentCount:%ld--increaseCount:%ld--decreaseCount:%ld", number.integerValue, currentCount, increaseCount, decreaseCount);
        if (number.integerValue > currentCount) {
            // 需要降低码率
            increaseCount++;
        } else{
            // 需要增大码率
            decreaseCount++;
        }
        currentCount = [number integerValue];
    }

    if (increaseCount >= self.callBackInterval) {
        // 降低码率
        NSLog(@"降低码率");
        return PFLiveBuffferIncrease;
    }

    if (decreaseCount >= self.callBackInterval) {
        // 提升码率
        NSLog(@"提升码率");
        return PFLiveBuffferDecline;
    }
    
    return PFLiveBuffferUnknown;
}
#pragma mark -- Setter Getter
- (NSMutableArray *)list {
    if (!_list) {
        _list = [[NSMutableArray alloc] init];
    }
    return _list;
}

- (NSMutableArray *)sortList {
    if (!_sortList) {
        _sortList = [[NSMutableArray alloc] init];
    }
    return _sortList;
}

- (NSMutableArray *)thresholdList {
    if (!_thresholdList) {
        _thresholdList = [[NSMutableArray alloc] init];
    }
    return _thresholdList;
}

#pragma mark -- 采样
- (void)tick {
    
    /** 采样 3个阶段   如果网络都是好或者都是差给回调 */
    _currentInterval += self.updateInterval;

    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [self.thresholdList addObject:@(self.list.count)];
    dispatch_semaphore_signal(_lock);
//    NSLog(@"currentInterval:%ld--callBackInterval:%ld--updateInterval:%ld", self.currentInterval, self.callBackInterval, self.updateInterval);
    if (self.currentInterval >= self.callBackInterval) {    //当当前时间间隔大于等于5时
        PFLiveBuffferState state = [self currentBufferState];
        if (state == PFLiveBuffferIncrease) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(streamingBuffer:bufferState:)]) {
                [self.delegate streamingBuffer:self bufferState:PFLiveBuffferIncrease];
            }
        } else if (state == PFLiveBuffferDecline) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(streamingBuffer:bufferState:)]) {
                // 将网络状态回调给session以进行码率调节
                [self.delegate streamingBuffer:self bufferState:PFLiveBuffferDecline];
            }
        }

        self.currentInterval = 0;
        [self.thresholdList removeAllObjects];
    }
    __weak typeof(self) _self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.updateInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(_self) self = _self;
        [self tick];
    });
}
@end
