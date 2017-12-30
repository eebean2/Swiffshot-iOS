//
//  SSContact.swift
//  Swiffshot
//
//  Created by Erik Bean on 2/14/17.
//  Copyright © 2017 Dmitry Kuklin. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation
import OneSignal

// Rebuilt the Contact model to take advantage of Swift 3 and be compliant with
// what information we are allowed to keep/track. This also helps monitor Firebase
// methods such as login/logout/new user

class SSContact {
    static let current = SSContact()
    private init() {}
    var ref = FIRDatabase.database().reference()
    var storage = FIRStorage.storage().reference()
    let userID = FIRAuth.auth()?.currentUser?.uid
    var user: FIRUser?
    var active: Bool {
        get { return UserDefaults.standard.bool(forKey: "active") }
        set (newActive) { UserDefaults.standard.set(newActive, forKey: "active") }
    }
    var isFacebook: Bool {
        get { return UserDefaults.standard.bool(forKey: "facebook") }
        set (facebook) { UserDefaults.standard.set(facebook, forKey: "facebook") }
    }
    var pushID: String = ""
    var first: String = ""
    var last: String = ""
    var username: String = ""
    var email: String = ""
    var avatar: UIImage = #imageLiteral(resourceName: "Logo")
    var isVerified = false
    
    var streamTo: [SSContact] = []
    var publicEnabled = true
    var friends: [SSContact] = []
    var groups: [String: [SSContact]] = [:]
    
    init(_ username: String) {
        self.username = username
    }
    
