//
//  PickImageViewController.swift
//  TextDetection-Vision-MLKit
//
//  Created by Matthias Wagner on 18.05.18.
//  Copyright © 2018 Matthias Wagner. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import FirebaseMLVision
import GDPerformanceView_Swift

class TrackingViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var visionButton: UIBarButtonItem!
    @IBOutlet weak var mlKitButton: UIBarButtonItem!
    
    @IBOutlet weak var visionSwitch: UISwitch!
    @IBOutlet weak var mlKitSwitch: UISwitch!
    @IBOutlet weak var drawingSwitch: UISwitch!
    
    // MARK: - Performance Properties

    var performanceView = GDPerformanceMonitor.init()

    // MARK: - Switch Properties

    private var isVisionOn: Bool = false
    private var isMLKitOn: Bool = false
    private var shouldDrawRects: Bool = true

    // MARK: - AVSession

    private var session = AVCaptureSession()
    private var videoLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Vision Properties

    private var visionRequests = [VNRequest]()
    private var pixelBuffer: CMSampleBuffer?
    private var lastBoxRect: CGRect?

    // MARK: - MLKit Properties

    lazy var mlVision = Vision.vision()
    private var mlTextDetector: VisionTextDetector?
    private var mlFrameSublayer = CALayer()

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPerformanceView()
        setupVideo()
        setupVision()
        setupMLKit()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        performanceView.startMonitoring()

        shouldDrawRects = drawingSwitch.isOn
        isVisionOn = visionSwitch.isOn
        isMLKitOn = mlKitSwitch.isOn
        session.startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }

    override func viewDidLayoutSubviews() {
        imageView.layer.sublayers?[0].frame = imageView.bounds
        imageView.layer.sublayers?[1].frame = imageView.bounds
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailViewController = segue.destination as? DetailViewController {
            guard let pixelBuffer = pixelBuffer, let image = pixelBuffer.toUIImage() else {
                return
            }

            detailViewController.boxRect = lastBoxRect
            detailViewController.image = image
        }
    }

    // MARK: - Setup

    private func setupPerformanceView() {
        performanceView.startMonitoring()
        performanceView.appVersionHidden = true
        performanceView.deviceVersionHidden = true
    }

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

        videoLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer!.frame = imageView.bounds
        imageView.layer.addSublayer(videoLayer!)

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

    // MARK: - IBActions

    @IBAction func onMLKitSwitch(_ sender: Any) {
        isMLKitOn = mlKitSwitch.isOn
        if !isMLKitOn {
            removeFrames()
            mlKitButton.title = "ML-Kit: -"
        }
    }

    @IBAction func onVisionSwitch(_ sender: Any) {
        isVisionOn = visionSwitch.isOn
        if !isVisionOn {
            imageView.layer.sublayers?.removeSubrange(2...)
            visionButton.title = "Vision: -"
        }
    }

    @IBAction func onDrawingSwitch(_ sender: Any) {
        shouldDrawRects = drawingSwitch.isOn

        if !shouldDrawRects {
            imageView.layer.sublayers?.removeSubrange(2...)
            removeFrames()
        }
    }

    // MARK: - Vision

    private func visionRequestHandler(request: VNRequest, error: Error?) {
        guard let results = request.results else { return }

        let textObservations = results.compactMap { $0 as? VNTextObservation }

        DispatchQueue.main.async {
            self.imageView.layer.sublayers?.removeSubrange(2...)

            if !self.isVisionOn { return }
            self.visionButton.title = "Vision: \(textObservations.count)"

            if !self.shouldDrawRects { return }
            textObservations.forEach { self.highlightVisionWord(box: $0) }
        }
    }

    private func highlightVisionWord(box: VNTextObservation) {

        let detectedBox = box.boundingBox.convertFromAVtoUIKit().resizeTo(imageView.frame)

        lastBoxRect = box.boundingBox

        let boxOutline = CALayer()
        boxOutline.frame = detectedBox
        boxOutline.borderWidth = 2.0
        boxOutline.borderColor = UIColor.blue.cgColor
        imageView.layer.addSublayer(boxOutline)
    }

    // MARK: - ML Kit

    /// Converts a feature frame to a frame UIView that is displayed over the image.
    ///
    /// - Parameters:
    ///   - featureFrame: The rect of the feature with the same scale as the original image.
    ///   - imageSize: The size of original image.
    ///   - viewRect: The view frame rect on the screen.
    private func addFrameView(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect, text: String? = nil) {

        /// TODO: Adjust this function for accurate frame drawing

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
                                       width: featureHeightScaled,
                                       height: featureWidthScaled)

        drawFrame(featureRectScaled, text: text)
    }

    /// Creates and draws a frame for the calculated rect as a sublayer.
    ///
    /// - Parameter rect: The rect to draw.
    private func drawFrame(_ rect: CGRect, text: String? = nil) {
        let bpath: UIBezierPath = UIBezierPath(rect: rect)
        let rectLayer: CAShapeLayer = CAShapeLayer()
        rectLayer.path = bpath.cgPath
        rectLayer.strokeColor = UIColor.red.cgColor
        rectLayer.fillColor = UIColor.clear.cgColor
        rectLayer.lineWidth = 2
        if let text = text {
            let textLayer = CATextLayer()
            textLayer.string = text
            textLayer.fontSize = 12.0
            textLayer.foregroundColor = UIColor.black.cgColor
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
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension TrackingViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        self.pixelBuffer = sampleBuffer

        // MARK: - Vision Buffer Handling

        if isVisionOn {
            var requestOptions: [VNImageOption: Any] = [:]

            if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
                requestOptions = [.cameraIntrinsics:camData]
            }

            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: requestOptions)

            do {
                try imageRequestHandler.perform(self.visionRequests)
            } catch {
                print(error)
            }
        }

        // MARK: - MLKit Buffer Handling

        if isMLKitOn {
            mlTextDetector = mlVision.textDetector()

            let metadata = VisionImageMetadata()
            metadata.orientation = .rightTop

            let mlImage = VisionImage(buffer: sampleBuffer)
            mlImage.metadata = metadata

            mlTextDetector?.detect(in: mlImage, completion: { [weak self] features, error in
                guard let `self` = self else { return }

                self.removeFrames()
                if !self.isMLKitOn { return }

                if let error = error {
                    print(error.localizedDescription)
                    return
                }

                DispatchQueue.main.async {
                    if !self.isMLKitOn { return }
                    self.mlKitButton.title = features != nil ? "ML-Kit: \(features!.count)" : "ML-Kit: 0"
                }

                if self.shouldDrawRects {
                    features?.forEach { mlKitText in
                        print("MLText: \(mlKitText.text)")
                        self.addFrameView(featureFrame: mlKitText.frame, imageSize: sampleBuffer.toUIImage()!.size, viewFrame: self.imageView.frame, text: mlKitText.text)
                    }
                }
            })
        }
    }
}
