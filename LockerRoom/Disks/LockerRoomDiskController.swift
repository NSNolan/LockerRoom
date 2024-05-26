//
//  LockerRoomDiskController.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/27/24.
//

import Foundation

import os.log

protocol LockerRoomDiskControlling {
    func create(name: String, size: Int) -> Bool
    func destory(name: String) -> Bool
    func open(name: String) -> Bool
    func attach(name: String) -> Bool
    func detach(name: String) -> Bool
    func mount(name: String) -> Bool
    func unmount(name: String) -> Bool
}

struct LockerRoomDiskController: LockerRoomDiskControlling {
    static let hdiutilLaunchPath = "/usr/bin/hdiutil"
    static let openLaunchPath = "/usr/bin/open"
    
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
                Logger.diskController.error("Disk controller operation for \(name) failed to create lockbox directory at path \(lockboxPath) with error \(error)")
                return false
            }
        }
        
        let lockboxUnencryptedContentPath = lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name).path
        return execute(
            launchPath: LockerRoomDiskController.hdiutilLaunchPath,
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
            Logger.diskController.error("Disk controller failed to remove disk with empty name")
            return false
        }
        
        let diskContentURL = lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name)
        let diskContentPath = diskContentURL.path(percentEncoded: false)
        
        guard fileManager.fileExists(atPath: diskContentPath) else {
            Logger.diskController.error("Disk controller failed to remove disk content \(name) at non-existing path \(diskContentPath)")
            return false
        }
        
        do {
            try fileManager.removeItem(at: diskContentURL)
            return true
        } catch {
            Logger.diskController.error("Disk controller failed to remove disk content \(name) at path \(diskContentPath)")
            return false
        }
    }
    
    func open(name: String) -> Bool {
        let mountedVolumePath = lockerRoomURLProvider.urlForMountedVolume(name: name).path
        return execute(
            launchPath: LockerRoomDiskController.openLaunchPath,
            arguments: [
                mountedVolumePath
            ],
            name: name
        )
    }
    
    func attach(name: String) -> Bool {
        let lockboxUnencryptedContentPath = lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name).path
        return execute(
            launchPath: LockerRoomDiskController.hdiutilLaunchPath,
            arguments: [
                "attach",
                "-verbose",
                "-autoopen",
                lockboxUnencryptedContentPath
            ],
            name: name
        )
    }
    
    func detach(name: String) -> Bool {
        let mountedVolumePath = lockerRoomURLProvider.urlForMountedVolume(name: name).path
        return execute(
            launchPath: LockerRoomDiskController.hdiutilLaunchPath,
            arguments: [
                "detach",
                "-verbose",
                mountedVolumePath
            ],
            name: name
        )
    }
    
    func mount(name: String) -> Bool {
        let devicePath = lockerRoomURLProvider.urlForAttachedDevice(name: name).path
        return execute(
            launchPath: LockerRoomDiskController.hdiutilLaunchPath,
            arguments: [
                "mountvol",
                "-verbose",
                "-whole",
                devicePath
            ],
            name: name
        )
    }
    
    func unmount(name: String) -> Bool {
        let mountedVolumePath = lockerRoomURLProvider.urlForMountedVolume(name: name).path
        return execute(
            launchPath: LockerRoomDiskController.hdiutilLaunchPath,
            arguments: [
                "unmount",
                "-verbose",
                "-whole",
                mountedVolumePath
            ],
            name: name
        )
    }
    
    private func execute(launchPath: String, arguments: [String], name: String) -> Bool {
        let process = Process()
        process.launchPath = launchPath
        process.arguments = arguments
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let status = process.terminationStatus
            if status != 0 {
                Logger.diskController.warning("Disk controller operation for \(name) with arguments \(arguments) failed with status \(status)")
                return false
            }
            return true
        } catch {
            Logger.diskController.error("Disk controller operation for \(name) with arguments \(arguments) failed with error \(error)")
            return false
        }
    }
}
