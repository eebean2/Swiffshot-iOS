//
//  UsernameSelection.swift
//  Swiffshot
//
//  Created by Erik Bean on 4/26/17.
//  Copyright © 2017 Swiffshot. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class UsernameSelection: UIViewController, UITextFieldDelegate {

    @IBOutlet var username: UITextField!
    @IBOutlet var warning: UILabel!
    @IBOutlet var select: UIButton!
    private var names: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didEndEditing)))
        let aData = ActivityData(size: CGSize(width: 50, height: 50), message: "Retriving Current Users...", type: .ballScaleRippleMultiple)
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(aData)
        SSServer().get { (names) in
            self.names.append(contentsOf: names)
            NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    func didEndEditing(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func didUpdateUsername(_ sender: UITextField) {
        if names.contains(sender.text!) {
            warning.isHidden = false
            select.isEnabled = false
        } else {
            warning.isHidden = true
            select.isEnabled = true
        }
    }

    @IBAction func didSelectUsername(_ sender: UIButton) {
        SSContact.current.username = username.text!
        SSServer().update(username: username.text!)
        _ = navigationController?.popViewController(animated: true)
    }

}
