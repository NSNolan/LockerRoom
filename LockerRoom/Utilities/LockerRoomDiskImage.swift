//
//  LockerRoomDiskImage.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/27/24.
//

import Foundation

struct LockerRoomDiskImage {
    static let hdiutilLaunchPath = "/usr/bin/hdiutil"
    
    internal var lockerRoomURLProvider: LockerRoomURLProviding
    
    init(lockerRoomURLProvider: LockerRoomURLProviding = LockerRoomURLProvider()) {
        self.lockerRoomURLProvider = lockerRoomURLProvider
    }
    
    func create(name: String, size: Int) -> Bool {
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
