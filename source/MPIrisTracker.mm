//
//  MPIrisTracker.mm
//  MPIrisTracker
//
//  Created by Yuki Yamato on 2021/05/05.
//
//

#import "MPIrisTracker.h"

#import "mediapipe/objc/MPPGraph.h"
#import "mediapipe/objc/MPPCameraInputSource.h"
#import "mediapipe/objc/MPPLayerRenderer.h"
#import "mediapipe/objc/MPPTimestampConverter.h"
#include "mediapipe/framework/formats/landmark.pb.h"
#include "mediapipe/framework/formats/rect.pb.h"

static NSString *const kGraphName = @"iris_tracking_gpu";
static const char *kInputStream = "input_video";
static const char *kOutputStream = "output_video";
static const char *kLandmarksOutputStream = "iris_landmarks";
static const char *kVideoQueueLabel = "com.google.mediapipe.example.videoQueue";
static const char *kFaceLandmarksOutputStream = "face_landmarks";


@interface MPIrisTracker () <MPPGraphDelegate, MPPInputSourceDelegate>
// The MediaPipe graph currently in use. Initialized in viewDidLoad, started in
// viewWillAppear: and sent video frames on videoQueue.
@property(nonatomic) MPPGraph *mediapipeGraph;
// Handles camera access via AVCaptureSession library.
@property(nonatomic) MPPCameraInputSource *cameraSource;
// Helps to convert timestamp.
@property(nonatomic) MPPTimestampConverter *timestampConverter;
// Process camera frames on this queue.
@property(nonatomic) dispatch_queue_t videoQueue;

@end

@interface MPLandmark ()
- (instancetype)initWithX:(float)x y:(float)y z:(float)z;
@end

@implementation MPIrisTracker {
    /// Input side packet for focal length parameter.
    std::map <std::string, mediapipe::Packet> _input_side_packets;
    mediapipe::Packet _focal_length_side_packet;
}

#pragma mark - Cleanup methods

- (void)dealloc {
    self.mediapipeGraph.delegate = nil;
    [self.mediapipeGraph cancel];
    // Ignore errors since we're cleaning up.
    [self.mediapipeGraph closeAllInputStreamsWithError:nil];
    [self.mediapipeGraph waitUntilDoneWithError:nil];
}

#pragma mark - MediaPipe graph methods

+ (MPPGraph *)loadGraphFromResource:(NSString *)resource {
    // Load the graph config resource.
    NSError *configLoadError = nil;
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    if (!resource || resource.length == 0) {
        return nil;
    }
    NSURL *graphURL = [bundle URLForResource:resource withExtension:@"binarypb"];
    NSData *data = [NSData dataWithContentsOfURL:graphURL options:0 error:&configLoadError];
    if (!data) {
        NSLog(@"Failed to load MediaPipe graph config: %@", configLoadError);
        return nil;
    }

    // Parse the graph config resource into mediapipe::CalculatorGraphConfig proto object.
    mediapipe::CalculatorGraphConfig config;
    config.ParseFromArray(data.bytes, data.length);

    // Create MediaPipe graph with mediapipe::CalculatorGraphConfig proto object.
    MPPGraph *newGraph = [[MPPGraph alloc] initWithGraphConfig:config];
    return newGraph;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.timestampConverter = [[MPPTimestampConverter alloc] init];
        dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(
                DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, /*relative_priority=*/0);
        self.videoQueue = dispatch_queue_create(kVideoQueueLabel, qosAttribute);

        self.mediapipeGraph = [[self class] loadGraphFromResource:kGraphName];
        [self.mediapipeGraph addFrameOutputStream:kOutputStream
                                 outputPacketType:MPPPacketTypePixelBuffer];

        self.mediapipeGraph.delegate = self;

        [self.mediapipeGraph addFrameOutputStream:kLandmarksOutputStream
                                 outputPacketType:MPPPacketTypeRaw];
        _focal_length_side_packet =
                mediapipe::MakePacket<std::unique_ptr<float>>(absl::make_unique<float>(0.0));
        _input_side_packets = {
                {"focal_length_pixel", _focal_length_side_packet},
        };
        [self.mediapipeGraph addSidePackets:_input_side_packets];

        [self.mediapipeGraph addFrameOutputStream:kFaceLandmarksOutputStream
                                 outputPacketType:MPPPacketTypeRaw];

        // Set maxFramesInFlight to a small value to avoid memory contention for real-time processing.
        self.mediapipeGraph.maxFramesInFlight = 2;

    }
    return self;
}

