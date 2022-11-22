//
//  PFStreamRTMPSocket.h
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/15.
//

#import <Foundation/Foundation.h>
#import "PFStreamSocket.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFStreamRTMPSocket : NSObject <PFStreamSocket>

#pragma mark - Initializer
///=============================================================================
/// @name Initializer
///=============================================================================
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;


@end

NS_ASSUME_NONNULL_END
