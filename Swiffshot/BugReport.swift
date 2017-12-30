//
//  BugReport.swift
//  Swiffshot
//
//  Created by Erik Bean on 5/8/17.
//  Copyright © 2017 Swiffshot. All rights reserved.
//

import UIKit

class BugReport: UIViewController {

    let username = SSContact.current.username
    var user = "No ID"
    var push = "No ID"

    @IBOutlet var userID: UILabel!
    @IBOutlet var pushID: UILabel!
    @IBOutlet var version: UILabel!
    @IBOutlet var text: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        text.layer.borderColor = UIColor.lightGray.cgColor
        text.layer.borderWidth = 1
        if SSContact.current.userID != nil {
            userID.text = SSContact.current.userID
            user = SSContact.current.userID!
        } else {
            userID.text = user
        }
        if SSContact.current.pushID != "" {
            pushID.text = SSContact.current.pushID
            push = SSContact.current.pushID
        } else {
            pushID.text = push
        }
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sendReport(_ sender: UIButton) {
        let report: [AnyHashable : Any] = ["username" : username,
                                           "userID" : user,
                                           "pushID" : push,
                                           "complaint" : text.text]
        SSServer().send(bug: report) { (error) in
            if error != nil {
                let alert = UIAlertController(title: "Oh No!", message: "We could not submit your bug report. \(error!)", preferredStyle: .alert)
                let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func sendDiagnostic(_ sender: UIButton) {
        let report: [AnyHashable : Any] = ["username" : username,
                                           "userID" : user,
                                           "pushID" : push]
        SSServer().send(bug: report) { (error) in
            if error != nil {
                let alert = UIAlertController(title: "Oh No!", message: "We could not submit your bug report. \(error!)", preferredStyle: .alert)
                let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}
