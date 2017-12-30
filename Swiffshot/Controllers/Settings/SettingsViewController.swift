//
//  SettingsViewController.swift
//  Swiffshot
//
//  Created by Justin Hodges on 2.16.17.
//  Copyright © 2017 Justin Hodges. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit

class SettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, FBSDKLoginButtonDelegate {

    @IBOutlet var logoutButton: UIButton!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var dateOfBirthLabel: UILabel!
    @IBOutlet var realNameLabel: UILabel!
    @IBOutlet var profilePicture: UIImageView!
    @IBOutlet var email: UITextField!
    @IBOutlet var verify: UIButton!

    let storageRef = FIRStorage.storage().reference()
    let data = Data()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(backPressed), name: Notification.Name(rawValue: "UserAccepted"), object: nil)
        let settings = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        settings.setImage(#imageLiteral(resourceName: "BackBtn"), for: .normal)
        settings.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: settings)
        SSContact.current.getAvatar { (image, error) in
            if error != nil {
                print("Error retriving image")
                print(error!.localizedDescription)
            }
            self.profilePicture.image = image
        }
        profilePicture.layer.cornerRadius = profilePicture.frame.width / 2
        profilePicture.layer.masksToBounds = true
        usernameLabel.text = SSContact.current.username
        realNameLabel.text = "\(SSContact.current.first) \(SSContact.current.last)"
        email.text = SSContact.current.email
        if SSContact.current.isVerified {
            verify.isHidden = true
        }
        if SSContact.current.isFacebook {
            logoutButton.isHidden = true
            let loginButton = FBSDKLoginButton(frame: CGRect(x: 16, y: view.frame.height - 130, width: view.frame.width - 32, height: 50))
            loginButton.delegate = self
            view.addSubview(loginButton)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "UserAccepted"), object: nil)
    }

    @IBAction func uploadNewImage(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            profilePicture.contentMode = .scaleAspectFill
            profilePicture.image = image
            SSContact.current.save(UIImagePNGRepresentation(image)!, completion: { (error) in
                if error != nil {
                    print("Error saving image")
                    print(error!.localizedDescription)
                }
            })
        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            profilePicture.contentMode = .scaleAspectFill
            profilePicture.image = image
            SSContact.current.save(UIImagePNGRepresentation(image)!, completion: { (error) in
                if error != nil {
                    print("Error saving image")
                    print(error!.localizedDescription)
                }
            })
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func backPressed() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        SSContact.current.isFacebook = false
        SSContact.current.active = false
        userLogout(nil)
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        print("Should not have logged in")
    }
    
    @IBAction func updateEmail(_ sender: UIButton) {
        SSContact.current.updateEmail(email.text!) { (error) in
            if error != nil {
                let alert = UIAlertController(title: "Could not update email", message: "Error: \(error!.localizedDescription)", preferredStyle: .alert)
                let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func verifyEmail(_ sender: UIButton) {
        if email.text!.isEmail {
            SSContact.current.sendVerificationCode { (error) in
                if error != nil {
                    let alert = UIAlertController(title: "Could not verify email", message: "Error: \(error!.localizedDescription)", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: "Verification Email Sent", message: nil, preferredStyle: .alert)
                    let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            let alert = UIAlertController(title: "Invalid Email Address", message: "You must have a valid email structured such as noreply@swiffshot.com", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func userLogout(_ sender: UIButton?) {
        SSContact.current.logout { error in
            if error != nil {
                print(error!.localizedDescription)
                let alert = UIAlertController(title: "Error Logging Out!", message: nil, preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
            } else {
                _ = self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}
