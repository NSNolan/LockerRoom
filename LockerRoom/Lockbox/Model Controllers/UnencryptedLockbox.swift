//
//  UnencryptedLockbox.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

class UnencryptedLockbox {
    let name: String
    let existingData: Data?
    
    internal let lockboxStore: LockboxStoring
    
    init(name: String, existingData: Data? = nil, lockboxStore: LockboxStoring) {
        self.name = name
        self.existingData = existingData
        self.lockboxStore = lockboxStore
    }
    
    func create(size: Int) -> Bool {
        if let existingData {
            print("[Default] Unencrypted lockbox is ignoring create size in favor or existing data")
            guard lockboxStore.writeToLockbox(data: existingData, name: name, fileType: .unencryptedContentFileType) else {
                print("[Error] Unencrypted lockbox failed to add \(name) from data \(existingData)")
                return false
            }
            
            return LockerRoomDiskImage().attach(name: name)
        }
        
        guard lockboxStore.addLockbox(name: name) else {
            print("[Error] Unencrypted lockbox failed to add \(name)")
            return false
        }

        let diskImage = LockerRoomDiskImage()
        return diskImage.create(name: name, size: size) && diskImage.attach(name: name)
    }
    
    func destroy() -> Bool {
        guard !name.isEmpty else {
            print("[Error] Unencrypted lockbox failed to destory disk image without a name")
            return false
        }
        
        _ = LockerRoomDiskImage().detach(name: name) // Not fatal
        
        self.unecryptedContent = nil
        if self.lockboxStore.removeLockbox(name: name) {
            return true
        } else {
            print("[Error] Unencrypted lockbox failed to remove \(name)")
            return false
        }
    }
    
    var unecryptedContent: Data? {
        get {
            if let data = lockboxStore.readFromLockbox(name: name, fileType: .unencryptedContentFileType) {
                return data
            } else {
                print("[Error] Encrypted lockbox failed to read unencrypted content for \(name)")
                return nil
            }
        }
        set(newUnencryptedContent) {
            if !lockboxStore.writeToLockbox(data: newUnencryptedContent, name: name, fileType: .unencryptedContentFileType) {
                print("[Error] Encrypted lockbox failed to write unencrypted content for \(name)")
            }
        }
    }
}
