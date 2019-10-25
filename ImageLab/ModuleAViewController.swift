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
    var eyeMouthFilter=0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        filters = self.setupFilters()

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
        
        
        // --------detect faces and high light-----------------------
        let f = getFaces(img: inputImage)
        // if no faces, just return original image
        if f.count == 0 { return inputImage }
        var retImage = inputImage
        //Highlights multiple faces in the scene using CoreImage filters
        for faces in f {
            self.bridge.setImage(retImage, withBounds: faces.bounds, andContext: self.videoManager.getCIContext())
            
            self.bridge.processImage()
            retImage = self.bridge.getImageComposite()
            
            
            //---------------detect eyes and mouth-----------
            //select a fliter
            let selectedFilter=self.filters[self.eyeMouthFilter]
            
            
            if (faces.hasMouthPosition) {
                selectedFilter.setValue(retImage, forKey: kCIInputImageKey)
                selectedFilter.setValue(CIVector(cgPoint: faces.mouthPosition), forKey: "inputCenter")
                selectedFilter.setValue(50, forKey: "inputRadius")
                retImage = selectedFilter.outputImage!
            }
            if (faces.hasLeftEyePosition) {
                selectedFilter.setValue(retImage, forKey: kCIInputImageKey)
                selectedFilter.setValue(CIVector(cgPoint: faces.leftEyePosition), forKey: "inputCenter")
                selectedFilter.setValue(30, forKey: "inputRadius")
                retImage = selectedFilter.outputImage!
            }
            if (faces.hasRightEyePosition) {
                selectedFilter.setValue(retImage, forKey: kCIInputImageKey)
                selectedFilter.setValue(CIVector(cgPoint: faces.rightEyePosition), forKey: "inputCenter")
                selectedFilter.setValue(30, forKey: "inputRadius")
                retImage = selectedFilter.outputImage!
            }

            
        }
        //--------------------------------------------------------------
        
        
        
        return retImage
    }
    
    //MARK: Setup filtering
    func setupFilters()->[CIFilter]{
        filters = []
//https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/
        
        filters.append(CIFilter(name:"CIBumpDistortion")!)
        
        filters.append(CIFilter(name:"CITorusLensDistortion")!)
        filters.append(CIFilter(name:"CIVortexDistortion")!)
        filters.append(CIFilter(name:"CITwirlDistortion")!)
//        filterPinch.setValue(-0.5, forKey: "inputScale")
//        filterPinch.setValue(75, forKey: "inputRadius")
        return filters
        
    }
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
    
    @IBAction func switchCamera(_ sender: UIButton) {
        self.videoManager.toggleCameraPosition()
    }
    
    
    @IBAction func changeHightLightStyle(_ sender: Any) {
        self.bridge.processType = (self.bridge.processType+1)%11+1
    }
    @IBAction func changeEyeMouthStyle(_ sender: UIButton) {
        self.eyeMouthFilter = (self.eyeMouthFilter+1)%4
    }
    
}
