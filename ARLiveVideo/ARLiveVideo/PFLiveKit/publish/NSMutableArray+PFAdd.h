//
//  NSMutableArray+PFAdd.h
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableArray (PFAdd)
/**
   Removes and returns the object with the lowest-valued index in the array.
   If the array is empty, it just returns nil.

   @return The first object, or nil.
 */
- (nullable id)pfPopFirstObject;
@end

NS_ASSUME_NONNULL_END
