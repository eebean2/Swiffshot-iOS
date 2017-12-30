//
//  WowzaViewController.swift
//  Swiffshot
//
//  Created by Benjamin Landau on 3/30/17.
//  Copyright © 2017 Swiffshot. All rights reserved.
//

import UIKit
import Firebase
import WowzaGoCoderSDK

class WowzaViewController: UIViewController, WZStatusCallback, WZVideoSink, WZAudioSink, UITextFieldDelegate {
    
    @IBOutlet weak var height: NSLayoutConstraint!
    @IBOutlet weak var chatMessageBox: UITextView!
    @IBOutlet weak var sendButtonChat: UIButton!
    @IBOutlet weak var chatTextField: UITextField!
    @IBOutlet weak var chatContainerView: UIView!
    @IBOutlet weak var endStreamButton: UIButton!
    @IBOutlet weak var owl: UIImageView!
    @IBOutlet weak var broadcastButton:UIButton!
    @IBOutlet weak var settingsButton:UIButton!
    @IBOutlet weak var switchCameraButton:UIButton!
    @IBOutlet weak var torchButton:UIButton!
    @IBOutlet weak var micButton:UIButton!
    @IBOutlet var views: UILabel!
    @IBOutlet var viewBackground: UIImageView!
    
    let savedConfigKey = "SDKSampleSavedConfigKey"
    let key = "GOSK-7743-0100-F566-7816-BBDE"
    let blackAndWhiteEffectKey = "BlackAndWhiteKey"
    
    var goCoder: WowzaGoCoder?
    var goCoderConfig: WowzaConfig!
    var receivedGoCoderEventCodes = Array<WZEvent>()
    var blackAndWhiteVideoEffect = false
    var goCoderRegistrationChecked = false
    var ref = FIRDatabase.database().reference()
    var tableView: UITableView!
    var isSelecting = false
    var didSetup = false
    let notify = NotificationCenter.default
    var keyboardIsShown = false
    
    var showAlerts = false
    
