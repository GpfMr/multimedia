//
//  PFHardwareAudioEncoder.h
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import "PFLiveAudioConfiguration.h"
#import "PFDelegate.h"


NS_ASSUME_NONNULL_BEGIN

@interface PFHardwareAudioEncoder : NSObject <PFAudioEncoding>

- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;
@end

NS_ASSUME_NONNULL_END
