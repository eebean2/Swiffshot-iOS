//
//  Friends.swift
//  Swiffshot
//
//  Created by Erik Bean on 2/16/17.
//  Copyright © 2017 Dmitry Kuklin. All rights reserved.
//

import UIKit
import Firebase

class SSFriends: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var search: UISearchBar!
    var users: [SSContact] = []
    let ref = FIRDatabase.database().reference()
    var show: [SSContact] = []
    @IBOutlet var tableView: UITableView!
    var friends: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        for contact in SSContact.current.friends {
            friends.append(contact.username)
        }
        ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            if let userData = snapshot.value as? NSDictionary {
                for user in userData {
                    let value = user.value as! NSDictionary
                    let contact = SSContact(value["username"] as! String)
                    contact.first = value["first"] as! String
                    contact.last = value["last"] as! String
                    if value["pushkey"] != nil {
                        contact.pushID = value["pushkey"] as! String
                    }
//                    contact.load(completion: { (_, error) in
//                        if error != nil {
//                            print("Could not load image")
//                            print(error!.localizedDescription)
//                        }
//                    })
                    self.users.append(contact)
                }
            } else {
                let error = UIAlertController(title: "Cannot get users", message: "Please try again later!", preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                    self.dismiss(animated: true, completion: nil)
                })
                error.addAction(action)
                self.present(error, animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func goBack(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        tableView.reloadData()
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return show.count
    }
    var text: String = ""
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        text = searchText.lowercased()
        show.removeAll()
        for user in users {
            if user.username.contains(text) {
                if SSContact.current.username != user.username && !friends.contains(user.username) {
                    show.append(user)
                }
            }
        }
        tableView.reloadData()
    }
    
    @IBAction func search(_ sender: AnyObject) {
        show.removeAll()
        for user in users {
            if user.username.contains(text) {
                if SSContact.current.username != user.username && !friends.contains(user.username) {
                    show.append(user)
                }
            }
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        let user = show[indexPath.row]
        cell.imageView!.image = user.avatar
        cell.imageView!.layer.cornerRadius = cell.imageView!.frame.width / 2
        cell.imageView!.layer.masksToBounds = true
        cell.textLabel!.text = user.username
        cell.detailTextLabel!.text = "\(user.first) \(user.last)"

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let alert = UIAlertController(title: "Friend Added!", message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default) { (action) in
            self.users.remove(at: indexPath.row)
            SSContact.current.friends.append(self.show[indexPath.row])
            self.show.remove(at: indexPath.row)
            SSContact.current.save(SSContact.current, completion: { (error) in
                if error != nil {
                    print(error!.localizedDescription)
                }
            })
            tableView.reloadData()
        }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}
