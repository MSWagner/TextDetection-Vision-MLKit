//
//  CGRect+ResizeTo.swift
//  TextDetection-Vision-MLKit
//
//  Created by Matthias Wagner on 18.05.18.
//  Copyright © 2018 Matthias Wagner. All rights reserved.
//

import UIKit

extension CGRect {
    func resizeTo(_ rect: CGRect) -> CGRect {
        return CGRect(x: origin.x * rect.width,
                      y: origin.y * rect.height,
                      width: width * rect.width,
                      height: height * rect.height)
    }

    func resizeTo(_ image: UIImage) -> CGRect {
        return CGRect(x: origin.x * image.size.width,
                      y: origin.y * image.size.height,
                      width: width * image.size.width,
                      height: height * image.size.height)
    }
}
