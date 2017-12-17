//
//  FaceDetectionViewController.swift
//  ARFaceDetection
//
//  Created by Ioannis Pasmatzis on 12/12/17.
//  Copyright © 2017 Yanniki. All rights reserved.
//

import UIKit
import ARKit
import Vision

class FaceDetectionViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    
    private var scanTimer: Timer?
    
    private var scannedFaceViews = [UIView]()
    
    //get the orientation of the image that correspond's to the current device orientation
    private var imageOrientation: CGImagePropertyOrientation {
        switch UIDevice.current.orientation {
        case .portrait: return .right
        case .landscapeRight: return .down
        case .portraitUpsideDown: return .left
        case .unknown: fallthrough
        case .faceUp: fallthrough
        case .faceDown: fallthrough
        case .landscapeLeft: return .up
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
        //8 scan for faces in regular intervals
        scanTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(scanForFaces), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        scanTimer?.invalidate()
        sceneView.session.pause()
    }
    
    @objc
    private func scanForFaces() {
        
        //6 remove the test views and empty the array that was keeping a reference to them
        _ = scannedFaceViews.map { $0.removeFromSuperview() }
        scannedFaceViews.removeAll()
        
        //1 get the captured image of the ARSession's current frame 
        guard let capturedImage = sceneView.session.currentFrame?.capturedImage else { return }
        
        //2 create a CIImage
        let image = CIImage.init(cvPixelBuffer: capturedImage)
        
        //3 create VNDetectFaceRectanglesRequest
        let detectFaceRequest = VNDetectFaceRectanglesRequest { (request, error) in
            
            DispatchQueue.main.async {
                //5 Loop through the resulting faces and add a red UIView on top of them.
                if let faces = request.results as? [VNFaceObservation] {
                    for face in faces {
                        let faceView = UIView(frame: self.faceFrame(from: face.boundingBox))
                    
                        faceView.backgroundColor = .red
                    
                        self.sceneView.addSubview(faceView)
                        
                        self.scannedFaceViews.append(faceView)
                    }
                }
            }
        }
        
        //4 ask a VNImageRequestHandler to perform the VNDetectFaceRectanglesRequest
        DispatchQueue.global().async {
            try? VNImageRequestHandler(ciImage: image, orientation: self.imageOrientation).perform([detectFaceRequest])
        }
    }
    
    private func faceFrame(from boundingBox: CGRect) -> CGRect {
        
        //7 translate camera frame to frame inside the ARSKView
        let origin = CGPoint(x: boundingBox.minX * sceneView.bounds.width, y: (1 - boundingBox.maxY) * sceneView.bounds.height)
        let size = CGSize(width: boundingBox.width * sceneView.bounds.width, height: boundingBox.height * sceneView.bounds.height)
        
        return CGRect(origin: origin, size: size)
    }
}

extension FaceDetectionViewController: ARSCNViewDelegate {
    //implement ARSCNViewDelegate functions for things like error tracking
}
