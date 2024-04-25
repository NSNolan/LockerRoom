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
    
    let inputStream: InputStream
    let outputStream: OutputStream
    let metadata: Metadata
    
    private init(inputStream: InputStream, outputStream: OutputStream, name: String, size: Int) {
        self.inputStream = inputStream
        self.outputStream = outputStream
        self.metadata = Metadata(name: name, size: size, isEncrypted: false)
    }
    
    static func create(name: String, size: Int, lockerRoomDiskImage: LockerRoomDiskImaging, lockerRoomStore: LockerRoomStoring) -> UnencryptedLockbox? {
        guard size > 0 else {
            print("[Error] Unencrypted lockbox failed to create emtpy sized lockbox \(name)")
            return nil
        }
        
        print("[Default] Unencrypted lockbox creating \(name) for new content")
        
        guard lockerRoomDiskImage.create(name: name, size: size) else {
            print("[Error] Unencrypted lockbox failed to create disk image \(name)")
            return nil
        }
        
        guard let streams = streams(forName: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Unencrypted lockbox failed to create input/output streams for \(name)")
            return nil
        }
        
        let lockbox = UnencryptedLockbox(inputStream: streams.input, outputStream: streams.output, name: name, size: size)
        
        guard lockerRoomStore.writeUnencryptedLockboxMetadata(lockbox.metadata) else {
            print("[Error] Unencrypted lockbox failed to write lockbox metadata for \(name)")
            return nil
        }
        
        return lockbox
    }
    
    static func create(from lockbox: LockerRoomLockbox, lockerRoomStore: LockerRoomStoring) -> UnencryptedLockbox? {
        let isEncrypted = lockbox.isEncrypted
        let name = lockbox.name
        
        guard !isEncrypted else {
            print("[Error] Unencrypted lockback failed to create \(name) from encrypted lockbox")
            return nil
        }
        
        guard let streams = streams(forName: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Unencrypted lockbox failed to create input and output streams for \(name)")
            return nil
        }
        
        guard let metadata = lockerRoomStore.readUnencryptedLockboxMetadata(name: name) else {
            print("[Error] Unencrypted lockbox failed to read metadata \(name)")
            return nil
        }
        
        return UnencryptedLockbox(inputStream: streams.input, outputStream: streams.output, name: name, size: metadata.size)
    }
    
    static func destroy(name: String, lockerRoomStore: LockerRoomStoring) -> Bool {
        guard lockerRoomStore.removeLockbox(name: name) else {
            print("[Error] Unencrypted lockbox failed to remove \(name)")
            return false
        }
        
        return true
    }
    
    private static func streams(forName name: String, lockerRoomStore: LockerRoomStoring) -> (input: InputStream, output: OutputStream)? {
        let inputURL = lockerRoomStore.lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name)
        let inputPath = inputURL.path(percentEncoded: false)
        
        guard let inputStream = InputStream(fileAtPath: inputPath) else {
            print("[Error] Unencrypted lockbox failed to create input stream at path \(name)")
            return nil
        }
        
        let outputURL = lockerRoomStore.lockerRoomURLProvider.urlForLockboxEncryptedContent(name: name)
        let outputPath = outputURL.path(percentEncoded: false)
        
        guard let outputStream = OutputStream(toFileAtPath: outputPath, append: false) else {
            print("[Error] Unencrypted lockbox failed to create output stream at path \(name)")
            return nil
        }
        
        return (inputStream, outputStream)
    }
}
