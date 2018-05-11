//
//  VideoViewController.swift
//  TextDetection-Vision-MLKit
//
//  Created by Matthias Wagner on 11.05.18.
//  Copyright © 2018 Matthias Wagner. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import FirebaseMLVision

class VideoViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    private var session = AVCaptureSession()

    // MARK: - Vision Properties

    private var visionRequests = [VNRequest]()

    // MARK: - MLKit Properties

    lazy var mlVision = Vision.vision()
    private var mlTextDetector: VisionTextDetector?
    private var mlFrameSublayer = CALayer()


    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupVideo()
        setupVision()
        setupMLKit()
    }

    override func viewDidLayoutSubviews() {
        imageView.layer.sublayers?[0].frame = imageView.bounds
        imageView.layer.sublayers?[1].frame = imageView.bounds
    }

    // MARK: - Setup

    private func setupVideo() {

        /// MLKit detection works not really with photo quality
        session.sessionPreset = AVCaptureSession.Preset.high
        let device = AVCaptureDevice.default(for: .video)

        let input = try! AVCaptureDeviceInput(device: device!)

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))

        session.addInput(input)
        session.addOutput(output)

        let videoLayer = AVCaptureVideoPreviewLayer(session: session)
        imageView.frame = imageView.bounds
        imageView.layer.addSublayer(videoLayer)

        session.startRunning()
    }

    private func setupVision() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.visionRequestHandler)
        textRequest.reportCharacterBoxes = true
        self.visionRequests = [textRequest]
    }

    private func setupMLKit() {
        imageView.layer.addSublayer(mlFrameSublayer)
        mlTextDetector = mlVision.textDetector()

    }

    // MARK: - Vision

    private func visionRequestHandler(request: VNRequest, error: Error?) {
        guard let results = request.results else { return }

        let textObservations = results.compactMap { $0 as? VNTextObservation }

        DispatchQueue.main.async {
            self.imageView.layer.sublayers?.removeSubrange(2...)
            textObservations.forEach { self.highlightVisionWord(box: $0) }
        }
    }


    // MARK: Helper Functions

    private func highlightVisionWord(box: VNTextObservation) {
        guard let boxes = box.characterBoxes else { return }

        var maxX: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9999.0
        var minY: CGFloat = 0.0

        for char in boxes {
            if char.bottomLeft.x < maxX {
                maxX = char.bottomLeft.x
            }
            if char.bottomRight.x > minX {
                minX = char.bottomRight.x
            }
            if char.bottomRight.y < maxY {
                maxY = char.bottomRight.y
            }
            if char.topRight.y > minY {
                minY = char.topRight.y
            }
        }

        let xCord = maxX * imageView.frame.size.width
        let yCord = (1 - minY) * imageView.frame.size.height
        let width = (minX - maxX) * imageView.frame.size.width
        let height = (minY - maxY) * imageView.frame.size.height

        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.blue.cgColor

        imageView.layer.addSublayer(outline)
    }

    private func highlightMLKitWord(features: [VisionText]?, error: Error?) {
        removeFrames()

        guard let features = features, !features.isEmpty else {
            return
        }
        print("text")

        for text in features {
            if let block = text as? VisionTextBlock {
                for line in block.lines {
                    for element in line.elements {
                        self.addFrameView(
                            featureFrame: element.frame,
                            imageSize: imageView.bounds.size,
                            viewFrame: self.imageView.frame,
                            text: element.text
                        )
                    }
                }
            }
        }
    }

    /// Converts a feature frame to a frame UIView that is displayed over the image.
    ///
    /// - Parameters:
    ///   - featureFrame: The rect of the feature with the same scale as the original image.
    ///   - imageSize: The size of original image.
    ///   - viewRect: The view frame rect on the screen.
    private func addFrameView(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect, text: String? = nil) {
        print("Frame: \(featureFrame).")

        /// TODO: Adjust high quality frame sizes to the imageView frame to show the labels correct

        let viewSize = viewFrame.size

        // Find resolution for the view and image
        let rView = viewSize.width / viewSize.height
        let rImage = imageSize.width / imageSize.height

        // Define scale based on comparing resolutions
        var scale: CGFloat
        if rView > rImage {
            scale = viewSize.height / imageSize.height
        } else {
            scale = viewSize.width / imageSize.width
        }

        // Calculate scaled feature frame size
        let featureWidthScaled = featureFrame.size.width * scale
        let featureHeightScaled = featureFrame.size.height * scale

        // Calculate scaled feature frame top-left point
        let imageWidthScaled = imageSize.width * scale
        let imageHeightScaled = imageSize.height * scale

        let imagePointXScaled = (viewSize.width - imageWidthScaled) / 2
        let imagePointYScaled = (viewSize.height - imageHeightScaled) / 2

        let featurePointXScaled = imagePointXScaled + featureFrame.origin.x * scale
        let featurePointYScaled = imagePointYScaled + featureFrame.origin.y * scale

        // Define a rect for scaled feature frame
        let featureRectScaled = CGRect(x: featurePointXScaled,
                                       y: featurePointYScaled,
                                       width: featureWidthScaled,
                                       height: featureHeightScaled)

        drawFrame(featureRectScaled, text: text)
    }

    /// Creates and draws a frame for the calculated rect as a sublayer.
    ///
    /// - Parameter rect: The rect to draw.
    private func drawFrame(_ rect: CGRect, text: String? = nil) {
        let bpath: UIBezierPath = UIBezierPath(rect: rect)
        let rectLayer: CAShapeLayer = CAShapeLayer()
        rectLayer.path = bpath.cgPath
        rectLayer.strokeColor = Constants.lineColor
        rectLayer.fillColor = Constants.fillColor
        rectLayer.lineWidth = Constants.lineWidth
        if let text = text {
            let textLayer = CATextLayer()
            textLayer.string = text
            textLayer.fontSize = 12.0
            textLayer.foregroundColor = Constants.lineColor
            let center = CGPoint(x: rect.midX, y: rect.midY)
            textLayer.position = center
            textLayer.frame = rect
            textLayer.alignmentMode = kCAAlignmentCenter
            textLayer.contentsScale = UIScreen.main.scale
            mlFrameSublayer.addSublayer(textLayer)
        }
        mlFrameSublayer.addSublayer(rectLayer)
    }

    private func removeFrames() {
        guard let sublayers = mlFrameSublayer.sublayers else { return }
        for sublayer in sublayers {
            guard let frameLayer = sublayer as CALayer? else {
                print("Failed to remove frame layer.")
                continue
            }
            frameLayer.removeFromSuperlayer()
        }
    }

    private func detectorOrientation(in image: UIImage) -> VisionDetectorImageOrientation {
        switch image.imageOrientation {
        case .up:
            return .topLeft
        case .down:
            return .bottomRight
        case .left:
            return .leftBottom
        case .right:
            return .rightTop
        case .upMirrored:
            return .topRight
        case .downMirrored:
            return .bottomLeft
        case .leftMirrored:
            return .leftTop
        case .rightMirrored:
            return .rightBottom
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension VideoViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }


        // MARK: - Vision Buffer Handling

        var requestOptions: [VNImageOption: Any] = [:]

        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)

        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }

        // MARK: - MLKit Buffer Handling

        mlTextDetector = mlVision.textDetector()

        let metadata = VisionImageMetadata()
        metadata.orientation = .rightTop

        let mlImage = VisionImage(buffer: sampleBuffer)
        mlImage.metadata = metadata

        mlTextDetector?.detect(in: mlImage, completion: { [weak self] features, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self?.highlightMLKitWord(features: features, error: error)
        })
    }
}


// MARK: - Fileprivate

fileprivate enum Constants {
    static let lineWidth: CGFloat = 3.0
    static let lineColor = UIColor.red.cgColor
    static let fillColor = UIColor.clear.cgColor
}
