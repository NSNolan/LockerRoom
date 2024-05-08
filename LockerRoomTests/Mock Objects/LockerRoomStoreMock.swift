//
//  LockerRoomStoreMock.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/8/24.
//

import Foundation

struct LockerRoomStoreMock: LockerRoomStoring {
    var lockerRoomURLProvider: LockerRoomURLProviding
    
    var failToReadUnencryptedLockboxMetadata = false
    var unencryptedLockboxMetadata: UnencryptedLockbox.Metadata? = nil
    var failToWriteUnencryptedLockboxMetadata = false
    
    var failToReadEncryptedLockboxMetadata = false
    var encryptedLockboxMetadata: EncryptedLockbox.Metadata? = nil
    var failToWriteEncryptedLockboxMetadata = false
    
    var lockboxExists = false
    var failToRemoveLockbox = false
    var failToRemoveUnencryptedContent = false
    var failToRemoveEncryptedContent = false
    
    var failToReadLockboxKey = false
    var lockboxKey: LockboxKey? = nil
    var failToWriteLockboxKey = false
    
    var lockboxKeyExists = false
    var failToRemoveLockboxKey = false
    
    init(lockerRoomURLProvider: LockerRoomURLProviding) {
        self.lockerRoomURLProvider = lockerRoomURLProvider
    }
    
    func readUnencryptedLockboxMetadata(name: String) -> UnencryptedLockbox.Metadata? {
        return failToReadUnencryptedLockboxMetadata ? nil : unencryptedLockboxMetadata
    }
    
    func writeUnencryptedLockboxMetadata(_ lockboxMetadata: UnencryptedLockbox.Metadata) -> Bool {
        return !failToWriteUnencryptedLockboxMetadata
    }
    
    func readEncryptedLockboxMetadata(name: String) -> EncryptedLockbox.Metadata? {
        return failToReadEncryptedLockboxMetadata ? nil : encryptedLockboxMetadata
    }
    
    func writeEncryptedLockboxMetadata(_ lockboxMetadata: EncryptedLockbox.Metadata) -> Bool {
        return !failToWriteEncryptedLockboxMetadata
    }
    
    func lockboxExists(name: String) -> Bool {
        return lockboxExists
    }
    
    func removeLockbox(name: String) -> Bool {
        return !failToRemoveLockbox
    }
    
    func removeUnencryptedContent(name: String) -> Bool {
        return !failToRemoveUnencryptedContent
    }
    
    func removeEncryptedContent(name: String) -> Bool {
        return !failToRemoveEncryptedContent
    }
    
    var unencryptedLockboxMetdatas = [UnencryptedLockbox.Metadata]()
    
    var encryptedLockboxMetadatas = [EncryptedLockbox.Metadata]()
    
    func readLockboxKey(name: String) -> LockboxKey? {
        return failToReadLockboxKey ? nil : lockboxKey
    }
    
    func writeLockboxKey(_ key: LockboxKey?, name: String) -> Bool {
        return !failToWriteLockboxKey
    }
    
    func lockboxKeyExists(name: String) -> Bool {
        return lockboxKeyExists
    }
    
    func removeLockboxKey(name: String) -> Bool {
        return !failToRemoveLockboxKey
    }
    
    var lockboxKeys = [LockboxKey]()
}
