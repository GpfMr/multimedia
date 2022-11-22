//
//  PFCameraDelegate.h
//  ARLiveVideo
//
//  Created by Gpf 郭 on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol PFCaptureDelegate <NSObject>
@required
- (void)captureOutputAudioData:(nullable CMSampleBufferRef)audioData;
- (void)captureOutputPixelBuffer:(nullable CVPixelBufferRef)pixelBuffer;
@end





