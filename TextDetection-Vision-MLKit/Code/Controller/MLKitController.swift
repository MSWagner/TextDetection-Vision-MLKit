//
//  MLKitController.swift
//  TextDetection-Vision-MLKit
//
//  Created by Matthias Wagner on 21.05.18.
//  Copyright © 2018 Matthias Wagner. All rights reserved.
//

import Foundation
import FirebaseMLVision
import ReactiveSwift
import Result

class MLKitController {
    private init() {}

    static let shared = MLKitController()

    // MARK: - Properties

    private lazy var mlVision = Vision.vision()
    private var mlTextDetector: VisionTextDetector?

    private var mlTextDetectors = [VisionTextDetector]()

    var detectionSignalProducers = [SignalProducer<[VisionText]?, MLKitError>]()

    // MARK: - Detection Functions

    func detectTextIn(_ sampleBuffer: CMSampleBuffer, completion: @escaping VisionTextDetectionCallback) {
        mlTextDetector = mlVision.textDetector()

        let metadata = VisionImageMetadata()
        metadata.orientation = .rightTop

        let mlImage = VisionImage(buffer: sampleBuffer)
        mlImage.metadata = metadata

        mlTextDetector?.detect(in: mlImage, completion: completion)
    }

    func detectTextIn(_ image: UIImage) -> SignalProducer<[VisionText]?, MLKitError> {
        let signalProducer = SignalProducer<[VisionText]?, MLKitError> { [weak self] (sink, _) in
            guard let `self` = self else { return }

            let newTextDetector = self.mlVision.textDetector()
            self.mlTextDetectors.append(newTextDetector)

            let mlImage = VisionImage(image: image)

            newTextDetector.detect(in: mlImage, completion: { (visionTexts, error) in

                if error != nil {
                    sink.send(error: .notDetected)
                } else {
                    sink.send(value: visionTexts)
                    sink.sendCompleted()
                }
            })
        }

        detectionSignalProducers.append(signalProducer)
        return signalProducer
    }

}

enum MLKitError: Swift.Error, LocalizedError {
    case notDetected
}