- (void)start {
    self.cameraSource = [[MPPCameraInputSource alloc] init];
    [self.cameraSource setDelegate:self queue:self.videoQueue];
    self.cameraSource.sessionPreset = AVCaptureSessionPresetHigh;

    self.cameraSource.cameraPosition = AVCaptureDevicePositionFront;
    // When using the front camera, mirror the input for a more natural look.
    _cameraSource.videoMirrored = YES;

    // The frame's native format is rotated with respect to the portrait orientation.
    _cameraSource.orientation = AVCaptureVideoOrientationPortrait;

    [self.cameraSource requestCameraAccessWithCompletionHandler:^void(BOOL granted) {
        if (granted) {
            [self startGraphAndCamera];
        }
    }];
}


- (void)startGraphAndCamera {
    // Start running self.mediapipeGraph.
    NSError *error;
    if (![self.mediapipeGraph startWithError:&error]) {
        NSLog(@"Failed to start graph: %@", error);
    } else if (![self.mediapipeGraph waitUntilIdleWithError:&error]) {
        NSLog(@"Failed to complete graph initial run: %@", error);
    }

    // Start fetching frames from the camera.
    dispatch_async(self.videoQueue, ^{
        [self.cameraSource start];
    });
}

#pragma mark - MPPGraphDelegate methods

// Receives CVPixelBufferRef from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph *)graph
  didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer
            fromStream:(const std::string&)streamName {
    if (streamName == kOutputStream) {
        [_delegate frameDidUpdate:self didOutputPixelBuffer:pixelBuffer];
    }
}


// Receives a raw packet from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph *)graph
       didOutputPacket:(const ::mediapipe::Packet&)packet
            fromStream:(const std::string&)streamName {
    if (streamName == kLandmarksOutputStream) {
        if (packet.IsEmpty()) {
            NSLog(@"[TS:%lld] No iris landmarks", packet.Timestamp().Value());
            return;
        }
        const auto
        &landmarks = packet.Get<::mediapipe::NormalizedLandmarkList>();

        NSMutableArray<MPLandmark *> *result = [NSMutableArray array];
        for (int i = 0; i < landmarks.landmark_size(); ++i) {
            MPLandmark *landmark = [[MPLandmark alloc] initWithX:landmarks.landmark(i).x()
                                                               y:landmarks.landmark(i).y()
                                                               z:landmarks.landmark(i).z()];
            [result addObject:landmark];
        }
        [_delegate irisTrackingDidUpdate:self didOutputLandmarks:result timestamp:packet.Timestamp().Value()];
    }
    if (streamName == kFaceLandmarksOutputStream) {
        if (packet.IsEmpty()) {
            NSLog(@"[TS:%lld] No face landmarks", packet.Timestamp().Value());
            return;
        }
        const auto
        &face_landmarks = packet.Get<::mediapipe::NormalizedLandmarkList>();
        NSMutableArray<MPLandmark *> *result = [NSMutableArray array];
        for (int i = 0; i < face_landmarks.landmark_size(); ++i) {
            MPLandmark *landmark = [[MPLandmark alloc] initWithX:face_landmarks.landmark(i).x()
                                                               y:face_landmarks.landmark(i).y()
                                                               z:face_landmarks.landmark(i).z()];
            [result addObject:landmark];
        }
        [_delegate faceMeshDidUpdate:self didOutputLandmarks:result timestamp:packet.Timestamp().Value()];
    }
}


#pragma mark - MPPInputSourceDelegate methods

// Must be invoked on _videoQueue.
- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer
                timestamp:(CMTime)timestamp
               fromSource:(MPPInputSource *)source {
    if (source != self.cameraSource) {
        NSLog(@"Unknown source: %@", source);
        return;
    }

    // TODO: This is a temporary solution. Need to verify whether the focal length is
    // constant. In that case, we need to use input stream instead of using side packet.
    *(_input_side_packets["focal_length_pixel"].Get<std::unique_ptr<float>>()) =
            self.cameraSource.cameraIntrinsicMatrix.columns[0][0];

    [_delegate frameWillUpdate:self didOutputPixelBuffer:imageBuffer timestamp:timestamp.value];
    [self.mediapipeGraph sendPixelBuffer:imageBuffer
                              intoStream:kInputStream
                              packetType:MPPPacketTypePixelBuffer];
}

@end


@implementation MPLandmark

- (instancetype)initWithX:(float)x y:(float)y z:(float)z {
    self = [super init];
    if (self) {
        _x = x;
        _y = y;
        _z = z;
    }
    return self;
}

@end

