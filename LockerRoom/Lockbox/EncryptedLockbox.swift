//
//  EncryptedLockbox.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

struct EncryptedLockbox {
    
    struct Metadata: LockboxMetadata {
        let name: String
        let size: Int
        let isEncrypted: Bool
        let encryptedSymmetricKeysBySerialNumber: [UInt32:Data]
        let encryptionLockboxKeys: [LockboxKey]
    }
    
    let content: Data
    let metadata: Metadata
        
    private init(name: String, size: Int, content: Data, encryptedSymmetricKeysBySerialNumber: [UInt32:Data], encryptionLockboxKeys: [LockboxKey]) {
        self.content = content
        self.metadata = Metadata(
            name: name,
            size: size,
            isEncrypted: true,
            encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber,
            encryptionLockboxKeys: encryptionLockboxKeys
        )
    }
    
    static func create(name: String, size: Int, encryptedContent: Data, encryptedSymmetricKeysBySerialNumber: [UInt32:Data], encryptionLockboxKeys: [LockboxKey], lockerRoomStore: LockerRoomStoring) -> EncryptedLockbox? {
        guard !lockerRoomStore.lockboxExists(name: name) else {
            print("[Error] Encrypted lockbox failed to add \(name) at existing path")
            return nil
        }
        
        guard size > 0 else {
            print("[Error] Encrypted lockbox failed to create emtpy sized lockbox \(name)")
            return nil
        }
        
        let lockbox = EncryptedLockbox(name: name, size: size, content: encryptedContent, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionLockboxKeys: encryptionLockboxKeys)
        
        guard lockerRoomStore.writeEncryptedLockbox(lockbox, name: name) else {
            print("[Error] Encrypted lockbox failed to write \(name)")
            return nil
        }
        
        return lockbox
    }
    
    static func create(from lockbox: LockerRoomLockbox, lockerRoomStore: LockerRoomStoring) -> EncryptedLockbox? {
        let isEncrypted = lockbox.isEncrypted
        let name = lockbox.name
        
        guard isEncrypted else {
            print("[Error] Encrypted lockback failed to create \(name) from unencrypted lockbox")
            return nil
        }
        
        guard let encryptedContent = lockerRoomStore.readEncryptedLockboxContent(name: name) else {
            print("[Error] Encrypted lockbox failed to read \(name)")
            return nil
        }
        
        guard let metadata = lockerRoomStore.readEncryptedLockboxMetadata(name: name) else {
            print("[Error] Encrypted lockbox failed to read metadata \(name)")
            return nil
        }
        
        let size = metadata.size
        let encryptedSymmetricKeysBySerialNumber = metadata.encryptedSymmetricKeysBySerialNumber
        let encryptionLockboxKeys = metadata.encryptionLockboxKeys

        return EncryptedLockbox(name: name, size: size, content: encryptedContent, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionLockboxKeys: encryptionLockboxKeys)
    }
    
    static func destroy(name: String, lockerRoomStore: LockerRoomStoring) -> Bool {
        guard lockerRoomStore.removeLockbox(name: name) else {
            print("[Error] Encrypted lockbox failed to remove \(name)")
            return false
        }
        
        return true
    }
}
