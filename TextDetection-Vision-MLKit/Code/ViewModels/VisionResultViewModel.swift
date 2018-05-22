//
//  VisionResultViewModel.swift
//  TextDetection-Vision-MLKit
//
//  Created by Matthias Wagner on 22.05.18.
//  Copyright © 2018 Matthias Wagner. All rights reserved.
//

import Foundation
import ReactiveSwift

class VisionResultViewModel {

    private var model: VisionResult

    init(model: VisionResult) {
        self.model = model

        MLKitController.shared.detectTextIn(model.resultImage).startWithResult { result in
            switch result {

            case .success(let visionTexts):
                print("ML Detection Success")

                guard let visionTexts = visionTexts else {
                    print("ML Detection Empty")

                    model.resultStrings.value = []
                    return
                }

                var textArray = [String]()
                for visionText in visionTexts {
                    print("VisionText: \(visionText.text)")
                    textArray.append(visionText.text)
                }

                print("ML Detection Values: \(textArray.count)")

                model.resultStrings.value = textArray

            case .failure(_):
                print("ML Detection Error")

                model.resultStrings.value = []
            }

            self.resultText.value = model.resultStrings.value.compactMap { $0 }.joined(separator: " ")
        }

    }

    var resultText = MutableProperty<String?>(nil)

    var resultImage: UIImage {
        return model.resultImage
    }
}
