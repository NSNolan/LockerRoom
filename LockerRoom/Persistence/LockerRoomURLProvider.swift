//
//  LockerRoomURLProvider.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/25/24.
//

import Foundation

import os.log

protocol LockerRoomURLProviding {
    var rootURL: URL { get }
    
    var urlForLockboxes: URL { get }
    var urlForKeys: URL { get }
    
    func urlForLockbox(name: String) -> URL
    func urlForLockboxMetadata(name: String) -> URL
    func urlForLockboxUnencryptedContent(name: String) -> URL
    func urlForLockboxEncryptedContent(name: String) -> URL
    
    func urlForKey(name: String) -> URL
    func urlForKeyFile(name: String) -> URL
    
    func urlForAttachedDevice(name: String) -> URL
    func urlForMountedVolume(name: String) -> URL
}

struct LockerRoomURLProvider: LockerRoomURLProviding {
    private static let metadataFileName = "Metadata.plist"
    private static let unencryptedContentFileName = "Content.dmg"
    private static let encryptedContentFileName = "Content.enc"
    private static let lockboxKeyFileName = "LockboxKey.plist"
    
    private static let lockboxesPathComponent = "Lockboxes"
    private static let keysPathComponent = "Keys"
    private static let devicePathComponent = "/dev"
    private static let volumesPathComponent = "/Volumes/"
    
    private let fileManager = FileManager.default
    
    let rootURL: URL
        
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
        
        Logger.persistence.log("Locker room URL provider is using root directory \(resolvedRootURL)")
    }
    
    var urlForLockboxes: URL {
        return rootURL.appending(component: LockerRoomURLProvider.lockboxesPathComponent)
    }
    
    var urlForKeys: URL {
        return rootURL.appending(component: LockerRoomURLProvider.keysPathComponent)
    }
    
    func urlForLockbox(name: String) -> URL {
        return urlForLockboxes.appending(component: name)
    }
    
    func urlForLockboxMetadata(name: String) -> URL {
        return urlForLockbox(name: name).appending(component: LockerRoomURLProvider.metadataFileName)
    }
    
    func urlForLockboxUnencryptedContent(name: String) -> URL {
        return urlForLockbox(name: name).appending(component: LockerRoomURLProvider.unencryptedContentFileName)
    }
    
    func urlForLockboxEncryptedContent(name: String) -> URL {
        return urlForLockbox(name: name).appending(component: LockerRoomURLProvider.encryptedContentFileName)
    }
    
    func urlForKey(name: String) -> URL {
        return urlForKeys.appending(component: name)
    }
    
    func urlForKeyFile(name: String) -> URL {
        return urlForKey(name: name).appending(component: LockerRoomURLProvider.lockboxKeyFileName)
    }
    
    func urlForAttachedDevice(name: String) -> URL {
        return URL(filePath: LockerRoomURLProvider.devicePathComponent).appending(component: name)
    }
    
    func urlForMountedVolume(name: String) -> URL {
        return URL(filePath: LockerRoomURLProvider.volumesPathComponent).appending(component: name)
    }
}

