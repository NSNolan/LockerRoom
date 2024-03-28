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
    
    internal let lockerRoomStore: LockerRoomStoring
    
    private init(name: String, size: Int, unencryptedContent: Data, lockerRoomStore: LockerRoomStoring) {
        self.name = name
        self.size = size
        self.unencryptedContent = unencryptedContent
        self.lockerRoomStore = lockerRoomStore
    }
    
    static func create(name: String, size: Int = 0, unencryptedContent: Data = Data(), lockerRoomStore: LockerRoomStoring) -> UnencryptedLockbox? {
        let actualSize = size > 0 ? size : (unencryptedContent.count / (1024 * 1024)) // Convert to MBs
        guard actualSize > 0 else {
            print("[Error] Unencrypted lockbox failed to create emtpy lockbox \(name)")
            _ = destroy(name: name, lockerRoomStore: lockerRoomStore)
            return nil
        }
        
        let diskImage = LockerRoomDiskImage()
        
        if !unencryptedContent.isEmpty {
            print("[Default] Unencrypted lockbox is ignoring create size in favor or existing data")
            guard lockerRoomStore.writeToLockbox(data: unencryptedContent, name: name, fileType: .unencryptedContentFileType) else {
                print("[Error] Unencrypted lockbox failed to add \(name) from data \(unencryptedContent)")
                _ = destroy(name: name, lockerRoomStore: lockerRoomStore)
                return nil
            }
            
            guard diskImage.attach(name: name) else {
                print("[Error] Unencrypted lockbox failed to attach to disk image \(name)")
                _ = destroy(name: name, lockerRoomStore: lockerRoomStore)
                return nil
            }
            
            return UnencryptedLockbox(name: name, size: actualSize, unencryptedContent: unencryptedContent, lockerRoomStore: lockerRoomStore)
        }
        
        guard lockerRoomStore.addLockbox(name: name) else {
            print("[Error] Unencrypted lockbox failed to add \(name)")
            _ = destroy(name: name, lockerRoomStore: lockerRoomStore)
            return nil
        }

        guard diskImage.create(name: name, size: size) else {
            print("[Error] Unencrypted lockbox failed to attach to disk image \(name)")
            _ = destroy(name: name, lockerRoomStore: lockerRoomStore)
            return nil
        }
        
        guard let newUnencryptedContent = lockerRoomStore.readFromLockbox(name: name, fileType: .unencryptedContentFileType) else {
            print("[Error] Unencrypted lockbox failed to read new unencrypted content for \(name)")
            _ = destroy(name: name, lockerRoomStore: lockerRoomStore)
            return nil
        }
        
        guard diskImage.attach(name: name) else {
            print("[Error] Unencrypted lockbox failed to attach to disk image \(name)")
            _ = destroy(name: name, lockerRoomStore: lockerRoomStore)
            return nil
        }
        
        return UnencryptedLockbox(name: name, size: actualSize, unencryptedContent: newUnencryptedContent, lockerRoomStore: lockerRoomStore)
    }
    
    static func create(from unencryptedLockboxMetadata: LockerRoomLockboxMetadata, lockerRoomStore: LockerRoomStoring) -> UnencryptedLockbox? {
        guard !unencryptedLockboxMetadata.isEncrypted else {
            print("[Error] Unencrypted lockback failed to create from encrypted lockbox metadata")
            return nil
        }
        
        let name = unencryptedLockboxMetadata.name
        let size = unencryptedLockboxMetadata.size
        
        guard let unencryptedContent = lockerRoomStore.readFromLockbox(name: name, fileType: .unencryptedContentFileType) else {
            print("[Error] Unencrypted lockbox failed to read unencrypted content for \(name)")
            return nil
        }
        
        return UnencryptedLockbox(name: name, size: size, unencryptedContent: unencryptedContent, lockerRoomStore: lockerRoomStore)
    }
    
    static func destroy(name: String, lockerRoomStore: LockerRoomStoring) -> Bool {        
        guard !name.isEmpty else {
            print("[Error] Unencrypted lockbox failed to destory lockbox without a name")
            return false
        }
        
        _ = LockerRoomDiskImage().detach(name: name) // Not fatal
        
        if lockerRoomStore.removeLockbox(name: name) {
            return true
        } else {
            print("[Error] Unencrypted lockbox failed to remove \(name)")
            return false
        }
    }

}
