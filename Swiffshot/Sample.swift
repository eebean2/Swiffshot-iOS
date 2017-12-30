//
//  Sample.swift
//  Swiffshot
//
//  Created by Erik Bean on 4/13/17.
//  Copyright © 2017 Swiffshot. All rights reserved.
//

import AVKit

class Sample: AVPlayerViewController, UITextFieldDelegate {
    
    private var chatView: UIView!
    private var isTyping = false
    private var isMuted = false
    private let notify = NotificationCenter.default
    private var height: NSLayoutConstraint!
    private var sendField: UITextField!
    private var chatBox: UITextView!
    var user: SSStream!
    
    // MARK:- View Overrides
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        showsPlaybackControls = false
        UIApplication.shared.isIdleTimerDisabled = true
        if player != nil && player?.rate != 1 {
            player!.play()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        draw()
        SSContact.current.subscribeTo(stream: user.username)
        notify.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        notify.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        notify.addObserver(self, selector: #selector(quit), name: .UIApplicationWillResignActive, object: nil)
        notify.addObserver(self, selector: #selector(quit), name: .UIApplicationWillTerminate, object: nil)
        addGestures()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        navigationController?.navigationBar.isHidden = false
        notify.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        notify.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        notify.removeObserver(self, name: .UIApplicationWillResignActive, object: nil)
        notify.removeObserver(self, name: .UIApplicationWillTerminate, object: nil)
        player?.pause()
        player = nil
    }
    
    // MARK:- User Interface
    
    private func draw() {
        
        // Top Buttons
        
        let topButton = UIButton(frame: CGRect(x: UIApplication.shared.keyWindow!.center.x - 87.5, y: 20, width: 175, height: 30))
        topButton.setTitle(user.username, for: .normal)
        topButton.titleLabel!.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightSemibold)
        topButton.addTarget(self, action: #selector(segueToProfile), for: .touchUpInside)
        view.addSubview(topButton)
        let rightButton = UIButton(frame: CGRect(x: UIApplication.shared.keyWindow!.frame.width - 29, y: 20, width: 13, height: 40))
        rightButton.setImage(#imageLiteral(resourceName: "Report"), for: .normal)
        rightButton.addTarget(self, action: #selector(report), for: .touchUpInside)
        
        // Chat Base
        
        chatView = UIView(frame: CGRect(x: 0, y: 480, width: UIApplication.shared.keyWindow!.frame.width, height: 187))
        chatView.backgroundColor = UIColor.clear
        
        view.addSubview(rightButton)
        view.addSubview(chatView)
        
        NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: chatView, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: chatView, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: bottomLayoutGuide, attribute: .top, relatedBy: .equal, toItem: chatView, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        height = NSLayoutConstraint(item: chatView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 187)
        height.isActive = true
        
        // Chat Elements
        
        drawTextBox()
        drawTextField()
        let send = drawSendButton()
        
        drawConstraints(send: send)
    }
    
    private func drawTextBox() {
        chatBox = UITextView(frame: CGRect(x: 8, y: 8, width: chatView.frame.width - 16, height: 133))
        chatBox.textColor = .white
        chatBox.font = UIFont.boldSystemFont(ofSize: 17)
        chatBox.backgroundColor = .clear
        chatBox.isEditable = false
        chatBox.dataDetectorTypes = .all
        SSServer().subscribeTo(chat: user.username) { (chatData) in
            self.chatBox.text = chatData.joined(separator: "\n")
            self.chatBox.scrollRangeToVisible(NSRange(location: self.chatBox.text.characters.count - 1, length: 1))
        }
        chatView.addSubview(chatBox)
    }
    
    private func drawTextField() {
        sendField = UITextField(frame: CGRect(x: 8, y: 149, width: chatView.frame.width - 54, height: 30))
        sendField.autocapitalizationType = .sentences
        sendField.delegate = self
        sendField.backgroundColor = UIColor.clear
        sendField.tintColor = .white
        sendField.textColor = .white
        sendField.borderStyle = .roundedRect
        sendField.layer.cornerRadius = 5
        sendField.backgroundColor = UIColor.clear
        sendField.textColor = UIColor.white
        let myColor : UIColor = UIColor.white
        sendField.layer.borderColor = myColor.cgColor
        sendField.layer.borderWidth = 1.5
        sendField.attributedPlaceholder = NSAttributedString(string: "Send Message...", attributes: [NSForegroundColorAttributeName: UIColor.white])
        chatView.addSubview(sendField)
    }
    
    private func drawSendButton() -> UIButton {
        let sendButton = UIButton(frame: CGRect(x: chatView.frame.width - 38, y: 149, width: 30, height: 30))
        sendButton.setImage(#imageLiteral(resourceName: "Send"), for: .normal)
        sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)
        chatView.addSubview(sendButton)
        
        return sendButton
    }
    
    private func drawConstraints(send: UIButton) {
        
        NSLayoutConstraint(item: chatView, attribute: .trailing, relatedBy: .equal, toItem: chatBox, attribute: .trailing, multiplier: 1, constant: 8).isActive = true
        NSLayoutConstraint(item: chatBox, attribute: .leading, relatedBy: .equal, toItem: chatView, attribute: .leading, multiplier: 1, constant: 8).isActive = true
        NSLayoutConstraint(item: chatBox, attribute: .top, relatedBy: .equal, toItem: chatView, attribute: .top, multiplier: 1, constant: 8).isActive = true
        NSLayoutConstraint(item: sendField, attribute: .leading, relatedBy: .equal, toItem: chatView, attribute: .leading, multiplier: 1, constant: 8).isActive = true
        NSLayoutConstraint(item: sendField, attribute: .top, relatedBy: .equal, toItem: chatBox, attribute: .bottom, multiplier: 1, constant: 8).isActive = true
         NSLayoutConstraint(item: send, attribute: .leading, relatedBy: .equal, toItem: sendField, attribute: .trailing, multiplier: 1, constant: 8).isActive = true
        NSLayoutConstraint(item: send, attribute: .top, relatedBy: .equal, toItem: chatBox, attribute: .bottom, multiplier: 1, constant: 8).isActive = true
        NSLayoutConstraint(item: chatView, attribute: .trailing, relatedBy: .equal, toItem: send, attribute: .trailing, multiplier: 1, constant: 8).isActive = true
        NSLayoutConstraint(item: chatBox, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 133).isActive = true
        NSLayoutConstraint(item: send, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30).isActive = true
        NSLayoutConstraint(item: send, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30).isActive = true
        chatBox.translatesAutoresizingMaskIntoConstraints = false
        sendField.translatesAutoresizingMaskIntoConstraints = false
        send.translatesAutoresizingMaskIntoConstraints = false
        chatView.translatesAutoresizingMaskIntoConstraints = false
        chatView.setNeedsUpdateConstraints()
    }
    
    // MARK:- Chat and Textfield Methods
    
    func send(_ sender: UIButton?) {
        if sendField.text != "" {
            var strings = chatBox.text.components(separatedBy: "\n")
            strings.append("\(SSContact.current.username): \(sendField.text!)")
            sendField.text = ""
            SSServer().update(chat: user.username, messages: strings) { (error) in
                if error != nil {
                    let alert = UIAlertController(title: "Could not send message", message: "Error: \(error!.localizedDescription)", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text != "" {
            send(nil)
            textField.text = ""
        }
        textField.resignFirstResponder()
        return true
    }
    
    // MARK:- Exit
    
    func playerFinished(_ notification: NSNotification) {
        let alert = UIAlertController(title: "Swiff Over", message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default) { (_) in
            self.quit()
        }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    func quit() {
        SSServer().unsubscribeFrom(chat: user.username)
        SSContact.current.unsubscribeFrom(stream: user.username)
        _ = navigationController?.popViewController(animated: true)
    }
    
    // MARK:- Gestures
    
    private var keyboardIsShown = false
    
    private func addGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(shortTap))
        let exit = UISwipeGestureRecognizer(target: self, action: #selector(quit))
        exit.direction = .right
        let showChat = UISwipeGestureRecognizer(target: self, action: #selector(swipeUp))
        showChat.direction = .up
        let exitChat = UISwipeGestureRecognizer(target: self, action: #selector(swipeDown))
        exitChat.direction = .down
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(exit)
        view.addGestureRecognizer(showChat)
        view.addGestureRecognizer(exitChat)
    }
    
    func keyboardWillShow(_ sender: NSNotification) {
        keyboardIsShown = true
        if let userInfo = sender.userInfo {
            if let keyboardHeight = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                chatView.frame.origin.y -= keyboardHeight
                height.constant += keyboardHeight
            }
        }
    }
    
    func keyboardWillHide(_ sender: NSNotification?) {
        keyboardIsShown = false
        chatView.frame.origin.y += 215
        height.constant = 187
    }
    
    func shortTap(_ sender: UIGestureRecognizer) {
        if keyboardIsShown {
            sendField.resignFirstResponder()
            keyboardWillHide(nil)
        } else {
            player!.isMuted = !player!.isMuted
        }
    }
    
    func swipeDown(_ sender: UIGestureRecognizer) {
        if keyboardIsShown {
            sendField.resignFirstResponder()
            keyboardWillHide(nil)
        } else {
            UIView.animate(withDuration: 0.5, animations: { 
                self.height.constant = 0
            })
        }
    }
    
    func swipeUp(_ sender: UIGestureRecognizer) {
        if !keyboardIsShown {
            UIView.animate(withDuration: 0.5, animations: { 
                self.height.constant = 187
            })
        } else {
            if sendField.canBecomeFirstResponder {
                sendField.becomeFirstResponder()
            }
        }
    }
    
    //MARK:- Report
    
    func report(_ sender: UIButton) {
        let alert = UIAlertController(title: "Report", message: "What would you like to report?", preferredStyle: .alert)
        let chat = UIAlertAction(title: "Chat", style: .default) { (action) in
            let report: [AnyHashable: Any] = ["reportedStream" : self.user.username,
                                              "reportingUser" : SSContact.current.username,
                                              "reportType" : "chat"]
            SSServer().submit(report: report, completion: { (error) in
                if error != nil {
                    self.error(error!)
                } else {
                    self.thankYou()
                }
            })
        }
        let video = UIAlertAction(title: "Video", style: .default) { (action) in
            let report: [AnyHashable: Any] = ["reportedStream" : self.user.username,
                                              "reportingUser" : SSContact.current.username,
                                              "reportType" : "video"]
            SSServer().submit(report: report, completion: { (error) in
                if error != nil {
                    self.error(error!)
                } else {
                    self.thankYou()
                }
            })
        }
        let both = UIAlertAction(title: "Both", style: .default) { (action) in
            let report: [AnyHashable: Any] = ["reportedStream" : self.user.username,
                                              "reportingUser" : SSContact.current.username,
                                              "reportType" : "chat&&video"]
            SSServer().submit(report: report, completion: { (error) in
                if error != nil {
                    self.error(error!)
                } else {
                    self.thankYou()
                }
            })
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(chat)
        alert.addAction(video)
        alert.addAction(both)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
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
    
    //MARK:- Segue
    
    func segueToProfile(_ sender: UIButton) {
        performSegue(withIdentifier: "profile", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "profile" {
            player!.pause()
            let destination = segue.destination as! SSStreamerProfile
            destination.stream = user.username
        }
    }
}