    // MARK: - Overrides
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        goCoder?.cameraPreview?.previewLayer?.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !goCoderRegistrationChecked {
            goCoderRegistrationChecked = true
            if let goCoderLicensingError = WowzaGoCoder.registerLicenseKey(key) {
                showAlert("GoCoder SDK Licensing Error", error: goCoderLicensingError as NSError)
            } else {
                if let coder = WowzaGoCoder.sharedInstance() {
                    goCoder = coder
                    WowzaGoCoder.requestPermission(for: .camera, response: { (permission) in
                        print("Camera permission is: \(permission == .authorized ? "authorized" : "denied")")
                    })
                    WowzaGoCoder.requestPermission(for: .microphone, response: { (permission) in
                        print("Microphone permission is: \(permission == .authorized ? "authorized" : "denied")")
                    })
                    goCoder?.register(self as WZAudioSink)
                    goCoder?.register(self as WZVideoSink)
                    goCoder?.config = goCoderConfig
                    goCoder?.cameraView = view
                    goCoder?.cameraPreview?.start()
                }
                updateUIControls()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        endStreamButton.isHidden = true
        chatContainerView.isHidden = true
        chatTextField.isHidden = true
        chatMessageBox.isHidden = true
        sendButtonChat.isHidden = true
        
        self.chatTextField.delegate = self
        
        notify.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        notify.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        notify.addObserver(self, selector: #selector(didTapEndStreamButton), name: .UIApplicationWillResignActive, object: nil)
        notify.addObserver(self, selector: #selector(didTapEndStreamButton), name: .UIApplicationWillTerminate, object: nil)
        
        let showChat = UISwipeGestureRecognizer(target: self, action: #selector(swipeUp))
        showChat.direction = .up
        let exitChat = UISwipeGestureRecognizer(target: self, action: #selector(swipeDown))
        exitChat.direction = .down
        view.addGestureRecognizer(showChat)
        view.addGestureRecognizer(exitChat)
        
        blackAndWhiteVideoEffect = UserDefaults.standard.bool(forKey: blackAndWhiteEffectKey)
        WowzaGoCoder.setLogLevel(.default)
        
        if let savedConfig:Data = UserDefaults.standard.object(forKey: savedConfigKey) as? Data {
            if let wowzaConfig = NSKeyedUnarchiver.unarchiveObject(with: savedConfig) as? WowzaConfig {
                goCoderConfig = wowzaConfig
            } else {
                goCoderConfig = getConfig()
            }
        } else {
            goCoderConfig = getConfig()
        }
        
        // Log version and platform info
        print("WowzaGoCoderSDK version =\n major: \(WZVersionInfo.majorVersion())\n minor: \(WZVersionInfo.minorVersion())\n revision: \(WZVersionInfo.revision())\n build: \(WZVersionInfo.buildNumber())\n string: \(WZVersionInfo.string())\n verbose string: \(WZVersionInfo.verboseString())")
        print("Platform Info:\n\(WZPlatformInfo.string())")
        
        
        if let goCoderLicensingError = WowzaGoCoder.registerLicenseKey(key) {
            self.showAlert("GoCoder SDK Licensing Error", error: goCoderLicensingError as NSError)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        didTapEndStreamButton(endStreamButton)
        navigationController?.navigationBar.isHidden = false
        UIApplication.shared.isIdleTimerDisabled = false
        notify.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        notify.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        notify.removeObserver(self, name: .UIApplicationWillResignActive, object: nil)
        notify.removeObserver(self, name: .UIApplicationWillTerminate, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        goCoder?.cameraPreview?.stop()
        goCoder?.unregisterAudioSink(self as WZAudioSink)
        goCoder?.unregisterVideoSink(self as WZVideoSink)
    }
    
    // MARK: - IBActions
    
    @IBAction func didPressSendButton(_ sender: Any) {
        if goCoder?.status.state == .running {
            if chatTextField.text != "" {
                var strings = chatMessageBox.text.components(separatedBy: "\n")
                strings.append("\(SSContact.current.username): \(chatTextField.text!)")
                chatTextField.text = ""
                SSServer().update(chat: SSContact.current.username, messages: strings) { (error) in
                    if error != nil {
                        let alert = UIAlertController(title: "Could not send message", message: "Error: \(error!.localizedDescription)", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
                        alert.addAction(ok)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        } else {
            let alert = UIAlertController(title: "Could not send message", message: "Error: You must be streaming first!", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func didTapBroadcastButton(_ sender:AnyObject?) {
        
        if !didSetup {
            initTableView()
            didSetup = true
        }
        if !isSelecting {
            isSelecting = true
            animateTableView(open: true)
        } else {
            isSelecting = false
            animateTableView(open: false)
            
            if let configError = self.goCoder?.config.validateForBroadcast() {
                showAlert("Incomplete Streaming Settings", error: configError as NSError)
            } else {
                broadcastButton.isEnabled = false
                torchButton.isEnabled = true
                switchCameraButton.isEnabled = true
                //settingsButton.isEnabled     = false
                if goCoder?.status.state != .running {
                    receivedGoCoderEventCodes.removeAll()
                    goCoder?.startStreaming(self)
                    startStreaming(completion: { (error) in
                        if error != nil {
                            self.goCoder?.endStreaming(self)
                            self.showAlert("Could not go live", error: error! as NSError)
                            SSContact.current.stopStreaming()
                        } else {
                            self.owl.tintColor = .cyan
                            self.owl.layer.shadowColor = UIColor.cyan.cgColor
                            self.owl.layer.shadowOpacity = 0.85
                            self.owl.layer.shadowRadius = 4.5
                            self.viewBackground.isHidden = false
                            self.views.isHidden = false
                            self.endStreamButton.isHidden = false
                            self.broadcastButton.isHidden = true
                            self.chatContainerView.isHidden = false
                            self.chatTextField.isHidden = false
                            self.chatMessageBox.isHidden = false
                            self.sendButtonChat.isHidden = false
                            self.chatContainerView.backgroundColor = UIColor.clear
                            self.chatTextField.borderStyle = .roundedRect
                            self.chatTextField.layer.cornerRadius = 5
                            self.chatTextField.backgroundColor = UIColor.clear
                            self.chatTextField.textColor = UIColor.white
                            self.chatTextField.layer.borderColor = UIColor.white.cgColor
                            self.chatTextField.layer.borderWidth = 1.5
                            self.chatTextField.attributedPlaceholder = NSAttributedString(string: "Send Message...", attributes: [NSForegroundColorAttributeName: UIColor.white])
                            SSServer().subscribeTo(chat: SSContact.current.username) { (chatData) in
                                self.chatMessageBox.text = chatData.joined(separator: "\n")
                                self.chatMessageBox.scrollRangeToVisible(NSRange(location: self.chatMessageBox.text.characters.count - 1, length: 1))
                            }
                            //let audioMuted = goCoder?.isAudioMuted ?? false
                            //micButton.setImage(UIImage(named: audioMuted ? "mic_off_button" : "mic_on_button"), for: UIControlState())
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func didTapEndStreamButton(_ sender: Any) {
        if goCoder?.status.state == .running {
            goCoder?.endStreaming(self)
            broadcastButton.isHidden = false
            broadcastButton.isEnabled = true
            endStreamButton.isHidden = true
            views.isHidden = true
            viewBackground.isHidden = true
            self.owl.tintColor = .white
            self.owl.layer.shadowColor = UIColor.clear.cgColor
            self.owl.layer.shadowOpacity = 0.0
            self.owl.layer.shadowRadius = 0.0
            chatContainerView.isHidden = true
            chatTextField.isHidden = true
            chatMessageBox.isHidden = true
            sendButtonChat.isHidden = true
            self.view.endEditing(true)
        }
        broadcastButton.isHidden = false
        SSContact.current.stopStreaming()
    }
    
    @IBAction func didTapSwitchCameraButton(_ sender:AnyObject?) {
        if let otherCamera = goCoder?.cameraPreview?.otherCamera() {
            if !otherCamera.supportsWidth(goCoderConfig.videoWidth) {
                goCoderConfig.load(otherCamera.supportedPresetConfigs.last!.toPreset())
                goCoder?.config = goCoderConfig
            }
            
            goCoder?.cameraPreview?.switchCamera()
            torchButton.setImage(UIImage(named: "torch_on_button"), for: UIControlState())
            self.updateUIControls()
        }
    }
    
    @IBAction func didTapTorchButton(_ sender:AnyObject?) {
        var newTorchState = goCoder?.cameraPreview?.camera?.isTorchOn ?? true
        newTorchState = !newTorchState
        goCoder?.cameraPreview?.camera?.isTorchOn = newTorchState
        torchButton.setImage(UIImage(named: newTorchState ? "torch_off_button" : "torch_on_button"), for: UIControlState())
    }
    
    @IBAction func didTapMicButton(_ sender:AnyObject?) {
        var newMutedState = self.goCoder?.isAudioMuted ?? true
        newMutedState = !newMutedState
        goCoder?.isAudioMuted = newMutedState
        micButton.setImage(UIImage(named: newMutedState ? "mic_off_button" : "mic_on_button"), for: UIControlState())
    }
    
    @IBAction func didTapSettingsButton(_ sender:AnyObject?) {
//        if let settingsNavigationController = UIStoryboard(name: "GoCoderSettings", bundle: nil).instantiateViewController(withIdentifier: "settingsNavigationController") as? UINavigationController {
//            
//            if let settingsViewController = settingsNavigationController.topViewController as? SettingsViewController {
//                settingsViewController.addAllSections()
//                settingsViewController.removeDisplay(.recordVideoLocally)
//                settingsViewController.removeDisplay(.backgroundMode)
//                let viewModel = SettingsViewModel(sessionConfig: goCoderConfig)
//                viewModel?.supportedPresetConfigs = goCoder?.cameraPreview?.camera?.supportedPresetConfigs
//                settingsViewController.viewModel = viewModel!
//            }
//            
//            
//            self.present(settingsNavigationController, animated: true, completion: nil)
//        }
    }
    
    //MARK: - WZStatusCallback Protocol Instance Methods
    
    func onWZStatus(_ status: WZStatus!) {
//        switch (status.state) {
//        case .idle:
//            DispatchQueue.main.async { () -> Void in
//                self.broadcastButton.setImage(UIImage(named: "start_button"), for: UIControlState())
//                self.updateUIControls()
//            }
//        case .running:
//            DispatchQueue.main.async { () -> Void in
//                self.broadcastButton.setImage(UIImage(named: "stop_button"), for: UIControlState())
//                self.updateUIControls()
//            }
//        case .stopping, .starting:
//            DispatchQueue.main.async { () -> Void in
//                self.updateUIControls()
//            }
//        case .buffering:
//            break
//        }
    }
    
    func onWZEvent(_ status: WZStatus!) {
        // If an event is reported by the GoCoder SDK, display an alert dialog describing the event,
        // but only if we haven't already shown an alert for this event
        
        DispatchQueue.main.async { () -> Void in
            if !self.receivedGoCoderEventCodes.contains(status.event) {
                self.receivedGoCoderEventCodes.append(status.event)
                self.showAlert("Live Streaming Event", status: status)
            }
            self.updateUIControls()
        }
    }
    
    func onWZError(_ status: WZStatus!) {
        // If an error is reported by the GoCoder SDK, display an alert dialog containing the error details
        DispatchQueue.main.async { () -> Void in
            self.showAlert("Live Streaming Error", status: status)
            self.updateUIControls()
        }
    }
    
    //MARK: - Keyboard Methods
    
    func keyboardWillShow(_ sender: NSNotification) {
        keyboardIsShown = true
        if let userInfo = sender.userInfo {
            if let keyboardHeight = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                chatContainerView.frame.origin.y -= keyboardHeight
                height.constant += keyboardHeight
            }
        }
    }
    
    func keyboardWillHide(_ sender: NSNotification) {
        keyboardIsShown = false
        if let userInfo = sender.userInfo {
            if let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                chatContainerView.frame.origin.y += keyboardHeight
                height.constant -= keyboardHeight
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func swipeDown(_ sender: UIGestureRecognizer) {
        if keyboardIsShown {
            UIView.animate(withDuration: 0.5, animations: { 
                self.chatTextField.resignFirstResponder()
            })
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
        }
    }
    
    //MARK: - WZVideoSink Protocol Methods
    
    func videoFrameWasCaptured(_ imageBuffer: CVImageBuffer, framePresentationTime: CMTime, frameDuration: CMTime) {
        if goCoder != nil && goCoder!.isStreaming && blackAndWhiteVideoEffect {
            // convert frame to b/w using CoreImage tonal filter
            var frameImage = CIImage(cvImageBuffer: imageBuffer)
            if let grayFilter = CIFilter(name: "CIPhotoEffectTonal") {
                grayFilter.setValue(frameImage, forKeyPath: "inputImage")
                if let outImage = grayFilter.outputImage {
                    frameImage = outImage
                    let context = CIContext(options: nil)
                    context.render(frameImage, to: imageBuffer)
                }
            }
        }
    }
    
    func videoCaptureInterruptionStarted() {
        goCoder?.endStreaming(self)
    }
    
    //MARK: - WZAudioSink Protocol Methods
    
    func audioLevelDidChange(_ level: Float) {
        print("Audio level did change: \(level)");
    }
    
    // MARK: - Other Methods
    
    func updateUIControls() {
        if goCoder?.status.state != .idle && goCoder?.status.state != .running {
            // If a streaming broadcast session is in the process of starting up or shutting down,
            // disable the UI controls
            self.broadcastButton.isEnabled    = false
            self.torchButton.isEnabled        = false
            self.switchCameraButton.isEnabled = false
//            self.settingsButton.isEnabled     = false
//            self.micButton.isHidden           = true
//            self.micButton.isEnabled          = false
        } else {
            // Set the UI control state based on the streaming broadcast status, configuration,
            // and device capability
            self.broadcastButton.isEnabled    = true
            self.switchCameraButton.isEnabled = ((self.goCoder?.cameraPreview?.cameras?.count) ?? 0) > 1
            self.torchButton.isEnabled        = self.goCoder?.cameraPreview?.camera?.hasTorch ?? false
//            let isStreaming                 = self.goCoder?.isStreaming ?? false
//            self.settingsButton.isEnabled     = !isStreaming
//            // The mic icon should only be displayed while streaming and audio streaming has been enabled
//            // in the GoCoder SDK configuration setiings
//            self.micButton.isEnabled          = isStreaming && self.goCoderConfig.audioEnabled
//            self.micButton.isHidden           = !self.micButton.isEnabled
        }
    }
    
    func getConfig() -> WowzaConfig {
        
        print("Name: \(SSContact.current.username)")
        
        let config = WowzaConfig(preset: .preset1920x1080)
        config.hostAddress = "54.242.159.242"
        config.portNumber = 1935
        config.streamName = SSContact.current.username
        config.applicationName = "Swiffshot"
        config.username = "streamer"
        config.password = "ImStreaming"
        config.broadcastVideoOrientation = .sameAsDevice
        config.broadcastScaleMode = .aspectFill
        return config
    }
    
    func startStreaming(completion: @escaping (Error?) -> Void) {
        SSContact.current.sendStreamInvites { (contacts) in
            if !contacts.isEmpty {
                let alert = UIAlertController(title: "Oh No!", message: "Not everyone could be invited! Some were not invited because either they do not have an updated version of Swiffshot or have not been on in a while!", preferredStyle: .alert)
                let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
            }
        }
        SSContact.current.isStreaming(public: SSContact.current.publicEnabled, to: SSContact.current.streamTo, verification: { (error) in
            if error != nil {
                let alert = UIAlertController(title: "Oh No! We couldn't go live!", message: "Error: \(error!.localizedDescription)", preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                    self.navigationController?.navigationBar.isHidden = false
                    _ = self.navigationController?.popViewController(animated: true)
                })
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
                print("Long Tap Error")
                print(error!.localizedDescription)
            }
            completion(error)
        }, live: { (_, views) in
            self.views.text = "\(views)"
        })
    }
    
    //MARK: - Alerts
    
    func showAlert(_ title:String, status:WZStatus) {
        let alertController = UIAlertController(title: title, message: status.description, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(action)
        if showAlerts {
            self.present(alertController, animated: true, completion: nil)
        } else {
            print("Wowza Alert: \(title) Status: \(status.description)")
        }
    }
    
    func showAlert(_ title:String, error:NSError) {
        let alertController = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(action)
        if showAlerts {
            self.present(alertController, animated: true, completion: nil)
        } else {
            print("Wowza Alert: \(title) Error: \(error.localizedDescription)")
        }
    }
    //MARK:-
}

extension WowzaViewController: UITableViewDelegate, UITableViewDataSource {
    
    //MARK:- TableView Methods
    
    func initTableView() {
        let tableView = UITableView(frame: CGRect(x: 20, y: view.frame.height / 2, width: view.frame.width - 40, height: 0))
        tableView.allowsMultipleSelection = true
        tableView.register(UINib(nibName: "SendToCell", bundle: Bundle.main), forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.layer.cornerRadius = 15
        tableView.layer.masksToBounds = true
        self.tableView = tableView
        view.addSubview(tableView)
    }
    
    func animateTableView(open: Bool) {
        if open {
            UIView.animate(withDuration: 0.5, animations: {
                let rect = CGRect(x: 20, y: self.view.frame.height / 2, width: self.view.frame.width - 40, height: (self.view.frame.height / 2) - (self.broadcastButton.frame.height + 50))
                self.tableView.frame = rect
            })
        } else {
            UIView.animate(withDuration: 0.5, animations: {
                let rect = CGRect(x: 20, y: self.view.frame.height / 2, width: self.view.frame.width - 40, height: 0)
                self.tableView.frame = rect
            })
        }
    }
    
    //MARK:- TableView Delegates and Datasource
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Swiff to..."
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if SSContact.current.friends.count > 1 {
            return SSContact.current.friends.count + 2
        } else {
            return SSContact.current.friends.count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! SendToCell
        if indexPath.row == 0 {
            cell.avatar.backgroundColor = .clear
            cell.username.text = "Public"
            cell.isPublic = true
        } else if indexPath.row == 1 && SSContact.current.friends.count > 1 {
            cell.avatar.backgroundColor = .clear
            cell.username.text = "All Friends"
            cell.isPublic = false
        } else {
            var row = indexPath.row - 1
            if SSContact.current.friends.count > 1 {
                row = indexPath.row - 2
            }
//            if SSContact.current.friends[row].avatar != nil {
//                cell.avatar.image = SSContact.current.friends[row].avatar
//            } else {
//                cell.avatar.backgroundColor = .clear
//            }
            cell.isPublic = false
            cell.username.text = SSContact.current.friends[row].username
            cell.contact = SSContact.current.friends[row]
        }
        return cell
    }
}



