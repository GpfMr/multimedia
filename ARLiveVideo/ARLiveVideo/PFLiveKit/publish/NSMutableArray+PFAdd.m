//
//  NSMutableArray+PFAdd.m
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import "NSMutableArray+PFAdd.h"

@implementation NSMutableArray (PFAdd)

- (void)pfRemoveFirstObject {
    if (self.count) {
        [self removeObjectAtIndex:0];
    }
}

- (id)pfPopFirstObject {
    id obj = nil;
    if (self.count) {
        obj = self.firstObject;
        [self pfRemoveFirstObject];
    }
    return obj;
}

@end
