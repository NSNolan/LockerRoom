//
//  UnencryptedLockbox.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

struct UnencryptedLockbox {
    let name: String
    let size: Int
    let unencryptedContent: Data
    
    internal let lockboxStore: LockboxStoring
    
    private init(name: String, size: Int, unencryptedContent: Data, lockboxStore: LockboxStoring) {
        self.name = name
        self.size = size
        self.unencryptedContent = unencryptedContent
        self.lockboxStore = lockboxStore
    }
    
    static func create(name: String, size: Int = 0, unencryptedContent: Data = Data(), lockboxStore: LockboxStoring) -> UnencryptedLockbox? {
        let actualSize = size > 0 ? size : (unencryptedContent.count / (1024 * 1024)) // Convert to MBs
        guard actualSize > 0 else {
            print("[Error] Unencrypted lockbox failed to create emtpy lockbox \(name)")
            _ = destroy(name: name, lockboxStore: lockboxStore)
            return nil
        }
        
        let diskImage = LockerRoomDiskImage()
        
        if !unencryptedContent.isEmpty {
            print("[Default] Unencrypted lockbox is ignoring create size in favor or existing data")
            guard lockboxStore.writeToLockbox(data: unencryptedContent, name: name, fileType: .unencryptedContentFileType) else {
                print("[Error] Unencrypted lockbox failed to add \(name) from data \(unencryptedContent)")
                _ = destroy(name: name, lockboxStore: lockboxStore)
                return nil
            }
            
            guard diskImage.attach(name: name) else {
                print("[Error] Unencrypted lockbox failed to attach to disk image \(name)")
                _ = destroy(name: name, lockboxStore: lockboxStore)
                return nil
            }
            
            return UnencryptedLockbox(name: name, size: actualSize, unencryptedContent: unencryptedContent, lockboxStore: lockboxStore)
        }
        
        guard lockboxStore.addLockbox(name: name) else {
            print("[Error] Unencrypted lockbox failed to add \(name)")
            _ = destroy(name: name, lockboxStore: lockboxStore)
            return nil
        }

        guard diskImage.create(name: name, size: size) else {
            print("[Error] Unencrypted lockbox failed to attach to disk image \(name)")
            _ = destroy(name: name, lockboxStore: lockboxStore)
            return nil
        }
        
        guard let newUnencryptedContent = lockboxStore.readFromLockbox(name: name, fileType: .unencryptedContentFileType) else {
            print("[Error] Unencrypted lockbox failed to read new unencrypted content for \(name)")
            _ = destroy(name: name, lockboxStore: lockboxStore)
            return nil
        }
        
        guard diskImage.attach(name: name) else {
            print("[Error] Unencrypted lockbox failed to attach to disk image \(name)")
            _ = destroy(name: name, lockboxStore: lockboxStore)
            return nil
        }
        
        return UnencryptedLockbox(name: name, size: actualSize, unencryptedContent: newUnencryptedContent, lockboxStore: lockboxStore)
    }
    
    static func create(from unencryptedLockboxMetadata: LockerRoomLockboxMetadata, lockboxStore: LockboxStoring) -> UnencryptedLockbox? {
        guard !unencryptedLockboxMetadata.isEncrypted else {
            print("[Error] Unencrypted lockback failed to create from encrypted lockbox metadata")
            return nil
        }
        
        let name = unencryptedLockboxMetadata.name
        let size = unencryptedLockboxMetadata.size
        
        guard let unencryptedContent = lockboxStore.readFromLockbox(name: name, fileType: .unencryptedContentFileType) else {
            print("[Error] Unencrypted lockbox failed to read unencrypted content for \(name)")
            return nil
        }
        
        return UnencryptedLockbox(name: name, size: size, unencryptedContent: unencryptedContent, lockboxStore: lockboxStore)
    }
    
    static func destroy(name: String, lockboxStore: LockboxStoring) -> Bool {        
        guard !name.isEmpty else {
            print("[Error] Unencrypted lockbox failed to destory lockbox without a name")
            return false
        }
        
        _ = LockerRoomDiskImage().detach(name: name) // Not fatal
        
        if lockboxStore.removeLockbox(name: name) {
            return true
        } else {
            print("[Error] Unencrypted lockbox failed to remove \(name)")
            return false
        }
    }

}
