//
//  CameraViewController.swift
//  Swiffshot
//
//  Created by Dmitry Kuklin on 25.11.16.
//  Copyright © 2016 Dmitry Kuklin. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

// Possible major problem file

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var previewLayer : AVCaptureVideoPreviewLayer?
    var cameraView : CameraView!
    var captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var filePath : URL?
    var isBackCamera = true
    var publisher: PublishViewController!
    var isPublishing: Bool = false
    var isOnline: Bool = false
    var playerViewController = PlayerViewController()
    
    //MARK: - SYSTEMS METHODS
    
    //NOTE: Can we condense this?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pathTosave()
        AVAudioSession.sharedInstance().requestRecordPermission { (permission) in
            if permission {
                //we have lift off!
            } else {
                //Houston we have a problem!
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cameraView = CameraView.instanceFromNib()
        cameraView.frame = view.frame
        view.insertSubview(cameraView, at: 0)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isPublishing = false
    }


    // MARK: - CAMERA METHODS
    
    // NOTE: Deprecated!!! AVCaptureDevice is Deprecated in iOS 10
    
    func turnOnCamera() {
        
        DispatchQueue.global(qos: .default).async {
            self.captureSession.sessionPreset = AVCaptureSessionPresetHigh
            let devices = AVCaptureDevice.devices()
            print(devices!)
            for device in devices! {
                if ((device as AnyObject).hasMediaType(AVMediaTypeVideo)) {
                    if((device as AnyObject).position == AVCaptureDevicePosition.back && self.isBackCamera) {
                        self.captureDevice = device as? AVCaptureDevice
                        if self.captureDevice != nil {
                            print("Capture device back camera found")
                            break
                        }
                    } else if((device as AnyObject).position == AVCaptureDevicePosition.front && !self.isBackCamera) {
                        self.captureDevice = device as? AVCaptureDevice
                        if self.captureDevice != nil {
                            print("Capture device front camera found")
                            break
                        }
                    }
                }
            }
            self.previewLayer = self.beginSession()
            DispatchQueue.main.async(execute: {
                self.cameraView.screenView.layer.addSublayer(self.previewLayer!)
                })
            }

    }
    
    fileprivate func pathTosave() {
        
// NOTE: Dynamic File Name Required!
        print("Error :: \(#function) :: Dynamic file name required")
        
        let fileName = "Swiffshot.mp4"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        filePath = documentsURL.appendingPathComponent(fileName)
    }
    
    fileprivate func beginSession() -> AVCaptureVideoPreviewLayer {
        configureDevice()
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.beginConfiguration()
            
            if (captureSession.canAddInput(deviceInput) == true) {
                captureSession.addInput(deviceInput)
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32 as UInt32)]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if (captureSession.canAddOutput(dataOutput) == true) {
                captureSession.addOutput(dataOutput)
            }
            captureSession.commitConfiguration()
            
            let queue = DispatchQueue(label: "com.invasivecode.videoQueue", attributes: [])
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
        }
        catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = self.view.frame
        previewLayer?.videoGravity = AVLayerVideoGravityResize
        captureSession.startRunning()
        return previewLayer!
    }
    
    fileprivate func configureDevice() {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
            } catch {
                return
            }
            if isBackCamera { device.focusMode = .continuousAutoFocus }
            device.unlockForConfiguration()
        }
    }
    
    func srartStopRecord(_ isStart: Bool){
        let videoFileOutput = AVCaptureMovieFileOutput()
        if isStart{
            self.captureSession.addOutput(videoFileOutput)
            
            let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self
            videoFileOutput.startRecording(toOutputFileURL: filePath, recordingDelegate: recordingDelegate)
        } else {
            if isOnline{
                publisher.stop()
                isOnline = false
            } else {
                videoFileOutput.stopRecording()
                UISaveVideoAtPathToSavedPhotosAlbum((filePath?.relativePath)!,self,nil,nil)
            }
        }
    }
    
    //MARK: STREAMING METHODS
    
    func stopStreaming(){
        publisher.stop()
    }
    
    func goStreaming(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "publishView")
        
        let frameSize = cameraView.screenView.bounds
        publisher = controller as! PublishViewController
        publisher.view.layer.frame = frameSize
        publisher.preview(isBackCamera)
        
        cameraView.screenView.addSubview(publisher.view)
        
        isPublishing ? publisher.stop() : publisher.start()
        isPublishing = !isPublishing
        isOnline = true
    }
    
    func removePreviewLayer(){
        captureSession = AVCaptureSession()
        previewLayer?.removeFromSuperlayer()
    }
    
    //MARK: - LOAD VIDEO
    
    func loadVideo() {
        removePreviewLayer()
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        imagePicker.modalPresentationStyle = .overFullScreen
        imagePicker.navigationBar.isTranslucent = false
        imagePicker.navigationBar.barTintColor = UIColor(colorLiteralRed: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
        present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK: - IMAGE PICKER METHODS
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        dismiss(animated: true, completion: nil)
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        if mediaType == "public.movie"{
            let videoURL = info[UIImagePickerControllerMediaURL] as! URL
            playerViewController.createVideoPlayer(videoURL)
            showPlayer(playerViewController)
        }
    }
    
    func showPlayer(_ playerController: PlayerViewController){
        self.present(playerController, animated: true){
            print("PLAYING")
            DispatchQueue.main.async {
                playerController.player?.play()
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: CATURE DELEGATE METHODS
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!){
        print("capture did finish")
        print(captureOutput)
        print(outputFileURL)
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!){
        print("capture output: started recording to \(fileURL)")
    }
}
