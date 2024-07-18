//
//  UnencryptedLockbox.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

import os.log

struct UnencryptedLockbox: LockboxStreaming {
    
    struct Metadata: LockboxMetadata {
        let id: UUID
        let name: String
        let size: Int
        let isEncrypted: Bool
        let isExternal: Bool
        
        var description: String {
            return "[UnencryptedLockbox.Metadata] ID: \(id) Name: \(name), Size: \(size), IsEncrypted: \(isEncrypted), IsExternal: \(isExternal)"
        }
    }
    
    let metadata: Metadata
    let inputStream: InputStream
    let outputStream: OutputStream
    
    private init(id: UUID, name: String, size: Int, isExternal: Bool, inputStream: InputStream, outputStream: OutputStream) {
        self.metadata = Metadata(
            id: id,
            name: name,
            size: size,
            isEncrypted: false,
            isExternal: isExternal
        )
        self.inputStream = inputStream
        self.outputStream = outputStream
    }
    
    static func create(id: UUID, name: String, size: Int, isExternal: Bool, lockerRoomDefaults: LockerRoomDefaulting, lockerRoomDiskController: LockerRoomDiskControlling, lockerRoomRemoteService: LockerRoomRemoteService, lockerRoomStore: LockerRoomStoring) -> UnencryptedLockbox? {
        guard size > 0 else {
            Logger.persistence.error("Unencrypted lockbox failed to create emtpy sized lockbox \(name)")
            return nil
        }
        
        if !isExternal {
            if lockerRoomDefaults.remoteServiceEnabled {
                guard lockerRoomRemoteService.createDiskImage(name: name, size: size, rootURL: lockerRoomStore.lockerRoomURLProvider.rootURL) else {
                    Logger.persistence.error("Unencrypted lockbox failed to create disk image \(name)")
                    return nil
                }
            } else {
                guard lockerRoomDiskController.create(name: name, size: size) else {
                    Logger.persistence.error("Unencrypted lockbox failed to create disk image \(name)")
                    return nil
                }
            }
        }
        
        guard let streams = streams(id: id, name: name, isEncrypted: false, isExternal: isExternal, lockerRoomStore: lockerRoomStore) else {
            Logger.persistence.error("Unencrypted lockbox failed to create input/output streams for \(name)")
            return nil
        }
        
        let lockbox = UnencryptedLockbox(id: id, name: name, size: size, isExternal: isExternal, inputStream: streams.input, outputStream: streams.output)
        
        guard lockerRoomStore.writeUnencryptedLockboxMetadata(lockbox.metadata) else {
            Logger.persistence.error("Unencrypted lockbox failed to write lockbox metadata for \(name)")
            return nil
        }
        
        Logger.persistence.log("Unencrypted lockbox created \(name)")
        
        return lockbox
    }
    
    static func create(from lockbox: LockerRoomLockbox, lockerRoomStore: LockerRoomStoring) -> UnencryptedLockbox? {
        let name = lockbox.name
        let isEncrypted = lockbox.isEncrypted
        
        guard !isEncrypted else {
            Logger.persistence.error("Unencrypted lockback failed to create \(name) from encrypted lockbox")
            return nil
        }
        
        guard let metadata = lockerRoomStore.readUnencryptedLockboxMetadata(name: name) else {
            Logger.persistence.error("Unencrypted lockbox failed to read metadata \(name)")
            return nil
        }
        
        let id = metadata.id
        let size = metadata.size
        let isExternal = metadata.isExternal
        
        guard let streams = streams(id: id, name: name, isEncrypted: isEncrypted, isExternal: isExternal, lockerRoomStore: lockerRoomStore) else {
            Logger.persistence.error("Unencrypted lockbox failed to create input and output streams for \(name)")
            return nil
        }
        
        return UnencryptedLockbox(id: id, name: name, size: size, isExternal: isExternal, inputStream: streams.input, outputStream: streams.output)
    }
    
    static func destroy(name: String, lockerRoomStore: LockerRoomStoring) -> Bool {
        guard lockerRoomStore.removeLockbox(name: name) else {
            Logger.persistence.error("Unencrypted lockbox failed to remove \(name)")
            return false
        }
        
        return true
    }
}
