//
//  LockerRoomURLProvider.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/25/24.
//

import Foundation

enum LockerRoomLockboxFileType: String {
    case encryptedContentFileType = "EncryptedContent.dmg"
    case encryptedSymmetricKeyFileType = "EncryptedSymmetricKey.key"
    case unencryptedContentFileType = "UnencryptedContent.dmg"
}

enum LockerRoomKeyFileType: String {
    case publicKeysFileType = "PublicKey.plist"
}

protocol LockerRoomURLProviding {
    var rootURL: URL { get }
    var urlForLockboxes: URL { get }
    var urlForKeys: URL { get }
    
    func urlForLockbox(name: String) -> URL
    func urlForLockboxFile(name: String, type: LockerRoomLockboxFileType) -> URL
    
    func urlForKey(name: String) -> URL
    func urlForKeyFile(name: String, type: LockerRoomKeyFileType) -> URL
    
    func urlForMountedVolume(name: String) -> URL
}

struct LockerRoomURLProvider: LockerRoomURLProviding {
    static let lockboxesPathComponent = "Lockboxes"
    static let keysPathComponent = "Keys"
    static let volumesPathComponent = "/Volumes/"
    
    internal var rootURL: URL
    private let fileManager = FileManager.default
        
    init(rootURL: URL? = nil) {
        let documentDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let temporaryDirectoryURL = fileManager.temporaryDirectory
        
        let resolvedRootURL: URL
        if let rootURL {
            resolvedRootURL = rootURL
        } else if let documentDirectoryURL {
            resolvedRootURL = documentDirectoryURL
        } else {
            resolvedRootURL = temporaryDirectoryURL
        }
        self.rootURL = resolvedRootURL
        
        print("[Default] Locker room URL provider is using root directory \(resolvedRootURL)")
    }
    
    var urlForLockboxes: URL {
        rootURL.appending(component: LockerRoomURLProvider.lockboxesPathComponent)
    }
    
    var urlForKeys: URL {
        rootURL.appending(component: LockerRoomURLProvider.keysPathComponent)
    }
    
    func urlForLockbox(name: String) -> URL {
        urlForLockboxes.appending(component: name)
    }
    
    func urlForLockboxFile(name: String, type: LockerRoomLockboxFileType) -> URL {
        urlForLockbox(name: name).appending(component: type.rawValue)
    }
    
    func urlForKey(name: String) -> URL {
        urlForKeys.appending(component: name)
    }
    
    func urlForKeyFile(name: String, type: LockerRoomKeyFileType) -> URL {
        urlForKey(name: name).appending(component: type.rawValue)
    }
    
    func urlForMountedVolume(name: String) -> URL {
        URL(filePath: "\(LockerRoomURLProvider.volumesPathComponent)\(name)")
    }
}

