//
//  DetailViewController.swift
//  TextDetection-Vision-MLKit
//
//  Created by Matthias Wagner on 17.05.18.
//  Copyright © 2018 Matthias Wagner. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lastBoxRectImageView: UIImageView!
    
    var image: UIImage?
    var boxRect: CGRect?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let image = image, let fixedImage = image.fixOrientation() else { return }

        imageView.image = fixedImage

        guard let boxRect = boxRect else { return }

        let detectedBox = boxRect.convertFromAVtoUIKit().resizeTo(imageView.frame)

        let boxOutline = CALayer()
        boxOutline.frame = detectedBox
        boxOutline.borderWidth = 2.0
        boxOutline.borderColor = UIColor.blue.cgColor
        imageView.layer.addSublayer(boxOutline)

        let imageBox = boxRect.convertFromAVtoUIKit().resizeTo(fixedImage)
        let croppedImage = fixedImage.cgImage?.cropping(to: imageBox)
        lastBoxRectImageView.image = UIImage(cgImage: croppedImage!)
    }
}
