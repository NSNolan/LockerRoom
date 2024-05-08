//
//  LockerRoomDiskImageMock.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/5/24.
//

import Foundation

struct LockerRoomDiskImageMock: LockerRoomDiskImaging {
    private let lockerRoomURLProvider: LockerRoomURLProviding
    private let fileManager = FileManager()
    
    var unencryptedContent: Data? = nil
    
    var failToCreate = false
    var failToAttach = false
    var failToDetach = false
    
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
        } catch {
            print("Failed to write random data to path \(unencryptedContentPath) with error: \(error)")
            return false
        }
        
        return true
    }
    
    func attach(name: String) -> Bool {
        return !failToAttach
    }
    
    func detach(name: String) -> Bool {
        return !failToDetach
    }
}
