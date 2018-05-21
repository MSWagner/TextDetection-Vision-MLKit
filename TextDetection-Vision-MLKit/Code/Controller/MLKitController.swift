//
//  MLKitController.swift
//  TextDetection-Vision-MLKit
//
//  Created by Matthias Wagner on 21.05.18.
//  Copyright © 2018 Matthias Wagner. All rights reserved.
//

import Foundation
import FirebaseMLVision

class MLKitController {
    private init() {}

    private lazy var mlVision = Vision.vision()
    private var mlTextDetector: VisionTextDetector?
    
    static let shared = MLKitController()

    func detectTextIn(_ sampleBuffer: CMSampleBuffer, completion: @escaping VisionTextDetectionCallback) {
        mlTextDetector = mlVision.textDetector()

        let metadata = VisionImageMetadata()
        metadata.orientation = .rightTop

        let mlImage = VisionImage(buffer: sampleBuffer)
        mlImage.metadata = metadata

        mlTextDetector?.detect(in: mlImage, completion: completion)
    }

}
