//
//  UnencryptedLockbox.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

struct UnencryptedLockbox {
    
    struct Metadata: LockboxMetadata {
        let name: String
        let size: Int
        let isEncrypted: Bool
    }
    
    let content: Data
    let metadata: Metadata
    
    private init(name: String, size: Int, content: Data) {
        self.content = content
        self.metadata = Metadata(name: name, size: size, isEncrypted: false)
    }
    
    static func create(name: String, size: Int, unencryptedContent: Data = Data(), lockerRoomStore: LockerRoomStoring) -> UnencryptedLockbox? {
        if unencryptedContent.isEmpty {
            print("[Default] Unencrypted lockbox creating \(name) for new content")
            
            guard size > 0 else {
                print("[Error] Unencrypted lockbox failed to create emtpy sized lockbox \(name)")
                return nil
            }
            
            guard LockerRoomDiskImage().create(name: name, size: size) else {
                print("[Error] Unencrypted lockbox failed to create disk image \(name)")
                return nil
            }
            
            guard let newUnencryptedContent = lockerRoomStore.readUnencryptedLockboxContent(name: name) else {
                print("[Error] Unencrypted lockbox failed to read \(name) for new content")
                return nil
            }
            
            let lockbox = UnencryptedLockbox(name: name, size: size, content: newUnencryptedContent)
            
            guard lockerRoomStore.writeUnencryptedLockbox(lockbox, name: name) else {
                print("[Error] Unencrypted lockbox failed to write \(name) for new content")
                return nil
            }
            
            return lockbox
        } else {
            print("[Default] Unencrypted lockbox creating \(name) from existing content")
            
            guard !lockerRoomStore.lockboxExists(name: name) else {
                print("[Error] Unencrypted lockback failed to add \(name) at existing path")
                return nil
            }
            
            guard size > 0 else {
                print("[Error] Unencrypted lockbox failed to create from emtpy sized lockbox \(name)")
                return nil
            }
            
            let lockbox = UnencryptedLockbox(name: name, size: size, content: unencryptedContent)
            
            guard lockerRoomStore.writeUnencryptedLockbox(lockbox, name: name) else {
                print("[Error] Unencrypted lockbox failed to write \(name)")
                return nil
            }
            
            return lockbox
        }
    }
    
    static func create(from lockbox: LockerRoomLockbox, lockerRoomStore: LockerRoomStoring) -> UnencryptedLockbox? {
        let isEncrypted = lockbox.isEncrypted
        let name = lockbox.name
        
        guard !isEncrypted else {
            print("[Error] Unencrypted lockback failed to create \(name) from encrypted lockbox")
            return nil
        }
        
        guard let unencryptedContent = lockerRoomStore.readUnencryptedLockboxContent(name: name) else {
            print("[Error] Unencrypted lockbox failed to read \(name) for unencrypted content")
            return nil
        }
        
        guard let metadata = lockerRoomStore.readUnencryptedLockboxMetadata(name: name) else {
            print("[Error] Unencrypted lockbox failed to read metadata \(name)")
            return nil
        }
        
        return UnencryptedLockbox(name: name, size: metadata.size, content: unencryptedContent)
    }
    
    static func destroy(name: String, lockerRoomStore: LockerRoomStoring) -> Bool {
        guard lockerRoomStore.removeLockbox(name: name) else {
            print("[Error] Unencrypted lockbox failed to remove \(name)")
            return false
        }
        
        return true
    }
}
