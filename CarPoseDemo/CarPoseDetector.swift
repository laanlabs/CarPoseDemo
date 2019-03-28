//
//  CarPoseDetector.swift
//  CarPoseDemo
//
//  Created by cc on 3/26/19.
//  Copyright © 2019 Laan Labs. All rights reserved.
//

import Foundation
import UIKit
import CoreML
import Accelerate
import Vision
import SceneKit

enum CarPointState : Int {
    case notLabelled = 0
    case notVisible = 1
    case visible = 2
    
}

struct CarPoint {
    let position : SCNVector3
    let name : String
    var state : CarPointState = .notVisible
}


class CarPoseDetector {
    
    var focalLength : Double = 290.0
    
    // Arbitrary threshold for neural network output
    let keypointScoreThreshold : Double = 0.05
    
    var isDetecting = false
    
    let networkInputSize : Int = 192
    let networkOutputSize : Int = 96
    
    static let carModel = CarPoseModel()
    
    static var visionModel : VNCoreMLModel = {
        return try! VNCoreMLModel(for: CarPoseDetector.carModel.model )
    }()
    
    
    static var carPoints3d : [CarPoint] = {
        
        var pts : [CarPoint] = []
        
        let jsonFile = Bundle.main.path(forResource: "car_points", ofType: "json")!
        return LoadCarJson(jsonFile: jsonFile, flipX: true)
        
    }()
    
    static var modelPoints3d : [Double] = {
        var pts : [Double] = []
        for p in CarPoseDetector.carPoints3d {
            pts.append(Double(p.position.x))
            pts.append(Double(p.position.y))
            pts.append(Double(p.position.z))
        }
        print("loaded car points: ", pts.count)
        
       return pts
    }()
    
    
    static func LoadCarJson( jsonFile : String,
                             flipX : Bool = false ) -> [CarPoint] {
        
        var pts : [CarPoint] = []
        
        if FileManager.default.fileExists(atPath: jsonFile ) {
            
            let json = try! JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: jsonFile)),
                                                         options: .init(rawValue: 0) ) as! [ [String:Any] ]
            
            for item in json {
                
                var x : Float = (item["x"] as! NSNumber).floatValue
                let y : Float = (item["y"] as! NSNumber).floatValue
                let z : Float = (item["z"] as? NSNumber)?.floatValue ?? -1.0
                
                let name : String = item["name"] as! String
                let state : Int = (item["state"] as? Int) ?? 0
                
                if flipX {
                    x = x * -1.0
                }
                
                pts.append(CarPoint(position: SCNVector3(x, y, z),
                                    name: name,
                                    state: CarPointState(rawValue: state)! ))
                
            }
            
        }
        
        return pts
        
        
    }
    
    
    
    
    func getCarPose(pixelBuffer : CVPixelBuffer?,
                    complete: @escaping (PoseResult?)->() ) {
        
        
        if self.isDetecting {
            complete(nil)
            return
        }
        
        self.isDetecting = true
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer!)
        
        
        let request = VNCoreMLRequest(model: CarPoseDetector.visionModel) { (request, error) in
            
            if let error = error {
                
                print(" Error processing vision: ", error )
                complete(nil)
                
            } else {
                
                
                if let observations = request.results as? [VNCoreMLFeatureValueObservation],
                    let features = observations.first?.featureValue.multiArrayValue {
                    
                    let carResult = self.getPoseForFeatures( features: features )
                    
                    complete( carResult )
                    
                }
            }
        }
        
        
        request.imageCropAndScaleOption = .scaleFit
        
        DispatchQueue.global().async {
            
            do {
                
                try handler.perform([request])
                self.isDetecting = false
                
            } catch {
                
                complete(nil)
                self.isDetecting = false
                
            }
            
            
        }
        
        
        
    }
    
    private func getPoseForFeatures( features : MLMultiArray ) -> PoseResult? {
        
        let result = PoseUtils.estimatePose(fromHeatmap: features,
                                            modelPoints: &CarPoseDetector.modelPoints3d,
                                            imageWidth: Int32(self.networkInputSize),
                                            imageHeight: Int32(self.networkInputSize),
                                            focalLength: self.focalLength,
                                            scoreThreshold: self.keypointScoreThreshold)

        return result
                                         
                                         
    }
    
    

}
