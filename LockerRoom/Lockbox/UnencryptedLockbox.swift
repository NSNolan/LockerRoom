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
            
            return attachDiskImage()
        }
        
        guard lockboxStore.addLockbox(name: name) else {
            print("[Error] Unencrypted lockbox failed to add \(name)")
            return false
        }
        
        let lockboxUnencryptedContentURL = lockboxStore.lockboxURLProvider.urlForLockboxFile(name: name, type: .unencryptedContentFileType)
        let lockboxUnencryptedContentPath = lockboxUnencryptedContentURL.path()
        
        let process = Process()
        process.launchPath = "/usr/bin/hdiutil"
        process.arguments = [
            "create",
            "-verbose",
            "-size", "\(size)M",
            "-volname", "\(name)",
            "-fs", "APFS",
            lockboxUnencryptedContentPath
        ]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let status = process.terminationStatus
            if status != 0 {
                print("[Error] Unencrypted lockbox \(name) failed to create disk image of size \(size)MB at path \(lockboxUnencryptedContentPath) with status \(status)")
                _ = destroy()
                return false
            }
        } catch {
            print("[Error] Unencrypted lockbox \(name) failed to create disk image of size \(size)MB at path \(lockboxUnencryptedContentPath) with error \(error)")
            _ = destroy()
            return false
        }
        return attachDiskImage()
    }
    
    func destroy() -> Bool {
        guard !name.isEmpty else {
            print("[Error] Unencrypted lockbox failed to destory disk image without a name")
            return false
        }
        
        _ = detachDiskImage() // Not fatal
        
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
    
    func attachDiskImage() -> Bool {
        let lockboxUnencryptedContentURL = lockboxStore.lockboxURLProvider.urlForLockboxFile(name: name, type: .unencryptedContentFileType)
        let lockboxUnencryptedContentPath = lockboxUnencryptedContentURL.path()
        
        let process = Process()
        process.launchPath = "/usr/bin/hdiutil"
        process.arguments = [
            "attach", lockboxUnencryptedContentPath,
            "-autoopen"
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let status = process.terminationStatus
            if status != 0 {
                print("[Error] Unencrypted lockbox \(name) failed to mount disk image at path \(lockboxUnencryptedContentPath) with status \(status)")
                return false
            }
        } catch {
            print("[Error] Unencrypted lockbox \(name) failed to mount disk image at path \(lockboxUnencryptedContentPath) with error \(error)")
            return false
        }
        return true
    }
    
    func detachDiskImage() -> Bool {
        let mountedVolumeURL = lockboxStore.lockboxURLProvider.urlForMountedVolume(name: name)
        let mountedVolumePath = mountedVolumeURL.path()
        
        let process = Process()
        process.launchPath = "/usr/bin/hdiutil"
        process.arguments = [
            "detach", mountedVolumePath
        ]

        do {
            try process.run()
            process.waitUntilExit()

            let status = process.terminationStatus
            if status != 0 {
                print("[Warning] Unencrypted lockbox \(name) failed to unmount volume at path \(mountedVolumePath) with status \(status)")
                return false
            }
        } catch {
            print("[Error] Unencrypted lockbox \(name) failed to unmount volume at path \(mountedVolumePath) with error \(error)")
            return false
        }
        return true
    }
}
