//
//  CollectionViewLayout.swift
//  VirtualTourist 1.0.3
//
//  Created by admin on 12/6/16.
//  Copyright © 2016 JPDaines. All rights reserved.
//

import Foundation
import UIKit


extension CollectionVC {
    
    
    
    func configureCell(cell: CollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        cell.contentView.layer.cornerRadius = 10.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
    }
    
}
