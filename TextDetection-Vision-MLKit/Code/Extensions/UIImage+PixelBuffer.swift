//
//  UIImage+PixelBuffer.swift
//  TextDetection-Vision-MLKit
//
//  Created by Matthias Wagner on 18.05.18.
//  Copyright © 2018 Matthias Wagner. All rights reserved.
//

import UIKit
import VideoToolbox

extension UIImage {
    /**
     Creates a new UIImage from a CVPixelBuffer.
     NOTE: This only works for RGB pixel buffers, not for grayscale.
     */
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, nil, &cgImage)

        if let cgImage = cgImage {
            self.init(cgImage: cgImage)
        } else {
            return nil
        }
    }

    /**
     Creates a new UIImage from a CVPixelBuffer, using Core Image.
     */
    public convenience init?(pixelBuffer: CVPixelBuffer, context: CIContext) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let rect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer),
                          height: CVPixelBufferGetHeight(pixelBuffer))
        if let cgImage = context.createCGImage(ciImage, from: rect) {
            self.init(cgImage: cgImage)
        } else {
            return nil
        }
    }
}
