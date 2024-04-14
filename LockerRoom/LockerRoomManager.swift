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
        self.lockboxMetadatas = lockerRoomStore.lockboxMetadatas
        self.lockboxKeyMetadatas = lockerRoomStore.lockboxKeyMetadatas
    }
    
    func addUnencryptedLockbox(name: String, size: Int) -> UnencryptedLockbox? {
        guard let unencryptedLockbox = UnencryptedLockbox.create(name: name, size: size, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add unencrypted lockbox \(name)")
            return nil
        }
        
        lockboxMetadatas = lockerRoomStore.lockboxMetadatas
        return unencryptedLockbox
    }
    
    func addUnencryptedLockbox(name: String, unencryptedContent: Data) -> UnencryptedLockbox? {
        guard let unencryptedLockbox = UnencryptedLockbox.create(name: name, unencryptedContent: unencryptedContent, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add unencrypted lockbox \(name) with data")
            return nil
        }
        
        lockboxMetadatas = lockerRoomStore.lockboxMetadatas
        return unencryptedLockbox
    }
    
    func removeUnencryptedLockbox(name: String) -> Bool {
        guard UnencryptedLockbox.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to remove unencrypted lockbox \(name)")
            return false
        }
        
        lockboxMetadatas = lockerRoomStore.lockboxMetadatas
        return true
    }
    
    func addEncryptedLockbox(name: String, encryptedContent: Data, encryptedSymmetricKeysBySerialNumber: [UInt32:Data]) -> EncryptedLockbox? {
        guard let encryptedLockbox = EncryptedLockbox.create(name: name, encryptedContent: encryptedContent, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add encrypted lockbox \(name) with data")
            return nil
        }
        
        lockboxMetadatas = lockerRoomStore.lockboxMetadatas
        return encryptedLockbox
    }
    
    func removeEncryptedLockbox(name: String) -> Bool {        
        guard EncryptedLockbox.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to remove encrypted lockbox \(name)")
            return false
        }
        
        lockboxMetadatas = lockerRoomStore.lockboxMetadatas
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
        
        lockboxKeyMetadatas = lockerRoomStore.lockboxKeyMetadatas
        return lockboxKey
    }
    
    func removeLockboxKey(name: String) -> Bool {
        guard LockboxKey.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to remove key \(name)")
            return false
        }
        
        lockboxKeyMetadatas = lockerRoomStore.lockboxKeyMetadatas
        return true
    }
    
    var lockboxKeys: [LockboxKey] {
        return lockerRoomStore.lockboxKeys
    }
}
