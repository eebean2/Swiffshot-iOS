//
//  SSServer.swift
//  Swiffshot
//
//  Created by Erik Bean on 3/21/17.
//  Copyright © 2017 Erik Bean. All rights reserved.
//

import Foundation
import Firebase

class SSServer {
    let ref = FIRDatabase.database().reference()
    let storage = FIRStorage.storage().reference()
    let user = SSContact.current
    
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
                                        newStream.visableTo.append(c)
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
    
    var feat: [SSStream] = []
    func subscribeToFeatured(pulse: @escaping ([SSStream]) -> Void) {
        ref.child("featured").observe(.value, with: { (snapshot) in
            self.feat.removeAll()
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
                            }
                        }
                        self.feat.append(newStream)
                    } else {
                        self.removeFeatured(stream.key as! String)
                    }
                }
            }
            pulse(self.feat)
        })
    }
    
    private func remove(_ stream: String) {
        ref.child("streaming").child(stream).removeValue()
    }
    
    private func removeFeatured(_ stream: String) {
        ref.child("featured").child(stream).removeValue()
    }
    
    func login(credential: FIRAuthCredential, completion: @escaping (Error?) -> Void) {
        FIRAuth.auth()?.signIn(with: credential, completion: { (_, error) in
            if error == nil {
                SSContact.current.active = true
            }
            completion(error)
        })
    }
    
    func login(email: String, password: String, completion: @escaping (Error?) -> Void) {
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (_, error) in
            if error == nil {
                SSContact.current.active = true
            }
            completion(error)
        })
    }
    
    func signup(email: String, password: String, completion: @escaping (Error?) -> Void) {
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (_, error) in
            if error == nil {
                SSContact.current.active = true
            }
            completion(error)
        })
    }
    
    func get(usernames: @escaping ([String]) -> Void) {
        ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            var users: [String] = []
            if let userData = snapshot.value as? NSDictionary {
                for user in userData {
                    users.append((user.value as! NSDictionary)["username"] as! String)
                }
            }
            usernames(users)
        })
    }
    
    func save(_ image: Data, completion: @escaping (Error?) -> Void) {
        let imageRef = storage.child("profilePictures/\(SSContact.current.username).png")
        imageRef.put(image, metadata: nil) { (_, error) in
            if error == nil {
                SSContact.current.avatar = UIImage(data: image)!
            }
            completion(error)
        }
    }
    
    func forgotPass(email: String, completion: @escaping (Error?) -> Void) {
        FIRAuth.auth()?.sendPasswordReset(withEmail: email, completion: { (error) in
            completion(error)
        })
    }
    
    func signout(success: (Bool) -> Void) {
        do {
            try FIRAuth.auth()?.signOut()
            success(true)
        } catch let error {
            print(error.localizedDescription)
            success(false)
        }
    }
    
    func getCredential(accessToken: String) -> FIRAuthCredential {
        return FIRFacebookAuthProvider.credential(withAccessToken: accessToken)
    }
    
    func load(success: @escaping (Bool) -> Void) {
        let userID = FIRAuth.auth()?.currentUser?.uid
        if user.active {
            ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.value is NSNull {
                    success(false)
                } else {
                    if let userData = snapshot.value as? NSDictionary {
                        self.user.first = userData["first"] as! String
                        self.user.last = userData["last"] as! String
                        self.user.username = userData["username"] as! String
                        if userData["friends"] != nil {
                            self.user.friends = self.user.contact(from: userData["friends"] as! [[String: String]])
                        }
                        self.user.pushID = userData["pushkey"] as! String
                    }
                    self.checkFriends()
// AVATARS
//                    self.load(completion: { (_, error) in
//                        if error != nil {
//                            print("Could not load user avatar")
//                            print(error!.localizedDescription)
//                        }
//                    })
                    SSContact.current.getPushToken()
                    success(true)
                }
            })
            if !user.isVerified {
                if let local = FIRAuth.auth()?.currentUser {
                    user.isVerified = local.isEmailVerified
                }
            }
        }
    }
    
    private func checkFriends() {
        var contacts: [SSContact] = []
        ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            if let userData = snapshot.value as? NSDictionary {
                for user in userData {
                    let data = user.value as! NSDictionary
                    let contact = SSContact(data["username"] as! String)
                    if data["pushkey"] != nil {
                        contact.pushID = data["pushkey"] as! String
                    }
                    contacts.append(contact)
                }
            }
            for friend in self.user.friends {
                if let index = contacts.index(of: friend) {
                    let contact = contacts.remove(at: index)
                    if contact.pushID != "" {
                        friend.pushID = contact.pushID
                        self.user.friends.remove(at: self.user.friends.index(of: friend)!)
                        self.user.friends.append(friend)
                    }
                } else {
                    self.user.friends.remove(at: self.user.friends.index(of: friend)!)
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
    
    func save(completion: @escaping (Error?) -> Void) {
        let userID = FIRAuth.auth()?.currentUser?.uid
        let update: [AnyHashable : Any] = ["first" : user.first,
                                           "last" : user.last,
                                           "username" : user.username,
                                           "friends" : user.getContactJSON(),
                                           "pushkey" : user.pushID]
        ref.child("users").child(userID!).updateChildValues(update) { (error, _) in
            completion(error)
        }
    }
    
    func subscribeTo(chat: String, update: @escaping (Array<String>) -> Void) {
        ref.child("streaming").child(chat).child("messages").observe(.value, with: { (snapshot) in
            if let chatData = snapshot.value as? Array<String> {
                update(chatData)
            }
        })
    }
    
    func unsubscribeFrom(chat: String) {
        ref.child("streaming").child(chat).child("messages").removeAllObservers()
    }
    
    func update(chat: String, messages: [String], completion: @escaping (Error?) -> Void) {
        ref.child("streaming").child(chat).updateChildValues(["messages": messages]) { (error, _) in
            completion(error)
        }
    }
    
    func submit(report: [AnyHashable: Any], completion: @escaping (Error?) -> Void) {
        ref.child("reported").childByAutoId().updateChildValues(report) { (error, _) in
            completion(error)
        }
    }
    
    func update(username: String) {
        let userID = FIRAuth.auth()?.currentUser?.uid
        ref.child("users").child(userID!).child("username").setValue(username)
    }
    
    func getVersion(completion: @escaping (String) -> Void) {
        ref.child("version").observeSingleEvent(of: .value, with: { (snapshot) in
            if let version = snapshot.value as? String {
                completion(version)
            }
        })
    }
    
    func send(bug: [AnyHashable: Any], completion: @escaping (Error?) -> Void) {
        ref.child("bug").childByAutoId().updateChildValues(bug) { (error, _) in
            completion(error)
        }
    }}
