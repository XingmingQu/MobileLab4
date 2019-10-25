//
//  ModuleAViewController.swift
//  ImageLab
//
//  Created by Xingming on 10/24/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

import UIKit

class ModuleAViewController: UIViewController {
    
    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    var detector:CIDetector! = nil
    
    let pinchFilterIndex = 2
    let bridge = OpenCVBridge()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        self.setupFilters()
        
        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.front)
        
        // create dictionary for face detection
        // HINT: you need to manipulate these proerties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyLow]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: self.videoManager.getCIContext(), // perform on the GPU if possible
                                  options: optsDetector)
        
        self.bridge.setTransforms(self.videoManager.transform)
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        
        
        if !videoManager.isRunning{
            videoManager.start()
        }
        
        self.bridge.processType = 1

        // Do any additional setup after loading the view.
    }
    
    
    
    //MARK: Process image output
    func processImage(inputImage:CIImage) -> CIImage{
        
        // detect faces
        let f = getFaces(img: inputImage)
        
        // if no faces, just return original image
        if f.count == 0 { return inputImage }
        
        var retImage = inputImage
        
        // use this code if you are using OpenCV and want to overwrite the displayed image via OpenCv
        // this is a BLOCKING CALL
        self.bridge.setImage(retImage, withBounds: f[0].bounds, andContext: self.videoManager.getCIContext())
        self.bridge.processImage()
        retImage = self.bridge.getImageComposite()
        
        //HINT: you can also send in the bounds of the face to ONLY process the face in OpenCV
        // or any bounds to only process a certain bounding region in OpenCV
        
        return retImage
    }
    
    //MARK: Setup filtering
    func setupFilters(){
        filters = []
        
        let filterPinch = CIFilter(name:"CIBumpDistortion")!
        filterPinch.setValue(-0.5, forKey: "inputScale")
        filterPinch.setValue(75, forKey: "inputRadius")
        filters.append(filterPinch)
        
    }
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
         // this ungodly mess makes sure the image is the correct orientation
         let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation]
         // get Face Features
         return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
         
     }
     

}