    func login(email: String, password: String, completion: @escaping (Error?) -> ()) {
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            self.user = user
            self.email = email
            if error == nil {
                self.active = true
            }
            completion(error)
        })
    }
    
    func newUser(email: String, password: String, completion: @escaping (Error?) -> ()) {
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
            self.user = user
            self.email = email
            if error == nil {
                self.active = true
                completion(nil)
            } else {
                completion(error)
            }
        })
    }
    
    func logout(completion: @escaping (Error?) -> Void) {
        do {
            try FIRAuth.auth()?.signOut()
            self.user = nil
            self.active = false
            completion(nil)
        } catch let error {
            completion(error)
        }
    }
    
    func save(_ contact: SSContact, completion: @escaping (Error?) -> Void) {
        let userID = FIRAuth.auth()?.currentUser?.uid
        let update: [AnyHashable : Any] = ["first" : first,
                      "last" : last,
                      "username" : username,
                      "friends" : getContactJSON(),
                      "pushkey" : pushID]
        ref.child("users").child(userID!).updateChildValues(update) { (error, _) in
            completion(error)
        }
    }
    
    func save(completion: @escaping (Error?) -> Void) {
        let userID = FIRAuth.auth()?.currentUser?.uid
        let update: [AnyHashable : Any] = ["first" : first,
                                           "last" : last,
                                           "username" : username,
                                           "friends" : getContactJSON(),
                                           "pushkey" : pushID]
        ref.child("users").child(userID!).updateChildValues(update) { (error, _) in
            completion(error)
        }
    }
    
    func save(_ image: Data, completion: ((Error?) -> Void)?) {
        let imageRef = storage.child("profilePictures/\(username).png")
        imageRef.put(image, metadata: nil) { (_, error) in
            if error == nil {
                self.avatar = UIImage(data: image)!
            }
            completion?(error)
        }
    }
    
    func uploadPreview(_ image: Data, completion: @escaping ((Error?) -> Void)) {
        let imgRef = storage.child("previews/\(username).png")
        imgRef.put(image, metadata: nil) { (_, error) in
            completion(error)
        }
    }
    
    var url: URL!
    func getPreview(_ username: String, completion: @escaping (UIImage?, Error?) -> Void) {
        url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(username).png")
        let image = storage.child("previews/\(username).png")
        image.write(toFile: url) { (imgURL, error) in
            if error != nil {
                completion(nil, error)
            } else {
                completion(UIImage(contentsOfFile: imgURL!.path), error)
            }
        }
    }
    
    func deletePreview() {
        let imgRef = storage.child("previews/\(username).png")
        imgRef.delete { (error) in
            print("Could not delete preview")
        }
    }
    
    func deleteLocalPreview() {
        do {
            try FileManager.default.removeItem(at: url)
        } catch let error {
            print("Could not delete local file")
            print(error.localizedDescription)
        }
    }
    
    func loadPreview(completion: @escaping (UIImage?, Error?) -> Void) {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(username).png")
        let image = storage.child("profilePictures/\(username).png")
        image.write(toFile: url) { (imgURL, error) in
            if error != nil {
                completion(nil, error)
            } else {
                completion(UIImage(contentsOfFile: imgURL!.path), error)
            }
        }
    }
    
    func propertyCheck(_ view: UIViewController, _ check: String = "FIRST") {
        
        switch check {
        case "FIRST":
            let alert = UIAlertController(title: "Oh No!", message: "We need some updated information, please enter your first name!", preferredStyle: .alert)
            if first == "" {
                let save = UIAlertAction(title: "Save", style: .default, handler: { action -> Void in
                    self.first = alert.textFields![0].text!
                    self.propertyCheck(view, "LAST")
                })
                alert.addTextField { (textField : UITextField!) -> Void in
                    textField.placeholder = "First Name"
                }
                alert.addAction(save)
                view.present(alert, animated: true, completion: nil)
            }
        case "LAST":
            let alert = UIAlertController(title: "Oh No!", message: "We need some updated information, please enter your last name!", preferredStyle: .alert)
            if last == "" {
                let save = UIAlertAction(title: "Save", style: .default, handler: { action -> Void in
                    self.last = alert.textFields![0].text!
                    self.propertyCheck(view, "USERNAME")
                })
                alert.addTextField { (textField : UITextField!) -> Void in
                    textField.placeholder = "Last Name"
                }
                alert.addAction(save)
                view.present(alert, animated: true, completion: nil)
            }
        case "USERNAME":
            let alert = UIAlertController(title: "Oh No!", message: "We need some updated information, please enter your desired username (no @ symbol please)!", preferredStyle: .alert)
            if username == "" {
                let save = UIAlertAction(title: "Save", style: .default, handler: { action -> Void in
                    self.username = alert.textFields![0].text!
                    self.save(self, completion: { (error) in
                        if error != nil {
                            print(error!.localizedDescription)
                        }
                    })
                })
                alert.addTextField { (textField : UITextField!) -> Void in
                    textField.placeholder = "Userame"
                }
                alert.addAction(save)
                view.present(alert, animated: true, completion: nil)
            }
        default: print("Error, case unknown")
        }
    }
    
    func load(success: @escaping (Bool) -> Void) {
        let userID = FIRAuth.auth()?.currentUser?.uid
        if active {
            ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.value is NSNull {
                    success(false)
                } else {
                    if let userData = snapshot.value as? NSDictionary {
                        self.first = userData["first"] as! String
                        self.last = userData["last"] as! String
                        self.username = userData["username"] as! String
                        if userData["friends"] != nil {
                            self.friends = self.contact(from: userData["friends"] as! [[String: String]])
                        }
                        self.pushID = userData["pushkey"] as! String
                    }
                    self.checkFriends()
                    self.load(completion: { (_, error) in
                        if error != nil {
                            print("Could not load user avatar")
                            print(error!.localizedDescription)
                        }
                    })
                    success(true)
                }
            })
            if !isVerified {
                if let user = FIRAuth.auth()?.currentUser {
                    self.isVerified = user.isEmailVerified
                }
            }
        }
    }
    
    func load(completion: @escaping (UIImage?, Error?) -> Void) {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(username).png")
        let image = storage.child("profilePictures/\(username).png")
        image.write(toFile: url) { (imgURL, error) in
            if error != nil {
                completion(nil, error)
            } else {
                self.avatar = UIImage(contentsOfFile: imgURL!.path)!
                completion(UIImage(contentsOfFile: imgURL!.path), error)
            }
        }
    }
    
    func load(_ username: String, completion: @escaping (UIImage?, Error?) -> Void) {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(username).png")
        let image = storage.child("profilePictures/\(username).png")
        image.write(toFile: url) { (imgURL, error) in
            if error != nil {
                completion(nil, error)
            } else {
                completion(UIImage(contentsOfFile: imgURL!.path), error)
            }
        }
    }
    
    func getContactJSON(_ contacts: [SSContact]? = nil) -> [[String: String]] {
        var friendJSON: [[String: String]] = []
        var t = contacts
        if t == nil {
            t = friends
        }
        for friend in t! {
            var json: [String: String] = [:]
            json["first"] = friend.first
            json["last"] = friend.last
            json["username"] = friend.username
            json["pushkey"] = friend.pushID
            friendJSON.append(json)
        }
        return friendJSON
    }
    
    func contact(from JSON: [[String: String]]) -> [SSContact] {
        var friends: [SSContact] = []
        for friend in JSON {
            let contact = SSContact(friend["username"]!)
            contact.first = friend["first"]!
            contact.last = friend["last"]!
            if friend["pushkey"] != nil {
                contact.pushID = friend["pushkey"]!
            }
            contact.load(completion: { (_, error) in
                if error != nil {
                    print("Could not load friend avatar")
                    print(error!.localizedDescription)
                }
            })
            friends.append(contact)
        }
        return friends
    }
    
    private func checkFriends() {
        var contacts: [SSContact] = []
        ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            if let userData = snapshot.value as? NSDictionary {
                for user in userData {
                    let data = user.value as! NSDictionary
                    let contact = SSContact()
                    contact.username = data["username"] as! String
                    if data["pushkey"] != nil {
                        contact.pushID = data["pushkey"] as! String
                    }
                    contacts.append(contact)
                }
            }
            for friend in self.friends {
                if let index = contacts.index(of: friend) {
                    let contact = contacts.remove(at: index)
                    if contact.pushID != "" {
                        friend.pushID = contact.pushID
                        self.friends.remove(at: self.friends.index(of: friend)!)
                        self.friends.append(friend)
                    }
                } else {
                    self.friends.remove(at: self.friends.index(of: friend)!)
                }
            }
            self.save(completion: { (error) in
                if error != nil {
                    print("Could not save friends")
                    print(error!.localizedDescription)
                }
            })
        })
    }
    
    func view(_ stream: String) {
        let views = ref.child("streaming/\(stream)").value(forKey: "views") as! Int
        ref.child("streaming/\(stream)/views").setValue(views + 1)
    }
    
    var top: [SSStream] = []
    func subscribeToTop(pulse: @escaping ([SSStream]) -> Void) {
        ref.child("streaming").observe(.value, with: { (snapshot) in
            self.top.removeAll()
            if let streams = snapshot.value as? NSDictionary {
                for stream in streams {
                    if (stream.value as! NSDictionary)["public"] != nil {
                        let newStream = SSStream()
                        if (stream.value as! NSDictionary)["public"] != nil {
                            newStream.username = stream.key as! String
                            newStream.isPublic = (stream.value as! NSDictionary)["public"] as! Bool
                            newStream.views = (stream.value as! NSDictionary)["views"] as! Int
                            if !newStream.isPublic {
                                newStream.preview = #imageLiteral(resourceName: "Private")
                                if let con = (stream.value as! NSDictionary)["contacts"] as? Array<Dictionary<String, String>> {
                                    for contact in con {
                                        let c = SSContact(contact["username"]!)
                                        c.first = contact["first"] ?? ""
                                        c.last = contact["last"] ?? ""
                                        c.pushID = contact["pushkey"] ?? ""
                                    }
                                }
                            }
                        }
                        self.top.append(newStream)
                    } else {
                        self.remove(stream.key as! String)
                    }
                }
            }
            pulse(self.top)
        })
    }
    
    func remove(_ stream: String) {
        ref.child("streaming").child(stream).removeValue()
    }
    
    func isStreaming(public isPublic: Bool, to: [SSContact]?, verification: @escaping (Error?) -> Void, live: @escaping (Bool, Int) -> Void) {
        var update: [AnyHashable : Any] = ["views" : 0,
                                           "public" : isPublic]
        if !isPublic {
            update["contacts"] = getContactJSON(to)
        }
        ref.child("streaming").child(self.username).updateChildValues(update) { (error, _) in
            verification(error)
        }
        ref.child("streaming").child(self.username).observe(.value, with: { (snapshot) in
            if let userData = snapshot.value as? NSDictionary {
                live(true, userData["views"] as! Int)
            }
        })
    }
    
    func stopStreaming() {
        ref.child("streaming").child(username).removeAllObservers()
        ref.child("streaming").child(username).removeValue()
    }
    
    func subscribeTo(stream: String) {
        ref.child("streaming").child(stream).observeSingleEvent(of: .value, with: { (snapshot) in
            if let userData = snapshot.value as? NSDictionary {
                let views = userData["views"] as! Int + 1
                self.ref.child("streaming").child(stream).child("views").setValue(views)
            }
        })
    }
    
    func unsubscribeFrom(stream: String) {
        ref.child("streaming").child(stream).observeSingleEvent(of: .value, with: { (snapshot) in
            if let userData = snapshot.value as? NSDictionary {
                let views = userData["views"] as! Int - 1
                self.ref.child("streaming").child(stream).child("views").setValue(views)
            }
        })
    }
    
    func sendStreamInvites(failedSends: @escaping ([String]) -> Void) {
        var failed: [String] = []
        var send: [String] = []
        for contact in streamTo {
            if contact.pushID == "" {
                failed.append(contact.username)
            } else {
                send.append(contact.pushID)
            }
        }
        let json: [AnyHashable: Any] = ["heading" : ["en" : "\(username) started a live video chat"],
                                        "contents" : ["en" : "Live video chat invite from \(username)"],
//                                        "buttons" : [["id" : "watch",
//                                                      "text" : "Watch",
//                                                      "icon" : "",
//                                                      "url" : "do_not_open"],
//                                                     ["id" : "decline",
//                                                      "text" : "Decline",
//                                                      "icon" : "",
//                                                      "url" : "do_not_open"]],
                                        "include_player_ids": send]
        OneSignal.postNotification(json, onSuccess: { (data) in
            print("OneSignal Notification Data:")
            print(data!)
        }) { (error) in
            if error != nil {
                print("Notification Post Failure")
                print(error!.localizedDescription)
            }
        }
        failedSends(failed)
    }
    
    func getPushToken() {
        OneSignal.idsAvailable({(pushID, _) in
            self.pushID = pushID!
            if self.active {
                self.ref.child("users").child(self.userID!).updateChildValues(["pushkey" : pushID!], withCompletionBlock: { (error, _) in
                    if error != nil {
                        print("Could not update pushID")
                        print("Error: \(error!.localizedDescription)")
                    }
                })
            }
        })
    }
    
    func updateEmail(_ email: String, completion: @escaping (Error?) -> Void) {
        FIRAuth.auth()?.currentUser?.updateEmail(email, completion: { (error) in
            if error != nil {
                self.email = email
            }
            completion(error)
        })
    }
    
    func sendVerificationCode(completion: @escaping (Error?) -> Void) {
        FIRAuth.auth()?.currentUser?.sendEmailVerification(completion: { (error) in
            completion(error)
        })
    }
    
    func checkVerification() {
        if let user = FIRAuth.auth()?.currentUser {
            isVerified = user.isEmailVerified
        }
    }
    
    func getAvatar(completion: @escaping (UIImage, Error?) -> Void) {
        if avatar == #imageLiteral(resourceName: "Logo") {
            completion(avatar, nil)
        } else {
            load(completion: { (image, error) in
                if error != nil {
                    completion(self.avatar, error)
                } else {
                    completion(image!, error)
                }
            })
        }
    }
    
    func getAvatar(_ username: String, completion: @escaping (UIImage?, Error?) -> Void) {
        load(username, completion: { (image, error) in
            if error != nil {
                completion(nil, error)
            } else {
                completion(image, error)
            }
        })
    }
}

extension SSContact: Equatable {
    
    static func ==(lhs: SSContact, rhs: SSContact) -> Bool {
        return lhs.username == rhs.username
    }
    
}

extension String {
    var isEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
}
