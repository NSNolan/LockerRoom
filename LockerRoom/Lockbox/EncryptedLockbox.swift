//
//  EncryptedLockbox.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

class EncryptedLockbox {
    let name: String
    let size: Int
    let encryptedContent: Data
    let encryptedSymmetricKey: Data
        
    private init(name: String, size: Int, encryptedContent: Data, encryptedSymmetricKey: Data) {
        self.name = name
        self.size = size
        self.encryptedContent = encryptedContent
        self.encryptedSymmetricKey = encryptedSymmetricKey
    }
    
    static func create(name: String, size: Int = 0, encryptedContent: Data, encryptedSymmetricKey: Data, lockerRoomStore: LockerRoomStoring) -> EncryptedLockbox? {
        let actualSize = size > 0 ? size : (encryptedContent.count / (1024 * 1024)) // Convert to MBs
        guard actualSize > 0 else {
            print("[Error] Encrypted lockbox failed to create emtpy lockbox \(name)")
            _ = destroy(name: name, lockerRoomStore: lockerRoomStore)
            return nil
        }
        
        guard !lockerRoomStore.lockboxExists(name: name) else {
            print("[Error] Encrypted lockbox failed to add \(name) at existing path")
            return nil
        }
        
        guard lockerRoomStore.writeToLockbox(encryptedContent, name: name, fileType: .encryptedContentFileType) else {
            print("[Error] Encrypted lockbox failed to write encrypted content for \(name)")
            _ = destroy(name: name, lockerRoomStore: lockerRoomStore)
            return nil
        }
        
        guard lockerRoomStore.writeToLockbox(encryptedSymmetricKey, name: name, fileType: .encryptedSymmetricKeyFileType) else {
            print("[Error] Encrypted lockbox failed to write encrypted symmetric key for \(name)")
            _ = destroy(name: name, lockerRoomStore: lockerRoomStore)
            return nil
        }
        
        return EncryptedLockbox(name: name, size: actualSize, encryptedContent: encryptedContent, encryptedSymmetricKey: encryptedSymmetricKey)
    }
    
    static func create(from encryptedLockboxMetadata: LockerRoomLockboxMetadata, lockerRoomStore: LockerRoomStoring) -> EncryptedLockbox? {
        let isEncrypted = encryptedLockboxMetadata.isEncrypted
        let name = encryptedLockboxMetadata.name
        let size = encryptedLockboxMetadata.size
        
        guard isEncrypted else {
            print("[Error] Encrypted lockback failed to create from unencrypted lockbox metadata")
            return nil
        }
        
        guard let encryptedContent = lockerRoomStore.readFromLockbox(name: name, fileType: .encryptedContentFileType) else {
            print("[Error] Encrypted lockbox failed to read encrypted content for \(name)")
            return nil
        }
        
        guard let encryptedSymmetricKey = lockerRoomStore.readFromLockbox(name: name, fileType: .encryptedSymmetricKeyFileType) else {
            print("[Error] Encrypted lockbox failed to read encrypted symmetric key for \(name)")
            return nil
        }

        return EncryptedLockbox(name: name, size: size, encryptedContent: encryptedContent, encryptedSymmetricKey: encryptedSymmetricKey)
    }
    
    static func destroy(name: String, lockerRoomStore: LockerRoomStoring) -> Bool {
        guard !name.isEmpty else {
            print("[Error] Encrypted lockbox failed to destory lockbox without a name")
            return false
        }
        
        guard lockerRoomStore.lockboxExists(name: name) else {
            print("[Error] Encrypted lockbox failed to destroy encrypted non-existing \(name)")
            return false
        }
        
        guard lockerRoomStore.removeLockbox(name: name) else {
            print("[Error] Encrypted lockbox failed to remove \(name)")
            return false
        }
        
        return true
    }
}