//
//  File.swift
//  VirtualTourist 1.0.3
//
//  Created by admin on 12/3/16.
//  Copyright © 2016 JPDaines. All rights reserved.
//

import UIKit


class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func roundCorners(){
    self.contentView.layer.cornerRadius = 2.0
    self.contentView.layer.borderWidth = 1.0
    self.contentView.layer.borderColor = UIColor.clear.cgColor
    self.contentView.layer.masksToBounds = true
    }
}
