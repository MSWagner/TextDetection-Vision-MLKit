//
//  VisionResultListViewModel.swift
//  TextDetection-Vision-MLKit
//
//  Created by Matthias Wagner on 22.05.18.
//  Copyright © 2018 Matthias Wagner. All rights reserved.
//

import Foundation
import ReactiveSwift
import PKHUD

class VisionResultListViewModel {

    private let _visionResultViewModels = MutableProperty<[VisionResultViewModel]>([])
    lazy var visionResultViewModels: Property<[VisionResultViewModel]> = {
        return Property(self._visionResultViewModels)
    }()

    init(visionResults: [VisionResult]) {
        DispatchQueue.global().async {
            let visionResultViewModels = visionResults.map { VisionResultViewModel.init(model: $0) }

            DispatchQueue.main.async {
                self._visionResultViewModels.value = visionResultViewModels
                HUD.flash(.success, delay: 0.4)
            }

            SignalProducer
                .combineLatest(MLKitController.shared.detectionSignalProducers)
                .startWithCompleted {
                    MLKitController.shared.detectionSignalProducers.removeAll()
            }
        }
    }
}
