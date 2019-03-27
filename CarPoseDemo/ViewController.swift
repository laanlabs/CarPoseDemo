//
//  ViewController.swift
//  CarPoseDemo
//
//  Created by cc on 3/26/19.
//  Copyright © 2019 Laan Labs. All rights reserved.
//

import UIKit
import SceneKit
import ARKit


extension Date {
    var secondsAgo : TimeInterval {
        return -self.timeIntervalSinceNow
    }
    var millisecondsAgo : TimeInterval {
        return -self.timeIntervalSinceNow * 1000.0
    }
}


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    let carParentNode = SCNNode()
    
    
    var runningDetection = false
    
    var lastDetectionTime = Date.distantPast
    let carDetectionIntervalMs : Double = 110.0
    
    let poseDetector = CarPoseDetector()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.automaticallyUpdatesLighting = false
        
        
        // Create a new scene
        let scene = SCNScene()
        // Set the scene to the view
        sceneView.scene = scene
        
        self.addCarObject()
        
        
    }
    
    override var shouldAutorotate: Bool { return true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        
        guard let pov = self.sceneView.pointOfView,
            let frame = self.sceneView.session.currentFrame else { return }
        
        if !self.runningDetection && lastDetectionTime.millisecondsAgo > carDetectionIntervalMs {
            
            self.runningDetection = true
            self.lastDetectionTime = Date()
            
            let cameraTransform = pov.worldTransform
            
            let buffer = frame.capturedImage
            
            let fx = frame.camera.intrinsics.columns.0.x
            
            let scale = Double(poseDetector.networkInputSize) / Double(frame.camera.imageResolution.width)
            
            poseDetector.focalLength = Double(fx) * scale
            
            poseDetector.getCarPose(pixelBuffer: buffer) { (_result) in
                
                if let result = _result {
                    
                    let estimatedCamera = SCNMatrix4Invert(result.scenekitCameraTransform)
                    
                    let meanScore = result.totalKeypointScore / 14.0
                    
                    if meanScore >= 0.5 {
                        SCNTransaction.begin()
                        SCNTransaction.animationDuration = 0.15
                        self.carParentNode.transform = SCNMatrix4Mult(estimatedCamera, cameraTransform)
                        SCNTransaction.commit()
                    }
                    
                    DispatchQueue.main.async {
                        print(" Mean score: ", meanScore )
                        //self.label.text = " sum: %4.1f  mean:  %5.2f ".format(result.sumOfMaxPerChannel,
                        //                                                      meanScore)
                    }
                    
                    
                }
                
                self.runningDetection = false
                
            }
            
            
        }
        
        
    }
    
    
    
    
    
    func addCarObject() {
        
        let scene = SCNScene(named: "art.scnassets/car.scn")!
        
        let car = scene.rootNode.childNode(withName: "car", recursively: true)!
        
        car.geometry?.firstMaterial?.fillMode = .lines
        car.geometry?.firstMaterial?.lightingModel = .constant
        car.geometry?.firstMaterial?.diffuse.contents = UIColor.magenta
        
        self.carParentNode.addChildNode(car)
        self.sceneView.scene.rootNode.addChildNode(self.carParentNode)
        
        
    }
    
    
}
