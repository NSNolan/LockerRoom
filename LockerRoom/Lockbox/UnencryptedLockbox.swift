//
//  UnencryptedLockbox.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

struct UnencryptedLockbox: Lockbox {
    let name: String
    let size: Int
    let isEncrypted: Bool
    let unencryptedContent: Data
    
    private init(name: String, size: Int, unencryptedContent: Data) {
        self.name = name
        self.size = size
        self.isEncrypted = false
        self.unencryptedContent = unencryptedContent
    }
    
    static func create(name: String, size: Int = 0, unencryptedContent: Data = Data(), lockerRoomStore: LockerRoomStoring) -> UnencryptedLockbox? {
        let diskImage = LockerRoomDiskImage() // TODO: It is very awkward that the disk image routines create, attach and detach are called within create/destroy
        
        if unencryptedContent.isEmpty {
            print("[Default] Unencrypted lockbox creating \(name) for new content")
            
            guard size > 0 else {
                print("[Error] Unencrypted lockbox failed to create emtpy sized lockbox \(name)")
                return nil
            }
            
            guard lockerRoomStore.addLockbox(name: name) else {
                print("[Error] Unencrypted lockbox failed to add \(name)")
                return nil
            }

            guard diskImage.create(name: name, size: size) else {
                print("[Error] Unencrypted lockbox failed to attach to disk image \(name)")
                return nil
            }
            
            guard let newUnencryptedContent = lockerRoomStore.readUnencryptedLockbox(name: name) else {
                print("[Error] Unencrypted lockbox failed to read \(name) for new content")
                return nil
            }
            
            guard diskImage.attach(name: name) else {
                print("[Error] Unencrypted lockbox failed to attach \(name) as disk image")
                return nil
            }
            
            return UnencryptedLockbox(name: name, size: size, unencryptedContent: newUnencryptedContent)
        } else {
            print("[Default] Unencrypted lockbox creating \(name) from existing content")
            
            let unencryptedContentSize = unencryptedContent.count / (1024 * 1024) // Convert to MBs
            guard unencryptedContentSize > 0 else {
                print("[Error] Unencrypted lockbox failed to create from emtpy sized lockbox \(name)")
                return nil
            }
            
            guard !lockerRoomStore.lockboxExists(name: name) else {
                print("[Error] Unencrypted lockback failed to add \(name) at existing path")
                return nil
            }
            
            guard lockerRoomStore.writeUnencryptedLockbox(unencryptedContent, name: name) else {
                print("[Error] Unencrypted lockbox failed to add \(name) from data \(unencryptedContent)")
                return nil
            }
            
            guard diskImage.attach(name: name) else {
                print("[Error] Unencrypted lockbox failed to attach to disk image \(name)")
                return nil
            }
            
            return UnencryptedLockbox(name: name, size: unencryptedContentSize, unencryptedContent: unencryptedContent)
        }
    }
    
    static func create(from unencryptedLockboxMetadata: LockerRoomLockboxMetadata, lockerRoomStore: LockerRoomStoring) -> UnencryptedLockbox? {
        let diskImage = LockerRoomDiskImage()
        let isEncrypted = unencryptedLockboxMetadata.isEncrypted
        let name = unencryptedLockboxMetadata.name
        let size = unencryptedLockboxMetadata.size
        
        guard !isEncrypted else {
            print("[Error] Unencrypted lockback failed to create \(name) with encrypted lockbox metadata")
            return nil
        }
        
        guard let unencryptedContent = lockerRoomStore.readUnencryptedLockbox(name: name) else {
            print("[Error] Unencrypted lockbox failed to read \(name) for unencrypted content")
            return nil
        }
        
        
        _ = diskImage.attach(name: name) // Not fatal
        
        return UnencryptedLockbox(name: name, size: size, unencryptedContent: unencryptedContent)
    }
    
    static func destroy(name: String, lockerRoomStore: LockerRoomStoring) -> Bool {
        let diskImage = LockerRoomDiskImage()
        _ = diskImage.detach(name: name) // Not fatal
        
        guard lockerRoomStore.removeLockbox(name: name) else {
            print("[Error] Unencrypted lockbox failed to remove \(name)")
            return false
        }
        
        return true
    }
}
