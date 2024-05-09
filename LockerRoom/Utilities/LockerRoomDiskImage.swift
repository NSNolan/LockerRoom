//
//  LockerRoomDiskImage.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/27/24.
//

import Foundation

protocol LockerRoomDiskImaging {
    func create(name: String, size: Int) -> Bool
    func destory(name: String) -> Bool
    func attach(name: String) -> Bool
    func detach(name: String) -> Bool
}

struct LockerRoomDiskImage: LockerRoomDiskImaging {
    static let hdiutilLaunchPath = "/usr/bin/hdiutil"
    
    private let lockerRoomURLProvider: LockerRoomURLProviding
    private let fileManager = FileManager.default
    
    init(lockerRoomURLProvider: LockerRoomURLProviding) {
        self.lockerRoomURLProvider = lockerRoomURLProvider
    }
    
    func create(name: String, size: Int) -> Bool {
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path(percentEncoded: false)
        
        if !fileManager.fileExists(atPath: lockboxPath) {
            do {
                try fileManager.createDirectory(atPath: lockboxPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("[Error] Disk image operation for \(name) failed to create lockbox directory at path \(lockboxPath) with error \(error)")
                return false
            }
        }
        
        let lockboxUnencryptedContentPath = lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name).path
        return hdiutil(
            arguments: [
                "create",
                "-verbose",
                "-size", "\(size)M",
                "-volname", name,
                "-fs", "APFS",
                lockboxUnencryptedContentPath
            ],
            name: name
        )
    }
    
    func destory(name: String) -> Bool {
        guard !name.isEmpty else {
            print("[Error] Disk image failed to remove disk with empty name")
            return false
        }
        
        let diskContentURL = lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name)
        let diskContentPath = diskContentURL.path(percentEncoded: false)
        
        guard fileManager.fileExists(atPath: diskContentPath) else {
            print("[Error] Disk image failed to remove disk content \(name) at non-existing path \(diskContentPath)")
            return false
        }
        
        do {
            try fileManager.removeItem(at: diskContentURL)
            return true
        } catch {
            print("[Error] Disk image failed to remove disk content \(name) at path \(diskContentPath)")
            return false
        }
    }
    
    func attach(name: String) -> Bool {
        let lockboxUnencryptedContentPath = lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name).path
        return hdiutil(
            arguments: [
                "attach",
                "-autoopen",
                lockboxUnencryptedContentPath
            ],
            name: name
        )
    }
    
    func detach(name: String) -> Bool {
        let mountedVolumePath = lockerRoomURLProvider.urlForMountedVolume(name: name).path
        return hdiutil(
            arguments: [
                "detach",
                mountedVolumePath
            ],
            name: name
        )
    }
    
    private func hdiutil(arguments: [String], name: String) -> Bool {
        let process = Process()
        process.launchPath = LockerRoomDiskImage.hdiutilLaunchPath
        process.arguments = arguments
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let status = process.terminationStatus
            if status != 0 {
                print("[Warning] Disk image operation for \(name) with arguments \(arguments) failed with status \(status)")
                return false
            }
            return true
        } catch {
            print("[Error] Disk image operation for \(name) with arguments \(arguments) failed with error \(error)")
            return false
        }
    }
}
