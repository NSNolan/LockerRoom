//
//  UnencryptedLockbox.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

import os.log

struct UnencryptedLockbox {
    
    struct Metadata: LockboxMetadata {
        let name: String
        let size: Int
        let isEncrypted: Bool
        
        var description: String {
            return "[UnencryptedLockbox.Metadata] Name: \(name), Size: \(size), IsEncrypted: \(isEncrypted)"
        }
    }
    
    let metadata: Metadata
    let inputStream: InputStream
    let outputStream: OutputStream
    
    private init(name: String, size: Int, inputStream: InputStream, outputStream: OutputStream) {
        self.metadata = Metadata(name: name, size: size, isEncrypted: false)
        self.inputStream = inputStream
        self.outputStream = outputStream
    }
    
    static func create(name: String, size: Int, lockerRoomDefaults: LockerRoomDefaulting, lockerRoomDiskImage: LockerRoomDiskImaging, lockerRoomService: LockerRoomService, lockerRoomStore: LockerRoomStoring) -> UnencryptedLockbox? {
        guard size > 0 else {
            Logger.persistence.error("Unencrypted lockbox failed to create emtpy sized lockbox \(name)")
            return nil
        }
        
        if lockerRoomDefaults.serviceEnabled {
            guard lockerRoomService.createDiskImage(name: name, size: size, rootURL: lockerRoomStore.lockerRoomURLProvider.rootURL) else {
                Logger.persistence.error("Unencrypted lockbox failed to create disk image \(name)")
                return nil
            }
        } else {
            guard lockerRoomDiskImage.create(name: name, size: size) else {
                Logger.persistence.error("Unencrypted lockbox failed to create disk image \(name)")
                return nil
            }
        }
        
        guard let streams = streams(forName: name, lockerRoomStore: lockerRoomStore) else {
            Logger.persistence.error("Unencrypted lockbox failed to create input/output streams for \(name)")
            return nil
        }
        
        let lockbox = UnencryptedLockbox(name: name, size: size, inputStream: streams.input, outputStream: streams.output)
        
        guard lockerRoomStore.writeUnencryptedLockboxMetadata(lockbox.metadata) else {
            Logger.persistence.error("Unencrypted lockbox failed to write lockbox metadata for \(name)")
            return nil
        }
        
        Logger.persistence.log("Unencrypted lockbox created \(name)")
        
        return lockbox
    }
    
    static func create(from lockbox: LockerRoomLockbox, lockerRoomStore: LockerRoomStoring) -> UnencryptedLockbox? {
        let isEncrypted = lockbox.isEncrypted
        let name = lockbox.name
        
        guard !isEncrypted else {
            Logger.persistence.error("Unencrypted lockback failed to create \(name) from encrypted lockbox")
            return nil
        }
        
        guard let streams = streams(forName: name, lockerRoomStore: lockerRoomStore) else {
            Logger.persistence.error("Unencrypted lockbox failed to create input and output streams for \(name)")
            return nil
        }
        
        guard let metadata = lockerRoomStore.readUnencryptedLockboxMetadata(name: name) else {
            Logger.persistence.error("Unencrypted lockbox failed to read metadata \(name)")
            return nil
        }
        
        return UnencryptedLockbox(name: name, size: metadata.size, inputStream: streams.input, outputStream: streams.output)
    }
    
    static func destroy(name: String, lockerRoomStore: LockerRoomStoring) -> Bool {
        guard lockerRoomStore.removeLockbox(name: name) else {
            Logger.persistence.error("Unencrypted lockbox failed to remove \(name)")
            return false
        }
        
        return true
    }
    
    private static func streams(forName name: String, lockerRoomStore: LockerRoomStoring) -> (input: InputStream, output: OutputStream)? {
        let inputURL = lockerRoomStore.lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name)
        let inputPath = inputURL.path(percentEncoded: false)
        
        guard let inputStream = InputStream(fileAtPath: inputPath) else {
            Logger.persistence.error("Unencrypted lockbox failed to create input stream at path \(name)")
            return nil
        }
        
        let outputURL = lockerRoomStore.lockerRoomURLProvider.urlForLockboxEncryptedContent(name: name)
        let outputPath = outputURL.path(percentEncoded: false)
        
        guard let outputStream = OutputStream(toFileAtPath: outputPath, append: false) else {
            Logger.persistence.error("Unencrypted lockbox failed to create output stream at path \(name)")
            return nil
        }
        
        return (inputStream, outputStream)
    }
}
