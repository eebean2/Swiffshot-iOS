//
//  CategoryCell.swift
//  Swiffshot
//
//  Created by Dmitry Kuklin on 29.11.16.
//  Copyright © 2016 Dmitry Kuklin. All rights reserved.
//

import UIKit

protocol CategoryCellDelegate: class {
    func moveToStream(_ isonline: Bool)
    func moveToCamera()
}

class CategoryCell: UICollectionViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate{
    
    weak var delegate: CategoryCellDelegate?
    var globalIndexSection = 0
    fileprivate let cellId = "cellId"
    
    let videosCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.clear
        return collectionView
    }()
    
    func setupViews(_ globInd: Int) {
        globalIndexSection = globInd
        addSubview(videosCollectionView)
        videosCollectionView.delegate = self
        videosCollectionView.dataSource = self
        videosCollectionView.backgroundColor = UIColor.clear
        videosCollectionView.showsHorizontalScrollIndicator = false
        if globInd == 0 { videosCollectionView.isScrollEnabled = false }

        videosCollectionView.register(UINib(nibName: "LatestStreamCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "bigCell")
        videosCollectionView.register(UINib(nibName: "SmallCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "smallCell")
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": videosCollectionView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": videosCollectionView]))
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(CategoryCell.handleTap(_:)))
        tap.delegate = self
        videosCollectionView.backgroundView = UIView()
        videosCollectionView.backgroundView?.addGestureRecognizer(tap)
    }
    
    @objc fileprivate func handleTap(_ sender: UITapGestureRecognizer) {
        delegate?.moveToCamera()
    }
    
    //MARK: COLLECTION VIEW DELEGATE METHODS
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch globalIndexSection {
        case 0:
            return 6
        default:
            return 9
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = UICollectionViewCell()
        
        switch globalIndexSection {
        case 0:
            let bigcell = collectionView.dequeueReusableCell(withReuseIdentifier: "bigCell", for: indexPath) as! LatestStreamCollectionViewCell
            indexPath.row == 0 ? bigcell.fillCell(true) : bigcell.fillCell(false)
            cell = bigcell
        default:
            let smallcell = collectionView.dequeueReusableCell(withReuseIdentifier: "smallCell", for: indexPath) as! SmallCollectionViewCell
            indexPath.row == 0 ? smallcell.fillCell(true) : smallcell.fillCell(false)
            cell = smallcell
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch globalIndexSection {
        case 0:
            return CGSize(width: 100, height: 120)
        default:
            return CGSize(width: 70, height: 90)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch globalIndexSection {
        case 0:
            let spacing = (collectionView.frame.size.width/3 - 100)
            return UIEdgeInsets(top: 20, left: spacing, bottom: 20, right: spacing)
            
        default:
            return UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        var isOnline = false
        if (cell?.isKind(of: LatestStreamCollectionViewCell.self))!{
            isOnline = (cell as! LatestStreamCollectionViewCell).isOnlineCell
        } else {
            isOnline = (cell as! SmallCollectionViewCell).isOnlineCell
        }
        delegate?.moveToStream(isOnline)
    }
}
