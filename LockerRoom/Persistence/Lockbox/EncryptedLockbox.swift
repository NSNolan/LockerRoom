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
    
    let metadata: Metadata
    let inputStream: InputStream
    let outputStream: OutputStream
        
    private init(name: String, size: Int, encryptedSymmetricKeysBySerialNumber: [UInt32:Data], encryptionLockboxKeys: [LockboxKey], inputStream: InputStream, outputStream: OutputStream) {
        self.metadata = Metadata(
            name: name,
            size: size,
            isEncrypted: true,
            encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber,
            encryptionLockboxKeys: encryptionLockboxKeys
        )
        self.inputStream = inputStream
        self.outputStream = outputStream
    }
    
    static func create(name: String, size: Int, encryptedSymmetricKeysBySerialNumber: [UInt32:Data], encryptionLockboxKeys: [LockboxKey], lockerRoomStore: LockerRoomStoring) -> EncryptedLockbox? {
        guard !lockerRoomStore.lockboxExists(name: name) else {
            print("[Error] Encrypted lockbox failed to add \(name) at existing path")
            return nil
        }
        
        guard size > 0 else {
            print("[Error] Encrypted lockbox failed to create emtpy sized lockbox \(name)")
            return nil
        }
        
        guard let streams = streams(forName: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Encrypted lockbox failed to create input/output streams for \(name)")
            return nil
        }
        
        let lockbox = EncryptedLockbox(name: name, size: size, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionLockboxKeys: encryptionLockboxKeys, inputStream: streams.input, outputStream: streams.output)
        
        guard lockerRoomStore.writeEncryptedLockboxMetadata(lockbox.metadata) else {
            print("[Error] Encrypted lockbox failed to write lockbox metadata for \(name)")
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
        
        guard let streams = streams(forName: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Encrypted lockbox failed to create input and output streams for lockbox \(name)")
            return nil
        }
        
        guard let metadata = lockerRoomStore.readEncryptedLockboxMetadata(name: name) else {
            print("[Error] Encrypted lockbox failed to read metadata \(name)")
            return nil
        }
        
        let size = metadata.size
        let encryptedSymmetricKeysBySerialNumber = metadata.encryptedSymmetricKeysBySerialNumber
        let encryptionLockboxKeys = metadata.encryptionLockboxKeys

        return EncryptedLockbox(name: name, size: size, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionLockboxKeys: encryptionLockboxKeys, inputStream: streams.input, outputStream: streams.output)
    }
    
    static func destroy(name: String, lockerRoomStore: LockerRoomStoring) -> Bool {
        guard lockerRoomStore.removeLockbox(name: name) else {
            print("[Error] Encrypted lockbox failed to remove \(name)")
            return false
        }
        
        return true
    }
    
    private static func streams(forName name: String, lockerRoomStore: LockerRoomStoring) -> (input: InputStream, output: OutputStream)? {
        let inputURL = lockerRoomStore.lockerRoomURLProvider.urlForLockboxEncryptedContent(name: name)
        let inputPath = inputURL.path(percentEncoded: false)
        
        guard let inputStream = InputStream(fileAtPath: inputPath) else {
            print("[Error] Encrypted lockbox failed to create input stream at path \(name)")
            return nil
        }
        
        let outputURL = lockerRoomStore.lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name)
        let outputPath = outputURL.path(percentEncoded: false)
        
        guard let outputStream = OutputStream(toFileAtPath: outputPath, append: false) else {
            print("[Error] Encrypted lockbox failed to create output stream at path \(name)")
            return nil
        }
        
        return (inputStream, outputStream)
    }
}
