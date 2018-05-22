//
//  VisionResult.swift
//  TextDetection-Vision-MLKit
//
//  Created by Matthias Wagner on 22.05.18.
//  Copyright © 2018 Matthias Wagner. All rights reserved.
//

import ReactiveSwift
import UIKit

struct VisionResult {
    let resultImage: UIImage
    var resultStrings = MutableProperty<[String?]>([nil])

    init(image: UIImage) {
        resultImage = image
    }
}
