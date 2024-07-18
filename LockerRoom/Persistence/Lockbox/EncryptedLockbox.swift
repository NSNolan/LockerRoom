//
//  EncryptedLockbox.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

import os.log

struct EncryptedLockbox: LockboxStreaming {
    
    struct Metadata: LockboxMetadata {
        let id: UUID
        let name: String
        let size: Int
        let isEncrypted: Bool
        let isExternal: Bool
        let encryptedSymmetricKeysBySerialNumber: [UInt32:Data]
        let encryptionComponents: LockboxCryptorComponents?
        let encryptionLockboxKeys: [LockboxKey]
        
        var description: String {
            return "[UnencryptedLockbox.Metadata] ID: \(id), Name: \(name), Size: \(size), IsEncrypted: \(isEncrypted), IsExternal: \(isExternal), EncryptedSymmetricKeysBySerialNumber: \(encryptedSymmetricKeysBySerialNumber), EncryptionComponents: \(encryptionComponents?.count ?? 0) EncryptionLockboxKeys: \(encryptionLockboxKeys)"
        }
    }
    
    let metadata: Metadata
    let inputStream: InputStream
    let outputStream: OutputStream
        
    private init(id: UUID, name: String, size: Int, isExternal: Bool, encryptedSymmetricKeysBySerialNumber: [UInt32:Data], encryptionComponents: LockboxCryptorComponents?, encryptionLockboxKeys: [LockboxKey], inputStream: InputStream, outputStream: OutputStream) {
        self.metadata = Metadata(
            id: id,
            name: name,
            size: size,
            isEncrypted: true,
            isExternal: isExternal,
            encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber,
            encryptionComponents: encryptionComponents,
            encryptionLockboxKeys: encryptionLockboxKeys
        )
        self.inputStream = inputStream
        self.outputStream = outputStream
    }
    
    static func create(id: UUID, name: String, size: Int, isExternal: Bool, encryptedSymmetricKeysBySerialNumber: [UInt32:Data], encryptionComponents: LockboxCryptorComponents?, encryptionLockboxKeys: [LockboxKey], lockerRoomStore: LockerRoomStoring) -> EncryptedLockbox? {
        guard size > 0 else {
            Logger.persistence.error("Encrypted lockbox failed to create emtpy sized lockbox \(name)")
            return nil
        }
        
        guard let streams = streams(id: id, name: name, isEncrypted: true, isExternal: isExternal, lockerRoomStore: lockerRoomStore) else {
            Logger.persistence.error("Encrypted lockbox failed to create input/output streams for \(name)")
            return nil
        }
        
        let lockbox = EncryptedLockbox(id: id, name: name, size: size, isExternal: isExternal, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionComponents: encryptionComponents, encryptionLockboxKeys: encryptionLockboxKeys, inputStream: streams.input, outputStream: streams.output)
        
        guard lockerRoomStore.writeEncryptedLockboxMetadata(lockbox.metadata) else {
            Logger.persistence.error("Encrypted lockbox failed to write lockbox metadata for \(name)")
            return nil
        }
        
        Logger.persistence.log("Encrypted lockbox created \(name)")
        
        return lockbox
    }
    
    static func create(from lockbox: LockerRoomLockbox, lockerRoomStore: LockerRoomStoring) -> EncryptedLockbox? {
        let name = lockbox.name
        let isEncrypted = lockbox.isEncrypted
        
        guard isEncrypted else {
            Logger.persistence.error("Encrypted lockback failed to create \(name) from unencrypted lockbox")
            return nil
        }
        
        guard let metadata = lockerRoomStore.readEncryptedLockboxMetadata(name: name) else {
            Logger.persistence.error("Encrypted lockbox failed to read metadata \(name)")
            return nil
        }
        
        let id = metadata.id
        let size = metadata.size
        let isExternal = metadata.isExternal
        let encryptedSymmetricKeysBySerialNumber = metadata.encryptedSymmetricKeysBySerialNumber
        let encryptionComponents = metadata.encryptionComponents
        let encryptionLockboxKeys = metadata.encryptionLockboxKeys
        
        guard let streams = streams(id: id, name: name, isEncrypted: isEncrypted, isExternal: isExternal, lockerRoomStore: lockerRoomStore) else {
            Logger.persistence.error("Encrypted lockbox failed to create input and output streams for lockbox \(name)")
            return nil
        }

        return EncryptedLockbox(id: id, name: name, size: size, isExternal: isExternal, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionComponents: encryptionComponents, encryptionLockboxKeys: encryptionLockboxKeys, inputStream: streams.input, outputStream: streams.output)
    }
    
    static func destroy(name: String, lockerRoomStore: LockerRoomStoring) -> Bool {
        guard lockerRoomStore.removeLockbox(name: name) else {
            Logger.persistence.error("Encrypted lockbox failed to remove \(name)")
            return false
        }
        
        return true
    }
}
