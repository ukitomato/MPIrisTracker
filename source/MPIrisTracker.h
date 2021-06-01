//
//  MPIrisTracker.h
//  MPIrisTracker
//
//  Created by Yuki Yamato on 2021/05/05.
//
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@class MPLandmark;
@class MPIrisTracker;

@protocol MPTrackerDelegate <NSObject>
- (void)faceMeshDidUpdate:(MPIrisTracker *)tracker
       didOutputLandmarks:(NSArray<MPLandmark *> *)landmarks
                timestamp:(long)timestamp;

- (void)irisTrackingDidUpdate:(MPIrisTracker *)tracker
           didOutputLandmarks:(NSArray<MPLandmark *> *)landmarks
                    timestamp:(long)timestamp;

- (void)frameWillUpdate:(MPIrisTracker *)tracker
   didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer
              timestamp:(long)timestamp;

- (void)frameDidUpdate:(MPIrisTracker *)tracker
  didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

@interface MPIrisTracker : NSObject
- (instancetype)init;

- (void)start;

@property(weak, nonatomic) id <MPTrackerDelegate> delegate;
@end

@interface MPLandmark : NSObject
@property(nonatomic, readonly) float x;
@property(nonatomic, readonly) float y;
@property(nonatomic, readonly) float z;
@end
