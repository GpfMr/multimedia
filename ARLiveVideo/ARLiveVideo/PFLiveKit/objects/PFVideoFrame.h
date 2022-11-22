//
//  PFVideoFrame.h
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import "PFFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFVideoFrame : PFFrame

@property (nonatomic, assign) BOOL isKeyFrame;
@property (nonatomic, strong) NSData *sps;
@property (nonatomic, strong) NSData *pps;

@end

NS_ASSUME_NONNULL_END
