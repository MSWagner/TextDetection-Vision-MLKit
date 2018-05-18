//
//  CGRect+AVtoUIKitConversion.swift
//  TextDetection-Vision-MLKit
//
//  Created by Matthias Wagner on 18.05.18.
//  Copyright © 2018 Matthias Wagner. All rights reserved.
//

import UIKit

extension CGRect {

    func convertFromAVtoUIKit() -> CGRect {
        return CGRect(x: origin.x,
                      y: 1 - origin.y - height,
                      width: width,
                      height: height)
    }
}
