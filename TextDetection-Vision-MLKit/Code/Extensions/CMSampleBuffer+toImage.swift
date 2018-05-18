//
//  CMSampleBuffer+toImage.swift
//  TextDetection-Vision-MLKit
//
//  Created by Matthias Wagner on 18.05.18.
//  Copyright © 2018 Matthias Wagner. All rights reserved.
//

import AVFoundation
import UIKit

extension CMSampleBuffer {

    // Converts a CMSampleBuffer to a UIImage
    //
    // Return: UIImage from CMSampleBuffer
    func toUIImage() -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(self) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))

            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: 1, orientation: .right)
            }
        }
        return nil
    }

    // Converts a CMSampleBuffer to a CGImage
    //
    // Return: CGImage from CMSampleBuffer
    func toCGImage() -> CGImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(self) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))

            if let image = context.createCGImage(ciImage, from: imageRect) {
                return image
            }

        }
        return nil
    }

    // Converts a CMSampleBuffer to a CIImage
    //
    // Return: CIImage from CMSampleBuffer
    func toCIImage() -> CIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(self) {
            return CIImage(cvPixelBuffer: pixelBuffer)
        } else {
            return nil
        }
    }

}
