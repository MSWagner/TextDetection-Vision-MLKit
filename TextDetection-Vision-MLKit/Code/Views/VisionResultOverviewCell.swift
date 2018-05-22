//
//  VisionResultOverviewCell.swift
//  TextDetection-Vision-MLKit
//
//  Created by Matthias Wagner on 22.05.18.
//  Copyright © 2018 Matthias Wagner. All rights reserved.
//

import UIKit
import MBDataSource
import ReactiveSwift

class VisionResultOverviewCell: UITableViewCell {

    @IBOutlet weak var detectedImageView: UIImageView!
    @IBOutlet weak var detectedTextLabel: UILabel!

    private var viewModel: VisionResultViewModel!

    private var disposeBag = CompositeDisposable()

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        disposeBag.dispose()
        disposeBag = CompositeDisposable()
    }

    // MARK: - Configure

    func configure(viewModel: VisionResultViewModel) {
        self.viewModel = viewModel

        detectedImageView.image = viewModel.resultImage
        detectedTextLabel.text = viewModel.resultText.value

        if viewModel.resultText.value != nil { return }

        disposeBag += viewModel.resultText.producer
            .startWithValues{ [weak self] detectedText in
                self?.detectedTextLabel.text = viewModel.resultText.value
        }
    }

}

extension VisionResultOverviewCell {
    static var descriptor: CellDescriptor<VisionResultViewModel, VisionResultOverviewCell> {
        return CellDescriptor()
            .configure { (data, cell, _) in
                cell.configure(viewModel: data)
        }
    }
}
