//
//  VisionResultListViewController.swift
//  TextDetection-Vision-MLKit
//
//  Created by Matthias Wagner on 22.05.18.
//  Copyright © 2018 Matthias Wagner. All rights reserved.
//

import UIKit
import MBDataSource
import ReactiveSwift

class VisionResultListViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var tableView: UITableView!

    // MARK: - Properties

    var viewModel: VisionResultListViewModel!

    lazy var dataSource: DataSource = {
        return DataSource(
            cellDescriptors: [
                VisionResultOverviewCell.descriptor
                    .configure { [weak self] (newsViewModel, cell, _) in
                        cell.configure(viewModel: newsViewModel)
                    }
                    .height { 120 }
            ]
        )
    }()

    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = dataSource
        tableView.delegate = dataSource
    
        bindViewModel()
    }

    // MARK: - DataSource

    private func bindViewModel() {
        viewModel.visionResultViewModels.producer.startWithValues { [weak self] (viewModels) in
            guard let `self` = self else { return }

            self.dataSource.sections = [Section(items: viewModels)]
            self.dataSource.reloadData(self.tableView, animated: true)
        }
    }
}
