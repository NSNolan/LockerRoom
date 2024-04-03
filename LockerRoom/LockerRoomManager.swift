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
    
    func removeUnencryptedLockbox(name: String) -> Bool {
        guard UnencryptedLockbox.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to remove unencrypted lockbox \(name)")
            return false
        }
        
        lockboxMetadatas = updateLockboxMetadatas()
        return true
    }
    
    func addEncryptedLockbox(name: String, encryptedContent: Data, encryptedSymmetricKeysBySerialNumber: [UInt32:Data]) -> EncryptedLockbox? {
        guard let encryptedLockbox = EncryptedLockbox.create(name: name, encryptedContent: encryptedContent, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add encrypted lockbox \(name) with data")
            return nil
        }
        
        lockboxMetadatas = updateLockboxMetadatas()
        return encryptedLockbox
    }
    
    func removeEncryptedLockbox(name: String) -> Bool {        
        guard EncryptedLockbox.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to remove encrypted lockbox \(name)")
            return false
        }
        
        lockboxMetadatas = updateLockboxMetadatas()
        return true
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
    
    var lockboxKeys: [LockboxKey] {
        return lockerRoomStore.lockboxKeys()
    }
    
    private func updateLockboxMetadatas() -> [LockerRoomLockboxMetadata] { // TODO: this should be fetching codable objects instead of using the file system to construct the metadata        
        let lockboxURLs = lockerRoomStore.lockboxURLs()
        return lockboxURLs.map { lockboxURL in
            let lockboxName = lockboxURL.lastPathComponent
            let isEncrypted = lockerRoomStore.lockboxEncryptedExists(name: lockboxName)
            let size: Int
            if isEncrypted {
                size = lockerRoomStore.lockboxEncryptedSize(name: lockboxName)
            } else {
                size = lockerRoomStore.lockboxUnencryptedSize(name: lockboxName)
            }
            
            return LockerRoomLockboxMetadata(name: lockboxName, size: size, url: lockboxURL, isEncrypted: isEncrypted)
        }
    }
    
    private func updateLockboxKeyMetadatas() -> [LockerRoomLockboxKeyMetadata] {
        let keys = lockerRoomStore.lockboxKeys()
        return keys.map { $0.metadata }
    }
}
