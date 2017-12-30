//
//  SendToCell.swift
//  Swiffshot
//
//  Created by Erik Bean on 2/28/17.
//  Copyright © 2017 Dmitry Kuklin. All rights reserved.
//

import UIKit

class SendToCell: UITableViewCell {
    
    @IBOutlet var avatar: UIImageView!
    @IBOutlet var username: UILabel!
    @IBOutlet var selectButton: UIButton!
    var contact: SSContact!
    var user = SSContact.current
    var isPublic = false

    override func awakeFromNib() {
        super.awakeFromNib()
        selectButton.setImage(#imageLiteral(resourceName: "Selected"), for: .selected)
        avatar.layer.cornerRadius = avatar.frame.width / 2
        avatar.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            selectButton.isSelected = !selectButton.isSelected
            if selectButton.isSelected {
                if isPublic {
                    user.streamTo.removeAll()
                    user.publicEnabled = true
                } else {
                    user.publicEnabled = false
                    if username.text == "All Friends" {
                        user.streamTo.append(contentsOf: SSContact.current.friends)
                    } else {
                        user.streamTo.append(contact)
                    }
                }
            } else {
                user.publicEnabled = false
                if !isPublic {
                    if username.text == "All Friends" {
                        user.streamTo.removeAll()
                    } else {
                        user.streamTo.remove(at: user.streamTo.index(of: contact)!)
                    }
                }
            }
        }
    }
    
    @IBAction func set(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if selectButton.isSelected {
            if isPublic {
                user.streamTo.removeAll()
                user.publicEnabled = true
            } else {
                user.publicEnabled = false
                if username.text == "All Friends" {
                    user.streamTo.append(contentsOf: SSContact.current.friends)
                } else {
                    user.streamTo.append(contact)
                }
            }
        } else {
            user.publicEnabled = false
            if !isPublic {
                if username.text == "All Friends" {
                    user.streamTo.removeAll()
                } else {
                    user.streamTo.remove(at: user.streamTo.index(of: contact)!)
                }
            }
        }
    }
}
