//
//  Defaults.swift
//  kixx
//
//  Created by Vladimir Borodko on 12/02/16.
//  Copyright © 2016 kixx.today. All rights reserved.
//

import UIKit


class Defaults {
    static let sharedDefaults = Defaults(defaults: UserDefaults.standard)
    
    private var defaults: UserDefaults
    private var token: NSObjectProtocol
    private enum Keys: String {
        case UserName //TODO: Replace with Model
        case UserNick //TODO: Replace with Model
        case UserAvatar //TODO: Replace with Model
        case UserLogged
        case LocalHost
        case HostPort
        case UserKnowAboutCamera
    }
    
    init(defaults: UserDefaults) {
        self.defaults = defaults
        self.token = NotificationCenter.default.addObserver(forName: .UIApplicationWillResignActive, object: nil, queue: nil) { _ in
            defaults.synchronize()
        }
        defaults.register( defaults: [
            Keys.LocalHost.rawValue: "52.88.33.14",
            Keys.HostPort.rawValue: 8554,
            Keys.UserLogged.rawValue: false,
            Keys.UserKnowAboutCamera.rawValue: false,
            ])
    }
    
    deinit {
        NotificationCenter.default.removeObserver(token)
    }
    
    var userName: String {
        get {
            return defaults.string(forKey: Keys.UserName.rawValue) ?? ""
        }
        set {
            defaults.set(newValue, forKey: Keys.UserName.rawValue)
            defaults.synchronize()
        }
    }
    
    var userNick: String {
        get {
            return defaults.string(forKey: Keys.UserNick.rawValue) ?? ""
        }
        set {
            defaults.set(newValue, forKey: Keys.UserNick.rawValue)
            defaults.synchronize()
        }
    }
    
    var userAvatar: String {
        get {
            return defaults.string(forKey: Keys.UserAvatar.rawValue) ?? ""
        }
        set {
            defaults.set(newValue, forKey: Keys.UserAvatar.rawValue)
            defaults.synchronize()
        }
    }
    
    var userLogged: Bool {
        get {
            return defaults.bool(forKey: Keys.UserLogged.rawValue)
        }
        set {
            defaults.set(newValue, forKey: Keys.UserLogged.rawValue)
            defaults.synchronize()
        }
    }
    
    var userKnowAboutCamera: Bool {
        get {
            return defaults.bool(forKey: Keys.UserKnowAboutCamera.rawValue)
        }
        set {
            defaults.set(newValue, forKey: Keys.UserKnowAboutCamera.rawValue)
            defaults.synchronize()
        }
    }
    
    var localHost: String {
        get {
            return defaults.string(forKey: Keys.LocalHost.rawValue)!
        }
    }
    
    var hostPort: Int {
        get {
            return defaults.integer(forKey: Keys.HostPort.rawValue)
        }
    }
    
    func reset() {
        defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        defaults.synchronize()
    }
}
