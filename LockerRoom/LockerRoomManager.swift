//
//  LockerRoomManager.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

class LockerRoomManager: ObservableObject {
    internal let lockerRoomStore: LockerRoomStoring
    
    @Published var lockboxes = [LockerRoomLockbox]()
    @Published var enrolledKeys = [LockerRoomEnrolledKey]()
    
    static let shared = LockerRoomManager()
    
    private init(lockerRoomStore: LockerRoomStoring = LockerRoomStore()) {
        self.lockerRoomStore = lockerRoomStore
        self.lockboxes = lockerRoomStore.lockerRoomLockboxes
        self.enrolledKeys = lockerRoomStore.lockerRoomEnrolledKeys
    }
    
    func addUnencryptedLockbox(name: String, size: Int) -> UnencryptedLockbox? {
        guard let unencryptedLockbox = UnencryptedLockbox.create(name: name, size: size, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add unencrypted lockbox \(name)")
            return nil
        }
        
        lockboxes = lockerRoomStore.lockerRoomLockboxes
        return unencryptedLockbox
    }
    
    func addUnencryptedLockbox(name: String, size: Int, unencryptedContent: Data) -> UnencryptedLockbox? {
        guard let unencryptedLockbox = UnencryptedLockbox.create(name: name, size: size, unencryptedContent: unencryptedContent, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add unencrypted lockbox \(name) with data")
            return nil
        }
        
        lockboxes = lockerRoomStore.lockerRoomLockboxes
        return unencryptedLockbox
    }
    
    func removeUnencryptedLockbox(name: String) -> Bool {
        guard UnencryptedLockbox.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to remove unencrypted lockbox \(name)")
            return false
        }
        
        lockboxes = lockerRoomStore.lockerRoomLockboxes
        return true
    }
    
    func addEncryptedLockbox(name: String, size: Int, encryptedContent: Data, encryptedSymmetricKeysBySerialNumber: [UInt32:Data], encryptionLockboxKeys: [LockboxKey]) -> EncryptedLockbox? {
        guard let encryptedLockbox = EncryptedLockbox.create(name: name, size: size, encryptedContent: encryptedContent, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionLockboxKeys: encryptionLockboxKeys, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add encrypted lockbox \(name) with data")
            return nil
        }
        
        lockboxes = lockerRoomStore.lockerRoomLockboxes
        return encryptedLockbox
    }
    
    func removeEncryptedLockbox(name: String) -> Bool {
        guard EncryptedLockbox.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to remove encrypted lockbox \(name)")
            return false
        }
        
        lockboxes = lockerRoomStore.lockerRoomLockboxes
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
        
        enrolledKeys = lockerRoomStore.lockerRoomEnrolledKeys
        return lockboxKey
    }
    
    func removeLockboxKey(name: String) -> Bool {
        guard LockboxKey.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to remove key \(name)")
            return false
        }
        
        enrolledKeys = lockerRoomStore.lockerRoomEnrolledKeys
        return true
    }
    
    var lockboxKeys: [LockboxKey] {
        return lockerRoomStore.lockboxKeys
    }
}
