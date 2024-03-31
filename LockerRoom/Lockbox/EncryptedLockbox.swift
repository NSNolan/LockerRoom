//
//  EncryptedLockbox.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

class EncryptedLockbox: Lockbox, Codable {
    let name: String
    let size: Int
    let isEncrypted: Bool
    let encryptedContent: Data
    let encryptedSymmetricKeysBySerialNumber: [UInt32:Data]
        
    private init(name: String, size: Int, encryptedContent: Data, encryptedSymmetricKeysBySerialNumber: [UInt32:Data]) {
        self.name = name
        self.size = size
        self.isEncrypted = true
        self.encryptedContent = encryptedContent
        self.encryptedSymmetricKeysBySerialNumber = encryptedSymmetricKeysBySerialNumber
    }
    
    static func create(name: String, size: Int = 0, encryptedContent: Data, encryptedSymmetricKeysBySerialNumber: [UInt32:Data], lockerRoomStore: LockerRoomStoring) -> EncryptedLockbox? {
        guard !lockerRoomStore.lockboxExists(name: name) else {
            print("[Error] Encrypted lockbox failed to add \(name) at existing path")
            return nil
        }
        
        let actualSize = size > 0 ? size : (encryptedContent.count / (1024 * 1024)) // Convert to MBs
        guard actualSize > 0 else {
            print("[Error] Encrypted lockbox failed to create emtpy sized lockbox \(name)")
            return nil
        }
        
        let lockbox = EncryptedLockbox(name: name, size: actualSize, encryptedContent: encryptedContent, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber)
        
        guard lockerRoomStore.writeEncryptedLockbox(lockbox, name: name, fileType: .encryptedLockboxFileType) else {
            print("[Error] Encrypted lockbox failed to write \(name)")
            return nil
        }
        
        return lockbox
    }
    
    static func create(from encryptedLockboxMetadata: LockerRoomLockboxMetadata, lockerRoomStore: LockerRoomStoring) -> EncryptedLockbox? {
        let isEncrypted = encryptedLockboxMetadata.isEncrypted
        let name = encryptedLockboxMetadata.name
        
        guard isEncrypted else {
            print("[Error] Encrypted lockback failed to create \(name) with unencrypted lockbox metadata")
            return nil
        }
        
        guard let encryptedLockbox = lockerRoomStore.readEncryptedLockbox(name: name, fileType: .encryptedLockboxFileType) else {
            print("[Error] Encrypted lockbox failed to read \(name)")
            return nil
        }

        return encryptedLockbox
    }
    
    static func destroy(name: String, lockerRoomStore: LockerRoomStoring) -> Bool {
        guard lockerRoomStore.removeLockbox(name: name) else {
            print("[Error] Encrypted lockbox failed to remove \(name)")
            return false
        }
        
        return true
    }
}
