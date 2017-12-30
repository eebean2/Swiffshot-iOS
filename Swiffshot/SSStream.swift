//
//  SSStream.swift
//  Swiffshot
//
//  Created by Erik Bean on 2/23/17.
//  Copyright © 2017 Dmitry Kuklin. All rights reserved.
//

import UIKit

class SSStream {
    var isPublic = true
    var views = 0
    var preview: UIImage = #imageLiteral(resourceName: "avatar_9")
    var username: String = "Swiffshot"
    var isEnabled = true
    var visableTo: [SSContact] = []
    private var isStreaming = false
    
    func prepare(isPublic: Bool, preview: UIImage) {
        self.isEnabled = true
        self.username = SSContact.current.username
        self.isPublic = isPublic
        self.preview = preview
    }
    
    func log() {
        print("\nSSStream for \(username)")
        print("Views: \(views)")
        print("Public: \(isPublic)")
        print("Preview: \(preview.description)")
    }
    
    func streamWith(_ username: String, preview: UIImage) {
        self.isEnabled = true
        self.username = username
        self.preview = preview
    }
    
    func start() {
        if isStreaming {
            return
        }
        
    }
    
    func subscribeToViews(viewUpdate: (Int) -> Void) {
        if !isStreaming {
            viewUpdate(0)
            return
        }
        viewUpdate(0)
    }
    
    func stop() {
        if !isStreaming {
            return
        }
    }
}
