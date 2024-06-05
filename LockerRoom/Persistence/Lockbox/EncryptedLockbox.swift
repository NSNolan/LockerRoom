//
//  EncryptedLockbox.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

import os.log

struct EncryptedLockbox {
    
    struct Metadata: LockboxMetadata {
        let id: UUID
        let name: String
        let size: Int
        let isEncrypted: Bool
        let isExternal: Bool
        let encryptedSymmetricKeysBySerialNumber: [UInt32:Data]
        let encryptionLockboxKeys: [LockboxKey]
        
        var description: String {
            return "[UnencryptedLockbox.Metadata] ID: \(id), Name: \(name), Size: \(size), IsEncrypted: \(isEncrypted), IsExternal: \(isExternal), EncryptedSymmetricKeysBySerialNumber: \(encryptedSymmetricKeysBySerialNumber), EncryptionLockboxKeys: \(encryptionLockboxKeys)"
        }
    }
    
    let metadata: Metadata
    let inputStream: InputStream
    let outputStream: OutputStream
        
    private init(id: UUID, name: String, size: Int, isExternal: Bool, encryptedSymmetricKeysBySerialNumber: [UInt32:Data], encryptionLockboxKeys: [LockboxKey], inputStream: InputStream, outputStream: OutputStream) {
        self.metadata = Metadata(
            id: id,
            name: name,
            size: size,
            isEncrypted: true,
            isExternal: isExternal,
            encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber,
            encryptionLockboxKeys: encryptionLockboxKeys
        )
        self.inputStream = inputStream
        self.outputStream = outputStream
    }
    
    static func create(id: UUID, name: String, size: Int, isExternal: Bool, encryptedSymmetricKeysBySerialNumber: [UInt32:Data], encryptionLockboxKeys: [LockboxKey], lockerRoomExternalDiskDiscovery: LockerRoomExternalDiskDiscovering, lockerRoomStore: LockerRoomStoring) -> EncryptedLockbox? {
        guard size > 0 else {
            Logger.persistence.error("Encrypted lockbox failed to create emtpy sized lockbox \(name)")
            return nil
        }
        
        guard let streams = streams(id: id, name: name, isExternal: isExternal, lockerRoomExternalDiskDiscovery: lockerRoomExternalDiskDiscovery, lockerRoomStore: lockerRoomStore) else {
            Logger.persistence.error("Encrypted lockbox failed to create input/output streams for \(name)")
            return nil
        }
        
        let lockbox = EncryptedLockbox(id: id, name: name, size: size, isExternal: isExternal, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionLockboxKeys: encryptionLockboxKeys, inputStream: streams.input, outputStream: streams.output)
        
        guard lockerRoomStore.writeEncryptedLockboxMetadata(lockbox.metadata) else {
            Logger.persistence.error("Encrypted lockbox failed to write lockbox metadata for \(name)")
            return nil
        }
        
        Logger.persistence.log("Encrypted lockbox created \(name)")
        
        return lockbox
    }
    
    static func create(from lockbox: LockerRoomLockbox, lockerRoomExternalDiskDiscovery: LockerRoomExternalDiskDiscovering, lockerRoomStore: LockerRoomStoring) -> EncryptedLockbox? {
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
        let encryptionLockboxKeys = metadata.encryptionLockboxKeys
        
        guard let streams = streams(id: id, name: name, isExternal: isExternal, lockerRoomExternalDiskDiscovery: lockerRoomExternalDiskDiscovery, lockerRoomStore: lockerRoomStore) else {
            Logger.persistence.error("Encrypted lockbox failed to create input and output streams for lockbox \(name)")
            return nil
        }

        return EncryptedLockbox(id: id, name: name, size: size, isExternal: isExternal, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionLockboxKeys: encryptionLockboxKeys, inputStream: streams.input, outputStream: streams.output)
    }
    
    static func destroy(name: String, lockerRoomStore: LockerRoomStoring) -> Bool {
        guard lockerRoomStore.removeLockbox(name: name) else {
            Logger.persistence.error("Encrypted lockbox failed to remove \(name)")
            return false
        }
        
        return true
    }
    
    private static func streams(id: UUID, name: String, isExternal: Bool, lockerRoomExternalDiskDiscovery: LockerRoomExternalDiskDiscovering, lockerRoomStore: LockerRoomStoring) -> (input: InputStream, output: OutputStream)? {
        let inputURL = lockerRoomStore.lockerRoomURLProvider.urlForLockboxEncryptedContent(name: name)
        let inputPath = inputURL.path(percentEncoded: false)
        
        guard let inputStream = InputStream(fileAtPath: inputPath) else {
            Logger.persistence.error("Encrypted lockbox failed to create input stream for \(name) at path \(inputPath)")
            return nil
        }
        
        let outputURL: URL
        if isExternal {
            guard let externalDisk = lockerRoomExternalDiskDiscovery.disksByID[id] else {
                Logger.persistence.error("Encrypted lockbox failed to create output stream for external disk \(name) with id \(id)")
                return nil
            }
            outputURL = lockerRoomStore.lockerRoomURLProvider.urlForAttachedDevice(name: externalDisk.bsdName)
        } else {
            outputURL = lockerRoomStore.lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name)
        }
        let outputPath = outputURL.path(percentEncoded: false)
        
        guard let outputStream = OutputStream(toFileAtPath: outputPath, append: false) else {
            Logger.persistence.error("Encrypted lockbox failed to create output stream for \(name) to path \(outputPath)")
            return nil
        }
        
        return (inputStream, outputStream)
    }
}
