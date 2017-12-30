//
//  ExpandedViewController.swift
//  Swiffshot
//
//  Created by Dmitry Kuklin on 30.11.16.
//  Copyright © 2016 Dmitry Kuklin. All rights reserved.
//

import UIKit
import Firebase

class ExpandedViewController: UIViewController {

    @IBOutlet weak var editFriendBtn: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addGroupBtn: UIButton!
    @IBOutlet weak var addFriendBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var profileBtn: UIButton!
    
    var titleLbl: String?
    let storageRef = FIRStorage.storage().reference()
    let data = Data()
    
    //MARK: - SYSTEMS METHODS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
  
    
    override func viewDidLayoutSubviews() {
        editFriendBtn.layer.cornerRadius = 5.0
        editFriendBtn.layer.borderWidth = 1.0
        editFriendBtn.layer.borderColor = UIColor.lightGray.cgColor
        editFriendBtn.isHidden = true
        addGroupBtn.isHidden = true
        addGroupBtn.layer.cornerRadius = 5.0
        addGroupBtn.layer.borderWidth = 1.0
        addGroupBtn.layer.borderColor = UIColor.lightGray.cgColor
        addFriendBtn.layer.cornerRadius = 5.0
        addFriendBtn.layer.borderWidth = 1.0
        addFriendBtn.layer.borderColor = UIColor.lightGray.cgColor
        collectionView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    //MARK: - IB ACTIONS
    
    @IBAction func editBtnPressed(_ sender: AnyObject) {
//        navigationController?.isNavigationBarHidden = true
//        setEditing(true, animated: true)
    }
    
    @IBAction func backBtnPressed(_ sender: AnyObject) {
        navigationController?.isNavigationBarHidden = false
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addGroupBtnPressed(_ sender: AnyObject) {
        
    }
    
    @IBAction func addFriendBtnPressed(_ sender: AnyObject) {
        performSegue(withIdentifier: "addFriend", sender: self)
    }
    
    func search(_ sender: AnyObject) {
        
    }
    
    func done(_ sender: AnyObject) {
        
    }

    @IBAction func profilePressed(_ sender: AnyObject) {
        
    }
    
}

extension ExpandedViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
//        let longPress = UILongPressGestureRecognizer(target: LargeCell.self, action: #selector(editFriend))
//        longPress.minimumPressDuration = 1.0
//        collectionView.addGestureRecognizer(longPress)
        
        return CGSize(width: 100, height: 120)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "friendCell", for: indexPath) as! LargeCell
        let friend = SSContact.current.friends[indexPath.row]
        cell.isUserInteractionEnabled = false
        cell.username.text = friend.username
        cell.avatar.image = friend.avatar
        cell.round()
        return cell
    }
    
//    func editFriend() {
//        collectionView?.allowsMultipleSelection = isEditing
//        var deletedItems:[LargeCell] = []
//        delete(deletedItems)
//    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return SSContact.current.friends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let alert = UIAlertController(title: "Remove Friend?", message: nil, preferredStyle: .alert)
        let removeFriend = UIAlertAction(title: "OK", style: .destructive) { (UIAlertAction) in
            SSContact.current.friends.remove(at: indexPath.row)
            collectionView.deleteItems(at: [indexPath])
           // collectionView.reloadData()
        }
        let defaultAlert = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(removeFriend)
        alert.addAction(defaultAlert)
        present(alert, animated: true, completion: nil)
    }
}

class LargeCell: UICollectionViewCell {
    @IBOutlet var avatar: UIImageView!
    @IBOutlet var username: UILabel!
    @IBOutlet var isPrivate: UILabel!
    
    func round() {
        self.isUserInteractionEnabled = true
        username.sizeThatFits(username.frame.size)
        avatar.layer.cornerRadius = avatar.frame.width / 2
        avatar.layer.masksToBounds = true
        if username.text == "Swiffshot" {
            self.isUserInteractionEnabled = false
        }
    }
}
