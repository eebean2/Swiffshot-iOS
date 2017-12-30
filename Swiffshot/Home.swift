//
//  Home.swift
//  Swiffshot
//
//  Created by Erik Bean on 4/12/17.
//  Copyright © 2017 Erik Bean. All rights reserved.
//

import UIKit
import AVFoundation

class Home: UIViewController {
    
    fileprivate var featured: [SSStream] = []
    fileprivate var priv: [SSStream] = []
    fileprivate var pub: [SSStream] = []
    private var server: SSServer!
    var stream: SSStream!
    
    private var phrases: [String] = ["King Henry VIII slept with a gigantic axe beside him.", "Bananas are curved because they grow towards the sun.", "If you lift a kangaroo’s tail off the ground it can’t hop.", "A baby octopus is about the size of a flea when it is born", "Catfish are the only animals that naturally have an odd number of whiskers.", "Facebook, Skype and Twitter are all banned in China", "Bob Dylan’s real name is Robert Zimmerman", "A crocodile can’t poke its tongue out", "Sea otters hold hands when they sleep so they don’t drift away from each other.", "Swiffshot is based out of Brooklyn, New York"]
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var collectionHeight: NSLayoutConstraint!
    @IBOutlet weak var facts: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !SSContact.current.active {
            dismiss(animated: true, completion: nil)
        } else {
            let ss = UserDefaults.standard.string(forKey: "UserAccepted")
            if ss != "" && ss != nil {
                let newStream = SSStream()
                newStream.username = ss!
                stream = newStream
                UserDefaults.standard.set(nil, forKey: "UserAccepted")
                performSegue(withIdentifier: "toSubscriber", sender: self)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        server = SSServer()
        serverFunctions()
        
        if SSContact.current.username == "" {
            self.navigationController?.navigationBar.isHidden = true
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            self.performSegue(withIdentifier: "username", sender: self)
        }
        
        tableView.rowHeight = 56
        tableView.register(UINib(nibName: "HomeHeader", bundle: Bundle.main), forHeaderFooterViewReuseIdentifier: "header")
        
        changeValue()
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 22, height: 22))
        imageView.contentMode = .scaleAspectFit
        let image = UIImage(named: "swiffshotLogoFont.png")
        imageView.image = image
        navigationItem.titleView = imageView
        navigationController?.navigationBar.isTranslucent = false
        let settings = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        settings.setImage(#imageLiteral(resourceName: "Settings"), for: .normal)
        settings.addTarget(self, action: #selector(settingsPressed), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: settings)
        let friends = UIButton(frame: CGRect(x: 0, y: 0, width: 23, height: 20))
        friends.setImage(#imageLiteral(resourceName: "AllFriends"), for: .normal)
        friends.addTarget(self, action: #selector(friendsPressed), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: friends)
    }
    
    func serverFunctions() {
        server.subscribeToTop { (streams) in
            self.pub.removeAll()
            self.priv.removeAll()
            if !streams.isEmpty {
                for stream in streams {
                    if stream.isPublic {
                        self.pub.append(stream)
                        self.tableView.isHidden = false
                    } else {
                        if stream.visableTo.contains(SSContact.current) {
                            self.priv.append(stream)
                            self.tableView.isHidden = false
                        }
                    }
                }
            } else {
                self.tableView.isHidden = true
            }
            self.tableView.reloadData()
        }
        server.subscribeToFeatured { (streams) in
            self.featured.removeAll()
            if !streams.isEmpty {
                self.featured.append(contentsOf: streams)
                UIView.animate(withDuration: 0.5, animations: {
                    self.collectionHeight.constant = 197
                })
            } else {
                UIView.animate(withDuration: 0.5, animations: {
                    self.collectionHeight.constant = 0
                })
            }
            self.collectionView.reloadData()
        }
    }
    
    func settingsPressed() {
        performSegue(withIdentifier: "toSettings", sender: self)
        changeValue()
    }
    
    func friendsPressed() {
        performSegue(withIdentifier: "toFriends", sender: self)
        changeValue()
    }
    
    func changeValue() {
        facts.text = phrases[Int(arc4random_uniform(UInt32(phrases.count)))]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSubscribe" {
            let destination = segue.destination as! Sample
            destination.navigationController?.isNavigationBarHidden = true
            destination.user = stream
            let url = URL(string: "http://54.242.159.242:1935/Swiffshot/\(stream.username)/playlist.m3u8")
            let asset = AVURLAsset(url: url!)
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: nil)
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.preferredForwardBufferDuration = 5
            destination.player = AVPlayer()
            destination.player!.play()
            destination.player!.replaceCurrentItem(with: playerItem)
            playerItem.preferredForwardBufferDuration = 0
        }
    }
}

// MARK:- UITableView
extension Home: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return priv.count
        } else {
            return pub.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if priv.count == 0 {
                return 0
            } else {
                return 45
            }
        } else {
            return 45
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as! SSTableViewHeader
        if section == 0 {
            if priv.count == 0 {
                return nil
            } else {
                header.title.text = "Private"
                return header
            }
        } else {
            header.title.text = "Public"
            return header
        }
    }
    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        if section == 0 {
//            if priv.count == 0 {
//                return nil
//            } else {
//                return "Private"
//            }
//        } else {
//            if priv.count == 0 {
//                return nil
//            } else {
//                return "Public"
//            }
//        }
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuse", for: indexPath) as! SSTableViewCell
        if indexPath.section == 0 {
            cell.avatar.image = priv[indexPath.row].preview
            cell.statusCircle.layer.cornerRadius = 10
            cell.statusCircle.clipsToBounds = true
            cell.statusCircle.backgroundColor = UIColor.cyan
//          cell.live.text = "LIVE"
//          cell.live.textColor = UIColor.blue//private
            cell.username.text = priv[indexPath.row].username
        } else {
            cell.statusCircle.layer.cornerRadius = 10
            cell.statusCircle.clipsToBounds = true
            cell.statusCircle.backgroundColor = UIColor.cyan
            cell.avatar.image = pub[indexPath.row].preview
//          cell.live.text = "LIVE"
//          cell.live.textColor = UIColor.blue//public
            cell.username.text = pub[indexPath.row].username
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            stream = priv[indexPath.row]
        } else {
            stream = pub[indexPath.row]
        }
        if stream.isPublic {
            performSegue(withIdentifier: "toSubscribe", sender: self)
        } else {
            for user in stream.visableTo {
                if user == SSContact.current {
                    performSegue(withIdentifier: "toSubscribe", sender: self)
                    return
                }
            }
            let alert = UIAlertController(title: "Oh No!", message: "You are not invited to see this stream! If you know this person, please ask them to invite you.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK:- UICollectionView
extension Home: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let visible: CGFloat = 3
        let padding: CGFloat = 5
        let width = (collectionView.bounds.width / visible) - padding
        let height = (collectionView.bounds.height - (2 * padding)) / 2
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return featured.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "largeCell", for: indexPath) as! SSCollectionViewCell
        cell.avatar.image = featured[indexPath.item].preview
        cell.username.text = featured[indexPath.item].username
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        stream = featured[indexPath.item]
        performSegue(withIdentifier: "toSubscribe", sender: self)
    }
}

// MARK:- SSCollectionView Cell
class SSCollectionViewCell: UICollectionViewCell {
    @IBOutlet var avatar: UIImageView!
    @IBOutlet var username: UILabel!
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        avatar.layer.cornerRadius = avatar.frame.width / 2
        avatar.layer.masksToBounds = true
    }
}

// MARK:- SSTableView Cell
class SSTableViewCell: UITableViewCell {
    @IBOutlet var avatar: UIImageView!
    @IBOutlet var username: UILabel!
    @IBOutlet var live: UILabel!
    @IBOutlet weak var statusCircle: UIView!
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        avatar.layer.cornerRadius = avatar.frame.width / 2
        avatar.layer.masksToBounds = true
    }
}

// MARK:- SSTableView Header
class SSTableViewHeader: UITableViewHeaderFooterView {
    @IBOutlet var title: UILabel!
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .white
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
