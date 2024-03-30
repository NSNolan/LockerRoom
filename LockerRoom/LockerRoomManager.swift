//
//  LockerRoomManager.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

class LockerRoomManager: ObservableObject {
    internal let lockerRoomStore: LockerRoomStoring
    
    @Published var lockboxMetadatas = [LockerRoomLockboxMetadata]()
    @Published var lockboxKeyMetadatas = [LockerRoomLockboxKeyMetadata]()
    
    static let shared = LockerRoomManager()
    
    private init(lockerRoomStore: LockerRoomStoring = LockerRoomStore()) {
        self.lockerRoomStore = lockerRoomStore
        self.lockboxMetadatas = updateLockboxMetadatas()
        self.lockboxKeyMetadatas = updateLockboxKeyMetadatas()
    }
    
    func addUnencryptedLockbox(name: String, size: Int) -> UnencryptedLockbox? {
        guard let unencryptedLockbox = UnencryptedLockbox.create(name: name, size: size, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add unencrypted lockbox \(name)")
            return nil
        }
        
        lockboxMetadatas = updateLockboxMetadatas()
        return unencryptedLockbox
    }
    
    func addUnencryptedLockbox(name: String, unencryptedContent: Data) -> UnencryptedLockbox? {
        guard let unencryptedLockbox = UnencryptedLockbox.create(name: name, unencryptedContent: unencryptedContent, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add unencrypted lockbox \(name) with data")
            return nil
        }
        
        lockboxMetadatas = updateLockboxMetadatas()
        return unencryptedLockbox
    }
    
    func addEncryptedLockbox(name: String, encryptedContent: Data, encryptedSymmetricKey: Data) -> EncryptedLockbox? {
        guard let encryptedLockbox = EncryptedLockbox.create(name: name, encryptedContent: encryptedContent, encryptedSymmetricKey: encryptedSymmetricKey, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add encrypted lockbox \(name) with data")
            return nil
        }
        
        lockboxMetadatas = updateLockboxMetadatas()
        return encryptedLockbox
    }
    
    func removeUnencryptedLockbox(name: String) -> Bool {
        guard UnencryptedLockbox.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to remove unencrypted lockbox \(name)")
            return false
        }
        
        lockboxMetadatas = updateLockboxMetadatas()
        return true
    }
    
    func removeEncryptedLockbox(name: String) -> Bool {        
        guard EncryptedLockbox.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to remove encrypted lockbox \(name)")
            return false
        }
        
        lockboxMetadatas = updateLockboxMetadatas()
        return true
    }
    
    private func updateLockboxMetadatas() -> [LockerRoomLockboxMetadata] {
        var results = [LockerRoomLockboxMetadata]()
        
        do {
            let lockboxURLs = lockerRoomStore.lockboxURLs()
            for lockboxURL in lockboxURLs {
                let lockboxName = lockboxURL.lastPathComponent
                let isEncrypted = lockerRoomStore.lockboxFileExists(name: lockboxName, fileType: .encryptedContentFileType) &&
                                  lockerRoomStore.lockboxFileExists(name: lockboxName, fileType: .encryptedSymmetricKeyFileType)
                let size: Int
                if isEncrypted {
                    size = lockerRoomStore.lockboxFileSize(name: lockboxName, fileType: .encryptedContentFileType)
                } else {
                    size = lockerRoomStore.lockboxFileSize(name: lockboxName, fileType: .unencryptedContentFileType)
                }
                
                let metadata = LockerRoomLockboxMetadata(name: lockboxName, size: size, url: lockboxURL, isEncrypted: isEncrypted)
                results.append(metadata)
            }
        }
        
        return results
    }
    
    func addLockboxKey(
        name: String,
        serialNumber: UInt32,
        slot: LockboxKey.Slot,
        algorithm: LockboxKey.Algorithm,
        pinPolicy: LockboxKey.PinPolicy,
        touchPolicy: LockboxKey.TouchPolicy,
        managementKeyString: String,
        publicKey: SecKey
    ) -> LockboxKey? {
        guard let lockboxKey = LockboxKey.create(name: name, serialNumber: serialNumber, slot: slot, algorithm: algorithm, pinPolicy: pinPolicy, touchPolicy: touchPolicy, managementKeyString: managementKeyString, publicKey: publicKey, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add key \(name)")
            return nil
        }
        
        lockboxKeyMetadatas = updateLockboxKeyMetadatas()
        return lockboxKey
    }
    
    func removeLockboxKey(name: String) -> Bool {
        guard LockboxKey.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to remove key \(name)")
            return false
        }
        
        lockboxKeyMetadatas = updateLockboxKeyMetadatas()
        return true
    }
    
    private func updateLockboxKeyMetadatas() -> [LockerRoomLockboxKeyMetadata] {
        let keyURLs = lockerRoomStore.lockboxKeys()
        return keyURLs.map { $0.metadata }
    }
}
