//
//  PFAudioFrame.h
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import "PFFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFAudioFrame : PFFrame
/// flv打包中aac的header
@property (nonatomic, strong) NSData *audioInfo;

@end

NS_ASSUME_NONNULL_END
