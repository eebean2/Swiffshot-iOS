//
//  SSStreamerProfile.swift
//  Swiffshot
//
//  Created by Erik Bean on 3/4/17.
//  Copyright © 2017 Dmitry Kuklin. All rights reserved.
//

import UIKit
import Firebase

class SSStreamerProfile: UIViewController {
    
    @IBOutlet var avatar: UIImageView!
    @IBOutlet var username: UILabel!
    var stream: String!
    let ref = FIRDatabase.database().reference()

    override func viewDidLoad() {
        super.viewDidLoad()
        username.text = stream
        avatar.layer.cornerRadius = avatar.frame.width / 2
        avatar.layer.masksToBounds = true
        SSContact.current.getAvatar(stream) { (image, error) in
            if error != nil {
                print("Error retriving image")
                print(error!.localizedDescription)
            }
            self.avatar.image = image
        }
    }
    
    @IBAction func reportPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Report Profile", message: "What are you reporting this person for?", preferredStyle: .alert)
        let pic = UIAlertAction(title: "Picture", style: .default) { (_) in
            let report: [AnyHashable: Any] = ["reportedStream" : self.stream,
                                              "reportingUser" : SSContact.current.username,
                                              "reportType" : "picture"]
            self.ref.child("reported").childByAutoId().updateChildValues(report, withCompletionBlock: { (error, _) in
                if error != nil {
                    self.error(error!)
                } else {
                    self.thankYou()
                }
            })
        }
        let username = UIAlertAction(title: "Username", style: .default) { (_) in
            let report: [AnyHashable: Any] = ["reportedStream" : self.stream,
                                              "reportingUser" : SSContact.current.username,
                                              "reportType" : "username"]
            self.ref.child("reported").childByAutoId().updateChildValues(report, withCompletionBlock: { (error, _) in
                if error != nil {
                    self.error(error!)
                } else {
                    self.thankYou()
                }
            })
        }
        let cancle = UIAlertAction(title: "Neither", style: .cancel, handler: nil)
        alert.addAction(pic)
        alert.addAction(username)
        alert.addAction(cancle)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func backPressed(_ sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    private func error(_ error: Error) {
        let alert = UIAlertController(title: "Oh No!", message: "We could not send the report! Please try again at a later time! Error: \(error.localizedDescription)", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    private func thankYou() {
        let alert = UIAlertController(title: "Thank You", message: "We thank you for your report and will review it as soon as possible", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }

}
