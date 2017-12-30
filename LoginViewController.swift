//
//  LoginViewController.swift
//  Swiffshot
//
//  Created by Dmitry Kuklin on 28.12.16.
//  Copyright © 2016 Dmitry Kuklin. All rights reserved.
//

import UIKit

class LoginViewController: AuthorizationViewController {
    
    @IBOutlet weak var nameTxt: UITextField!
    @IBOutlet weak var passwordTxt: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var viaPhoneBtn: UIButton!
    @IBOutlet weak var viaEmailBtn: UIButton!
    @IBOutlet weak var alertViewBody: UIView!
    @IBOutlet var errorText: UILabel!
    
    var userModel = ProfileModel()
    
    //MARK: - SYSTEMS METHODS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setEnabledButton()
        nameTxt.delegate = self
        nameTxt.autocorrectionType = .no
        nameTxt.autocapitalizationType = .none
        nameTxt.spellCheckingType = .no
        nameTxt.keyboardType = .emailAddress
        passwordTxt.delegate = self
        passwordTxt.isSecureTextEntry = true
        passwordTxt.autocorrectionType = .no
        passwordTxt.autocapitalizationType = .none
        passwordTxt.spellCheckingType = .no
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        visualEffects()
        loginBtn.layer.cornerRadius = 10
    }
    
    //MARK: - VISUAL EFFECTS
    
    fileprivate func visualEffects(){
        alertViewBody.layer.cornerRadius = 10
        alertViewBody.layer.borderWidth = 1.0
        alertViewBody.layer.borderColor = UIColor.lightGray.cgColor
        
        viaPhoneBtn.layer.cornerRadius = 10
        viaPhoneBtn.layer.borderWidth = 1.0
        viaPhoneBtn.layer.borderColor = UIColor(colorLiteralRed: 75.0/255.0, green: 253.0/255.0, blue: 252.0/255.0, alpha: 1.0).cgColor
        
        viaEmailBtn.layer.cornerRadius = 10
        viaEmailBtn.layer.borderWidth = 1.0
        viaEmailBtn.layer.borderColor = UIColor(colorLiteralRed: 75.0/255.0, green: 253.0/255.0, blue: 252.0/255.0, alpha: 1.0).cgColor
    }
    
    //MARK: - CHECK FOR AVALABILITY
    
    func setEnabledButton(){
        if (nameTxt.text == "" || passwordTxt.text == "") {
            loginBtn.alpha = 0.6
        } else {
            loginBtn.alpha = 1.0
        }
        loginBtn.isUserInteractionEnabled = (nameTxt.text != "" && passwordTxt.text != "")
    }
    
    //MARK: - IB ACTIONS
    @IBAction func cancelPressed(_ sender: AnyObject) {
        alertView.isHidden = true
    }
    
    @IBAction func viaEmailPressed(_ sender: AnyObject) {
        
    }
    
    @IBAction func forgetPressed(_ sender: AnyObject) {
        alertView.isHidden = false
    }
    
    @IBAction func viaPhonePressed(_ sender: AnyObject) {
    }
    
    @IBAction func loginPressed(_ sender: AnyObject) {
        SSContact.shared.login(email: nameTxt.text!, password: passwordTxt.text!) { (error) in
            if error != nil {
                if error!._code == 17011 || error!._code == 17009 {
                    self.errorText.text = "Invalid email or password"
                    self.errorText.sizeToFit()
                    self.errorText.isHidden = false
                } else {
                    self.errorText.text = error!.localizedDescription
                    self.errorText.sizeToFit()
                    self.errorText.isHidden = false
                }
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension LoginViewController{
    func textFieldDidEndEditing(_ textField: UITextField) {
        if nameTxt.text!.isEmail && passwordTxt.text! != "" {
            setEnabledButton()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

