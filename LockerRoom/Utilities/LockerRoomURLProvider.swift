//
//  LockerRoomURLProvider.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/25/24.
//

import Foundation

enum LockboxFileType: String {
    case encryptedContentFileType = "EncryptedContent.dmg"
    case encryptedSymmetricKeyFileType = "EncryptedSymmetricKey.key"
    case unencryptedContentFileType = "UnencryptedContent.dmg"
}

protocol LockerRoomURLProviding {
    var rootURL: URL { get }
    var urlForLockboxes: URL { get }
    func urlForLockbox(name: String) -> URL
    func urlForLockboxFile(name: String, type: LockboxFileType) -> URL
    func urlForMountedVolume(name: String) -> URL
}

struct LockerRoomURLProvider: LockerRoomURLProviding {
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
        rootURL.appending(component: "Lockboxes")
    }
    
    func urlForLockbox(name: String) -> URL {
        urlForLockboxes.appending(component: name)
    }
    
    func urlForLockboxFile(name: String, type: LockboxFileType) -> URL {
        urlForLockbox(name: name).appending(component: type.rawValue)
    }
    
    func urlForMountedVolume(name: String) -> URL {
        URL(filePath: "/Volumes/\(name)")
    }
}

