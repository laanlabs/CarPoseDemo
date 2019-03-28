//
//  PoseUtils.m
//  CarPoseDemo
//
//  Created by cc on 3/26/19.
//  Copyright © 2019 Laan Labs. All rights reserved.
//

#import "PoseUtils.h"

#include "opencv2/core/core.hpp"
#include <opencv2/opencv.hpp>

using namespace std;
using namespace cv;


@implementation PoseResult
@end


@implementation PoseUtils

+ (PoseResult*) estimatePoseFromHeatmap:(MLMultiArray*)networkOutput
                            modelPoints:(double*)modelPoints3d
                             imageWidth:(int)imageWidth
                            imageHeight:(int)imageHeight
                            focalLength:(double)focal_length
                         scoreThreshold:(double)scoreThreshold {
    
    int numPoints = (int)networkOutput.shape[0].integerValue;
    
    NSAssert(numPoints == 14, @"wrong shape index");
    
    double outputSize = networkOutput.shape[1].doubleValue;
    
    std::vector<cv::Point3d> max_heatmap_points;
    std::vector<cv::Point3d> nn_out_maxes = [PoseUtils getMaxPoints:networkOutput];
    
    for ( int i = 0; i < numPoints; i ++ ) {
        int heatmap_idx = UNITY_TO_NN_LAYER[i];
        max_heatmap_points.push_back(nn_out_maxes[heatmap_idx]);
    }
    
    double total_score = 0.0;
    
    // Limit solvePnP to points with scores above a threshold
    vector<Point2d> image_points;
    vector<Point3d> model_points;

    for ( int i = 0; i < numPoints; i ++ ) {
        
        // rescale to image size:
        Point3d p1 = max_heatmap_points[i];
        float score = p1.z;
        
        p1 = (p1 / outputSize) * ((double)imageWidth);
        
        if ( score > scoreThreshold ) {
            total_score += score;
            image_points.push_back( Point2d(p1.x, p1.y) );
            model_points.push_back( Point3d( modelPoints3d[3*i] , modelPoints3d[3*i+1], modelPoints3d[3*i+2] ));
        }
        
    }
    
    PoseResult * result = [PoseResult new];
    
    if ( image_points.size() < 4 ) {
        result.foundPose = false;
        return result;
    }
    
    
    cv::Point2d center = cv::Point2d(imageWidth/2, imageHeight/2);
    
    cv::Mat camera_matrix = (cv::Mat_<double>(3,3) << focal_length, 0, center.x, 0 , focal_length, center.y, 0, 0, 1);
    
    cv::Mat dist_coeffs = cv::Mat::zeros(4,1,cv::DataType<double>::type); // Assuming no lens distortion
    
    cv::Mat rotation_vector;
    cv::Mat translation_vector;
    
    solvePnPRansac(model_points, image_points, camera_matrix, dist_coeffs, rotation_vector, translation_vector);
    
    // TODO: use reprojected model points scores
    //vector<Point2d> reprojected_car2D;
    //projectPoints(model_points, rotation_vector, translation_vector, camera_matrix, dist_coeffs, reprojected_car2D);
    
    result.totalKeypointScore = total_score;
    
    
    Mat expandedR;
    Rodrigues(rotation_vector, expandedR);
    
    SCNMatrix4 transform = SCNMatrix4Identity;
    
    // col 1
    transform.m11 = expandedR.at<double>(0,0);
    transform.m12 = expandedR.at<double>(1,0);
    transform.m13 = expandedR.at<double>(2,0);
    
    // col 2
    transform.m21 = expandedR.at<double>(0,1);
    transform.m22 = expandedR.at<double>(1,1);
    transform.m23 = expandedR.at<double>(2,1);
    
    // col 3
    transform.m31 = expandedR.at<double>(0,2);
    transform.m32 = expandedR.at<double>(1,2);
    transform.m33 = expandedR.at<double>(2,2);
    
    // translation
    transform.m41 = translation_vector.at<double>(0,0);
    transform.m42 = translation_vector.at<double>(1,0);
    transform.m43 = translation_vector.at<double>(2,0);
    
    result.transform = transform;
    
    
    return result;
    
    
}


// x,y, score
+(std::vector<Point3d>) getMaxPoints:(MLMultiArray*)input {
    
    std::vector<Point3d> maxPoints;
    
    bool blurMaxPoints = true;
    
    int numChannels = (int)input.shape[0].integerValue;
    int outputHeight = (int)input.shape[1].integerValue;
    int outputWidth = (int)input.shape[2].integerValue;
    
    double * data = (double *)input.dataPointer;
    
    int blurSize = 3;
    
    const int image_size = outputWidth * outputHeight;
    
    double max_points[3 * numChannels];
    
    for ( int d = 0; d < numChannels; d++) {
        
        float maxVal = -100000.0;
        
        int channel_ptr = d * image_size;
        cv::Mat channelImage = cv::Mat(outputHeight, outputWidth, CV_64F, data+channel_ptr);
        
        if ( blurMaxPoints ) {
            cv::GaussianBlur(channelImage, channelImage, cv::Size2d(blurSize, blurSize), 0);
        }
        
        for ( int y = 0; y < outputHeight; y ++ ) {
            for ( int x = 0; x < outputWidth; x ++ ) {
                
                double val = channelImage.at<double>(y,x);
                
                if ( val > maxVal ) {
                    
                    maxVal = val;
                    max_points[3*d] = x;
                    max_points[3*d+1] = y;
                    max_points[3*d+2] = val;
                    
                }
                
            }
            
        }
        
    }
    
    
    for ( int d = 0; d < numChannels; d ++ ) {
        maxPoints.push_back(Point3d( max_points[3*d], max_points[3*d+1], max_points[3*d+2] ));
    }
    
    return maxPoints;
    
}



@end
