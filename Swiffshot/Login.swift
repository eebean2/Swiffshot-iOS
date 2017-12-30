//
//  Login.swift
//  Swiffshot
//
//  Created by Erik Bean on 3/21/17.
//  Copyright © 2017 Erik Bean. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import NVActivityIndicatorView

enum LoginState {
    case title
    case signin
    case signup
    case username
    case photo
    case name
    case end
    case reset
}

class Login: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FBSDKLoginButtonDelegate, NVActivityIndicatorViewable {
    
    @IBOutlet var backButton: UIButton!
    @IBOutlet var warningText: UILabel!
    @IBOutlet var fieldOneText: UILabel!
    @IBOutlet var fieldOneField: UITextField!
    @IBOutlet var fieldOneSep: UIView!
    @IBOutlet var fieldTwoText: UILabel!
    @IBOutlet var fieldTwoField: UITextField!
    @IBOutlet var fieldTwoSep: UIView!
    @IBOutlet var forgotButton: UIButton!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var signupButton: UIButton!
    @IBOutlet var avatar: UIImageView!
    @IBOutlet var select: UIButton!
    var fbButton: FBSDKLoginButton!
    var state: LoginState = .title
    var server: SSServer!
    var user: SSContact!
    var names: [String] = []
    
    //MARK: -View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signupButton.layer.borderColor = UIColor.lightGray.cgColor
        signupButton.layer.borderWidth = 1.5
        loginButton.layer.borderColor = UIColor.lightGray.cgColor
        loginButton.layer.borderWidth = 1.5
        server = SSServer()
        user = SSContact.current
        avatar.layer.cornerRadius = avatar.frame.width / 2
        avatar.layer.masksToBounds = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didEndEditing)))
        server.get(usernames: { (names) in
            self.names = names
        })
        fbButton = FBSDKLoginButton(frame: CGRect(x: 16, y: view.frame.height - 208, width: view.frame.width - 32, height: 64))
        fbButton.delegate = self
        fbButton.layer.masksToBounds = false
        view.addSubview(fbButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if user.active {
            server = SSServer()
            server.load(success: { (success) in
                if !success {
                    self.user.active = false
                } else {
                    self.performSegue(withIdentifier: "login", sender: self)
                }
            })
        }
    }
    
    func didEndEditing(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @IBAction func signUpPressed(_ sender: UIButton) {
        state = .signup
        fade(signupButton, in: false, hide: true)
        fade(fbButton, in: false, hide: true)
        fade(fieldOneText, in: true)
        fade(fieldOneField, in: true)
        fade(fieldOneSep, in: true)
        fade(fieldTwoText, in: true)
        fade(fieldTwoField, in: true)
        fade(fieldTwoSep, in: true)
        fade(backButton, in: true)
        loginButton.setTitle("SIGN UP", for: .normal)
    }
    
    func fade(_ view: UIView, in isOut: Bool, hide: Bool = false) {
        if isOut {
            UIView.animate(withDuration: 1, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                view.isHidden = hide
                view.alpha = 1
            }, completion: { (finished: Bool) -> Void in
                view.isUserInteractionEnabled = true
            })
        } else {
            UIView.animate(withDuration: 1, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                view.alpha = 0
            }, completion: { (finished: Bool) -> Void in
                view.isUserInteractionEnabled = false
                view.isHidden = hide
            })
        }
    }
    
    @IBAction func back(_ sender: UIButton) {
        warning(state: true)
        switch state {
        case .signin:
            state = .title
            fade(fieldOneText, in: false, hide: true)
            fade(fieldOneField, in: false, hide: true)
            fieldOneField.text = ""
            fade(fieldOneSep, in: false, hide: true)
            fade(fieldTwoText, in: false, hide: true)
            fade(fieldTwoField, in: false, hide: true)
            fieldTwoField.text = ""
            fade(fieldTwoSep, in: false, hide: true)
            fade(backButton, in: false, hide: true)
            fade(forgotButton, in: false, hide: true)
            fade(signupButton, in: true)
            fade(fbButton, in: true)
        case .signup:
            state = .title
            fade(fieldOneText, in: false, hide: true)
            fade(fieldOneField, in: false, hide: true)
            fieldOneField.text = ""
            fade(fieldOneSep, in: false, hide: true)
            fade(fieldTwoText, in: false, hide: true)
            fade(fieldTwoField, in: false, hide: true)
            fieldTwoField.text = ""
            fade(fieldTwoSep, in: false, hide: true)
            fade(backButton, in: false, hide: true)
            fade(signupButton, in: true)
            fade(fbButton, in: true)
            loginButton.setTitle("LOGIN", for: .normal)
        case .reset:
            forgotButton.tag = 0
            forgotButton.setTitle("Forgot Password?", for: .normal)
            loginButton.setTitle("LOGIN", for: .normal)
            fade(fieldTwoText, in: true)
            fade(fieldTwoField, in: true)
            fade(fieldTwoSep, in: true)
            state = .signin
        case .name:
            state = .username
            UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                self.fieldOneField.alpha = 0
                self.fieldTwoField.alpha = 0
                self.fieldOneText.alpha = 0
            }, completion: { (finished: Bool) -> Void in
                self.fieldOneField.text = self.user.username
                self.fieldTwoField.text = ""
                self.fieldOneText.text = "USERNAME"
                UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                    self.fieldOneField.alpha = 1
                    self.fieldTwoField.alpha = 1
                    self.fieldOneText.alpha = 1
                })
            })
            fade(backButton, in: false, hide: true)
            fade(fieldTwoText, in: false, hide: true)
            fade(fieldTwoField, in: false, hide: true)
            fade(fieldTwoSep, in: false, hide: true)
        case .photo, .end:
            state = .name
            fieldTwoText.text = "LAST NAME"
            fieldOneText.text = "FIRST NAME"
            fieldTwoField.text = self.user.last
            fade(avatar, in: false, hide: false)
            fade(select, in: false, hide: false)
            fade(fieldOneText, in: true)
            fade(fieldOneField, in: true)
            fade(fieldOneSep, in: true)
            fade(fieldTwoField, in: true)
            fade(fieldTwoText, in: true)
            fade(fieldTwoSep, in: true)
            loginButton.setTitle("Next", for: .normal)
        default: break
        }
    }
    
    @IBAction func next(_ sender: UIButton) {
        switch state {
        case .title:
            state = .signin
            fade(signupButton, in: false, hide: true)
            fade(fbButton, in: false, hide: true)
            fade(fieldOneText, in: true)
            fade(fieldOneField, in: true)
            fade(fieldOneSep, in: true)
            fade(fieldTwoText, in: true)
            fade(fieldTwoField, in: true)
            fade(fieldTwoSep, in: true)
            fade(backButton, in: true)
            fade(forgotButton, in: true)
        case .signin:
            warning(state: true)
            if fieldOneField.text!.characters.count < 1 && fieldOneField.text!.characters.count < 1 {
                warning("Email and Password cannot be empty", state: false)
                break
            }
            let aData = ActivityData(size: CGSize(width: 50, height: 50), message: "Attempting to Log In...", type: .ballScaleRippleMultiple)
            NVActivityIndicatorPresenter.sharedInstance.startAnimating(aData)
            server.login(email: fieldOneField.text!, password: fieldTwoField.text!, completion: { (error) in
                if error != nil {
                    NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                    self.warning(error!.localizedDescription)
                } else {
                    NVActivityIndicatorPresenter.sharedInstance.setMessage("Loading Profile...")
                    self.user.active = true
                    self.fieldOneField.text = ""
                    self.fieldTwoField.text = ""
                    self.server.load(success: { (success) in
                        NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                        if success {
                            self.performSegue(withIdentifier: "login", sender: self)
                        } else {
                            let alert = UIAlertController(title: "Oh No!", message: "We failed to load your profile! Please login and try again.", preferredStyle: .alert)
                            let ok = UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                                SSContact.current.logout(completion: { (error) in
                                    self.dismiss(animated: true, completion: nil)
                                })
                            })
                            alert.addAction(ok)
                            self.present(alert, animated: true)
                        }
                    })
                    
                }
            })
        case .signup:
            warning(state: true)
            if fieldOneField.text!.characters.count < 1 && fieldOneField.text!.characters.count < 1 {
                warning("Email and Password cannot be empty", state: false)
                break
            }
            let aData = ActivityData(size: CGSize(width: 50, height: 50), message: "Attempting to Sign Up...", type: .ballScaleRippleMultiple)
            NVActivityIndicatorPresenter.sharedInstance.startAnimating(aData)
            server.signup(email: fieldOneField.text!, password: fieldTwoField.text!, completion: { (error) in
                NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                if error != nil {
                    self.warning(error!.localizedDescription)
                } else {
                    sender.setTitle("Next", for: .normal)
                    sender.isEnabled = false
                    self.fieldOneField.keyboardType = .default
                    self.fieldTwoField.isSecureTextEntry = false
                    self.state = .username
                    UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                        self.fieldOneText.alpha = 0
                        self.fieldOneField.alpha = 0
                    }, completion: { (finished: Bool) -> Void in
                        self.fieldOneText.text = "USERNAME"
                        self.fieldOneField.text = self.user.username
                        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                            self.fieldOneText.alpha = 1
                            self.fieldOneField.alpha = 1
                        })
                    })
                    self.fade(self.fieldTwoText, in: false, hide: true)
                    self.fade(self.fieldTwoField, in: false, hide: true)
                    self.fade(self.fieldTwoSep, in: false, hide: true)
                    self.fade(self.backButton, in: false, hide: true)
                    self.fieldTwoField.text = ""
                    self.fbButton.removeFromSuperview()
                    self.fbButton = nil
                }
            })
        case .username:
            warning(state: true)
            if fieldOneField.text!.characters.count < 1 {
                warning("Username cannot be empty", state: false)
                break
            }
            user.username = fieldOneField.text!
            state = .name
            fieldTwoText.text = "LAST NAME"
            fieldTwoField.text = self.user.last
            fieldOneField.autocapitalizationType = .words
            fieldTwoField.autocapitalizationType = .words
            UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                self.fieldOneText.alpha = 0
                self.fieldOneField.alpha = 0
            }, completion: { (finished: Bool) -> Void in
                self.fieldOneText.text = "FIRST NAME"
                self.fieldOneField.text = self.user.first
                UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                    self.fieldOneText.alpha = 1
                    self.fieldOneField.alpha = 1
                })
            })
            fade(fieldTwoText, in: true)
            fade(fieldTwoField, in: true)
            fade(fieldTwoSep, in: true)
            fade(backButton, in: true)
        case .name:
            warning(state: true)
            fieldOneField.keyboardType = .decimalPad
            fieldOneField.autocapitalizationType = .none
            fieldTwoField.autocapitalizationType = .none
            user.first = fieldOneField.text!
            user.last = fieldTwoField.text!
            state = .photo
            fade(fieldOneText, in: false, hide: true)
            fade(fieldOneField, in: false, hide: true)
            fade(fieldOneSep, in: false, hide: true)
            fade(fieldTwoText, in: false, hide: true)
            fade(fieldTwoField, in: false, hide: true)
            fade(fieldTwoSep, in: false, hide: true)
            avatar.image = user.avatar
            fade(avatar, in: true)
            fade(select, in: true)
            sender.setTitle("Skip", for: .normal)
        case .photo:
            warning(state: true)
            state = .end
            sender.setTitle("Finish", for: .normal)
        case .end:
            warning(state: true)
            server.save(completion: { (error) in
                if error != nil {
                    self.warning(error!.localizedDescription, state: false)
                } else {
                    self.user.active = true
                    self.performSegue(withIdentifier: "login", sender: self)
                }
            })
        case .reset:
            warning(state: true)
            let aData = ActivityData(size: CGSize(width: 50, height: 50), message: "Sending Reset Email...", type: .ballScaleRippleMultiple)
            NVActivityIndicatorPresenter.sharedInstance.startAnimating(aData)
            server.forgotPass(email: fieldOneField.text!, completion: { (error) in
                NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                if error != nil {
                    self.warning(error!.localizedDescription, state: false)
                }
            })
        }
    }
    
    func warning(_ text: String? = nil, state: Bool = false) {
        if !state {
            UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                self.warningText.alpha = 0
            }, completion: { (finished: Bool) -> Void in
                self.warningText.textColor = UIColor(red: 223/255, green: 39/255, blue: 50/255, alpha: 1.0)
                self.warningText.text = text
                UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                    self.warningText.alpha = 1
                })
            })
        } else {
            if warningText.text != "Sign up to share live and fun moments with your friends" {
                UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                    self.warningText.alpha = 0
                }, completion: { (finished: Bool) -> Void in
                    self.warningText.textColor = .white
                    self.warningText.text = "Sign up to share live and fun moments with your friends"
                    UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                        self.warningText.alpha = 1
                    })
                })
            }
        }
    }
    
    func pickerChanged(_ sender: UIDatePicker) {
        let format = DateFormatter()
        format.dateStyle = .medium
        format.timeStyle = .none
        fieldOneField.text = format.string(from: sender.date)
    }
    
    @IBAction func selectImage(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func checkText(_ sender: UITextField) {
        switch state {
        case .username:
            let username = sender.text!
            if username == "" {
                loginButton.isEnabled = false
                warning(state: true)
            } else if names.contains(username) {
                loginButton.isEnabled = false
                warning("That username is already in use!")
            } else {
                loginButton.isEnabled = true
                warning(state: true)
            }
        default:
            let text = sender.text!
            if text == "" {
                loginButton.isEnabled = false
            } else {
                loginButton.isEnabled = true
            }
        }
    }
    
    @IBAction func forgotPassword(_ sender: UIButton) {
        if sender.tag == 0 {
            sender.tag = 1
            UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                sender.alpha = 0
            }, completion: { (finished: Bool) -> Void in
                sender.setTitle("Cancel", for: .normal)
                UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                    sender.alpha = 1
                })
            })
            loginButton.setTitle("Send Recovery Email", for: .normal)
            fade(fieldTwoText, in: false, hide: true)
            fade(fieldTwoField, in: false, hide: true)
            fade(fieldTwoSep, in: false, hide: true)
            state = .reset
        } else if sender.tag == 1 {
            sender.tag = 0
            UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                sender.alpha = 0
            }, completion: { (finished: Bool) -> Void in
                sender.setTitle("Forgot Password?", for: .normal)
                UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                    sender.alpha = 1
                })
            })
            loginButton.setTitle("LOGIN", for: .normal)
            fade(fieldTwoText, in: true)
            fade(fieldTwoField, in: true)
            fade(fieldTwoSep, in: true)
            state = .signin
        }
    }
    
    //MARK: -Text Field Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: -Image Methods
    
    func error(_ error: Error) {
        let alert = UIAlertController(title: "Oh No!", message: "We couldn't save your image! Error: \(error.localizedDescription)", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: -Image Picker Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let aData = ActivityData(size: CGSize(width: 50, height: 50), message: "Saving Avatar...", type: .ballScaleRippleMultiple)
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(aData)
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            server.save(UIImagePNGRepresentation(image)!, completion: { (error) in
                NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                if error != nil {
                    self.error(error!)
                } else {
                    self.avatar.image = image
                    self.user.avatar = image
                    self.state = .end
                    self.loginButton.setTitle("Finish", for: .normal)
                }
            })
        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            server.save(UIImagePNGRepresentation(image)!, completion: { (error) in
                NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                if error != nil {
                    self.error(error!)
                } else {
                    self.avatar.image = image
                    self.user.avatar = image
                    self.state = .end
                    self.loginButton.setTitle("Finish", for: .normal)
                }
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: -FB Delegate
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        server.signout(success: { (success) in
            if success {
                SSContact.current.active = false
            }
        })
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        let aData = ActivityData(size: CGSize(width: 50, height: 50), message: "Logging In via Facebook...", type: .ballScaleRippleMultiple)
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(aData)
        if error != nil {
            NVActivityIndicatorPresenter.sharedInstance.setMessage("Error")
            print("Facebook Auth Error :: Error: \(error.localizedDescription)")
            NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
        } else {
            SSContact.current.isFacebook = true
            guard let accessToken = FBSDKAccessToken.current() else {
                print("No Access Token")
                NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                return
            }
            let credential = server.getCredential(accessToken: accessToken.tokenString)
            NVActivityIndicatorPresenter.sharedInstance.setMessage("Accessing User Data...")
            server.login(credential: credential, completion: { (error) in
                if error != nil {
                    print(error!.localizedDescription)
                    let alert = UIAlertController(title: "Could not sign in", message: nil, preferredStyle: .alert)
                    let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    NVActivityIndicatorPresenter.sharedInstance.setMessage("Checking for Profile...")
                    self.user.active = true
                    self.server.load(success: { (success) in
                        NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                        if success {
                            self.user.active = true
                            self.performSegue(withIdentifier: "login", sender: self)
                        } else {
                            self.loginButton.setTitle("Next", for: .normal)
                            self.loginButton.isEnabled = false
                            self.fieldOneField.keyboardType = .default
                            self.fieldTwoField.isSecureTextEntry = false
                            self.state = .username
                            self.fieldOneText.text = "USERNAME"
                            self.fieldOneField.text = self.user.username
                            self.fade(self.fieldOneText, in: true)
                            self.fade(self.fieldOneField, in: true)
                            self.fade(self.fieldOneSep, in: true)
                            self.fade(self.backButton, in: false, hide: true)
                        }
                    })
                }
            })
        }
    }
}
