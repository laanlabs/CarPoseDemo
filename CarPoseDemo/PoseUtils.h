//
//  PoseUtils.h
//  CarPoseDemo
//
//  Created by cc on 3/26/19.
//  Copyright © 2019 Laan Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreML/CoreML.h>
#import <SceneKit/SceneKit.h>



// Keypoint indices shuffled during training. TODO
const int UNITY_TO_NN_LAYER[] = {0, 1, 5, 2, 6, 3, 7, 4, 11, 8, 12, 9, 13, 10,};


@interface PoseResult : NSObject

@property (nonatomic) bool foundPose;
@property (nonatomic) SCNMatrix4 transform;
@property (nonatomic) SCNMatrix4 scenekitCameraTransform;
@property (nonatomic) float fovDegreesForEstimatedPose;
@property (nonatomic) double totalKeypointScore;
@property (nonatomic) double estimatedFocalLength;

@end



@interface PoseUtils : NSObject

+ (PoseResult*) estimatePoseFromHeatmap:(MLMultiArray*)networkOutput
                            modelPoints:(double*)modelPoints3d
                             imageWidth:(int)imageWidth
                            imageHeight:(int)imageHeight
                            focalLength:(double)focal_length
                         scoreThreshold:(double)scoreThreshold;


@end


