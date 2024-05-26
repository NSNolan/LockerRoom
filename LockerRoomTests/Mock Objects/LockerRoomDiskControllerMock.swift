//
//  LockerRoomDiskControllerMock.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/5/24.
//

import Foundation

struct LockerRoomDiskControllerMock: LockerRoomDiskControlling {
    private let lockerRoomURLProvider: LockerRoomURLProviding
    private let fileManager = FileManager()
    
    var unencryptedContent: Data? = nil
    
    var failToCreate = false
    var failToDestroy = false
    var failToOpen = false
    var failToAttach = false
    var failToDetach = false
    var failToMount = false
    var failToUnmount = false
    
    init(lockerRoomURLProvider: LockerRoomURLProviding) {
        self.lockerRoomURLProvider = lockerRoomURLProvider
    }
    
    func create(name: String, size: Int) -> Bool {
        guard !failToCreate else {
            return false
        }
        
        guard let unencryptedContent else {
            return true
        }
        
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path(percentEncoded: false)
        
        if !fileManager.fileExists(atPath: lockboxPath) {
            do {
                try fileManager.createDirectory(at: lockboxURL, withIntermediateDirectories: true)
            } catch {
                print("Failed to create directory at path \(lockboxPath) with \(error)")
                return false
            }
        }
        
        let unencryptedContentURL = lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name)
        let unencryptedContentPath = unencryptedContentURL.path(percentEncoded: false)
        
        do {
            try unencryptedContent.write(to: unencryptedContentURL)
            return true
        } catch {
            print("Failed to write random data to path \(unencryptedContentPath) with error: \(error)")
            return false
        }
    }
    
    func destory(name: String) -> Bool {
        guard !failToDestroy else {
            return false
        }
        
        let unencryptedContentURL = lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name)
        let unencryptedContentPath = unencryptedContentURL.path(percentEncoded: false)
        
        do {
            try fileManager.removeItem(at: unencryptedContentURL)
            return true
        } catch {
            print("[Error] Disk image failed to remove disk content \(name) at path \(unencryptedContentPath)")
            return false
        }
    }
    
    func open(name: String) -> Bool {
        return !failToOpen
    }
    
    func attach(name: String) -> Bool {
        return !failToAttach
    }
    
    func detach(name: String) -> Bool {
        return !failToDetach
    }
    
    func mount(name: String) -> Bool {
        return !failToMount
    }
    
    func unmount(name: String) -> Bool {
        return !failToUnmount
    }
}
