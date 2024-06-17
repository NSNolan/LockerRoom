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
                Logger.diskController.error("Locker room disk controller operation for \(name) failed to create lockbox directory at path \(lockboxPath) with error \(error)")
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
            Logger.diskController.error("Locker room disk controller failed to remove disk with empty name")
            return false
        }
        
        let diskContentURL = lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name)
        let diskContentPath = diskContentURL.path(percentEncoded: false)
        
        guard fileManager.fileExists(atPath: diskContentPath) else {
            Logger.diskController.error("Locker room disk controller failed to remove disk content \(name) at non-existing path \(diskContentPath)")
            return false
        }
        
        do {
            try fileManager.removeItem(at: diskContentURL)
            return true
        } catch {
            Logger.diskController.error("Locker room disk controller failed to remove disk content \(name) at path \(diskContentPath)")
            return false
        }
    }
    
    func attach(name: String) -> Bool {
        let lockboxUnencryptedContentURL = lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name)
        let lockboxUnencryptedContentPath = lockboxUnencryptedContentURL.path(percentEncoded: false)
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
        let mountedVolumeURL = lockerRoomURLProvider.urlForMountedVolume(name: name)
        let mountedVolumePath = mountedVolumeURL.path(percentEncoded: false)
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
    
    func open(name: String) -> Bool {
        let mountedVolumeURL = lockerRoomURLProvider.urlForMountedVolume(name: name)
        let mountedVolumePath = mountedVolumeURL.path(percentEncoded: false)
        return execute(
            launchPath: LockerRoomDiskController.openLaunchPath,
            arguments: [
                mountedVolumePath
            ],
            name: name
        )
    }
    
    func mount(name: String) -> Bool {
        let deviceURL = lockerRoomURLProvider.urlForAttachedDevice(name: name)
        let devicePath = deviceURL.path(percentEncoded: false)
        return execute(
            launchPath: LockerRoomDiskController.hdiutilLaunchPath,
            arguments: [
                "mount",
                "-verbose",
                devicePath
            ],
            name: name
        )
    }
    
    func unmount(name: String) -> Bool {
        let mountedVolumeURL = lockerRoomURLProvider.urlForMountedVolume(name: name)
        let mountedVolumePath = mountedVolumeURL.path(percentEncoded: false)
        return execute(
            launchPath: LockerRoomDiskController.hdiutilLaunchPath,
            arguments: [
                "unmount",
                "-verbose",
                mountedVolumePath
            ],
            name: name
        )
    }
    
    private func execute(launchPath: String, arguments: [String], name: String) -> Bool {
        let process = Process()
        process.launchPath = launchPath
        process.arguments = arguments
        
        Logger.diskController.debug("Locker room disk controller executing operation \(launchPath) with arguments \(arguments)")
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let status = process.terminationStatus
            if status != 0 {
                Logger.diskController.warning("Locker room disk controller operation failed for \(name) with launch path \(launchPath) arguments \(arguments) status \(status)")
                return false
            }
            return true
        } catch {
            Logger.diskController.error("Locker room disk controller operation failed to run for \(name) with launch path \(launchPath) arguments \(arguments) error \(error)")
            return false
        }
    }
}
