//
//  LatestStreamCollectionViewCell.swift
//  Swiffshot
//
//  Created by Dmitry Kuklin on 24.11.16.
//  Copyright © 2016 Dmitry Kuklin. All rights reserved.
//

import UIKit

class LatestStreamCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var onlineStreamIndicatorView: UIView!
    @IBOutlet weak var avatarImg: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    
    var isOnlineCell = false
    
    func fillCell(_ isOnline: Bool) {
        nameLbl.text = "@\(SSContact.shared.username)"
        isOnlineCell = isOnline
        onlineStreamIndicatorView.layer.cornerRadius = 50
        onlineStreamIndicatorView.isHidden = !isOnline
        avatarImg.image = UIImage(named: "avatar_\(arc4random_uniform(10) + 1)")
    }
}
