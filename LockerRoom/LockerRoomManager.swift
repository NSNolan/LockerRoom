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
        self.lockboxes = lockerRoomStore.lockboxes
        self.enrolledKeys = lockerRoomStore.enrolledKeys
    }
    
    func addUnencryptedLockbox(name: String, size: Int) -> UnencryptedLockbox? {
        guard let unencryptedLockbox = UnencryptedLockbox.create(name: name, size: size, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add unencrypted lockbox \(name)")
            return nil
        }
        
        lockboxes = lockerRoomStore.lockboxes
        return unencryptedLockbox
    }
    
    func addUnencryptedLockbox(name: String, size: Int, unencryptedContent: Data) -> UnencryptedLockbox? {
        guard let unencryptedLockbox = UnencryptedLockbox.create(name: name, size: size, unencryptedContent: unencryptedContent, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add unencrypted lockbox \(name) with data")
            return nil
        }
        
        lockboxes = lockerRoomStore.lockboxes
        return unencryptedLockbox
    }
    
    func removeUnencryptedLockbox(name: String) -> Bool {
        guard UnencryptedLockbox.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to remove unencrypted lockbox \(name)")
            return false
        }
        
        lockboxes = lockerRoomStore.lockboxes
        return true
    }
    
    func addEncryptedLockbox(name: String, size: Int, encryptedContent: Data, encryptedSymmetricKeysBySerialNumber: [UInt32:Data], encryptionLockboxKeys: [LockboxKey]) -> EncryptedLockbox? {
        guard let encryptedLockbox = EncryptedLockbox.create(name: name, size: size, encryptedContent: encryptedContent, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionLockboxKeys: encryptionLockboxKeys, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add encrypted lockbox \(name) with data")
            return nil
        }
        
        lockboxes = lockerRoomStore.lockboxes
        return encryptedLockbox
    }
    
    func removeEncryptedLockbox(name: String) -> Bool {
        guard EncryptedLockbox.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to remove encrypted lockbox \(name)")
            return false
        }
        
        lockboxes = lockerRoomStore.lockboxes
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
        
        enrolledKeys = lockerRoomStore.enrolledKeys
        return lockboxKey
    }
    
    func removeLockboxKey(name: String) -> Bool {
        guard LockboxKey.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to remove key \(name)")
            return false
        }
        
        enrolledKeys = lockerRoomStore.enrolledKeys
        return true
    }
    
    func encrypt(lockbox: UnencryptedLockbox) {
        let name = lockbox.metadata.name
        let size = lockbox.metadata.size
        let symmetricKeyData = LockboxKeyGenerator.generateSymmetricKeyData()
        
        var encryptedSymmetricKeysBySerialNumber = [UInt32:Data]()
        var encryptionLockboxKeys = [LockboxKey]()
        
        for lockboxKey in lockerRoomStore.lockboxKeys {
            guard let encryptedSymmetricKeyData = LockboxKeyCryptor.encrypt(symmetricKeyData: symmetricKeyData, lockboxKey: lockboxKey) else {
                print("[Error] Locker room manager failed to encrypt a symmetric key with lockbox key \(lockboxKey.name) for \(name)")
                continue
            }
            encryptedSymmetricKeysBySerialNumber[lockboxKey.serialNumber] = encryptedSymmetricKeyData
            encryptionLockboxKeys.append(lockboxKey)
        }
        
        guard !encryptedSymmetricKeysBySerialNumber.isEmpty else {
            print("[Error] Locker room manager failed to encrypt a symmetric key for \(name)")
            return
        }
        print("[Default] Locker room manager encrypted a symmetric key for \(name)")
        
        guard let encryptedContent = LockboxCryptor.encrypt(lockbox: lockbox, symmetricKeyData: symmetricKeyData) else {
            print("[Error] Locker room manager failed to encrypt an unencrypted lockbox \(name)")
            return
        }
        print("[Default] Locker room manager encrypted an unencrypted lockbox \(name)")
        
        guard removeUnencryptedLockbox(name: name) else { // TODO: Unencrypted lockbox is removed before encrypted lockbox is added. May cause data loss.
            print("[Error] Locker room manager failed to removed an unencrypted lockbox \(name)")
            return
        }
        print("[Default] Locker room manager removed an unencrypted lockbox \(name)")
        
        guard addEncryptedLockbox(name: name, size: size, encryptedContent: encryptedContent, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionLockboxKeys: encryptionLockboxKeys) != nil else {
            print("[Error] Locker room manager failed to add an encrypted lockbox \(name)")
            return
        }
        print("[Default] Locker room manager added an encrypted lockbox \(name)")
    }
    
    func decryptKey(forLockbox lockbox: EncryptedLockbox) async -> Data? {
        let name = lockbox.metadata.name
        let encryptedSymmetricKeysBySerialNumber = lockbox.metadata.encryptedSymmetricKeysBySerialNumber
        
        guard !encryptedSymmetricKeysBySerialNumber.isEmpty else {
            print("[Error] Locker room manager is missing encrypted symmetric keys for \(name)")
            return nil
        }
        
        var lockboxKeysBySerialNumber = [UInt32:LockboxKey]()
        for lockboxKey in lockerRoomStore.lockboxKeys {
            lockboxKeysBySerialNumber[lockboxKey.serialNumber] = lockboxKey
        }
        
        guard let symmetricKeyData = await LockboxKeyCryptor.decrypt(encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, lockboxKeysBySerialNumber: lockboxKeysBySerialNumber) else {
            print("[Error] Locker room manager failed to decrypt an encrypted symmetric key for \(name)")
            return nil
        }
        print("[Default] Locker room manager decrypted an encrypted symmetric key for \(name)")
        
        return symmetricKeyData
    }
    
    func decrypt(lockbox: EncryptedLockbox, symmetricKeyData: Data) {
        let name = lockbox.metadata.name
            
        guard let content = LockboxCryptor.decrypt(lockbox: lockbox, symmetricKeyData: symmetricKeyData) else {
            print("[Error] Locker room manager failed to decrypt an encrypted lockbox \(name)")
            return
        }
        print("[Default] Locker room manager decrypted an encrypted lockbox \(name)")
        
        guard removeEncryptedLockbox(name: name) else { // TODO: Encrypted lockbox is removed before unencrypted lockbox is added. May cause data loss.
            print("[Error] Locker room manager failed to remove an encrypted lockbox \(name)")
            return
        }
        print("[Default] Locker room manager removed an encrypted lockbox \(name)")
        
        guard addUnencryptedLockbox(name: name, size: lockbox.metadata.size, unencryptedContent: content) != nil else {
            print("[Error] Locker room manager failed to add an unencrypted lockbox \(name)")
            return
        }
        print("[Default] Locker room manager added an unencrypted lockbox \(name)")
    }
}

extension LockerRoomStoring {
    var lockboxes: [LockerRoomLockbox] {
        let unencryptedLockboxes = unencryptedLockboxMetdatas.map { $0.lockerRoomLockbox }
        let encryptedLockboxes = encryptedLockboxMetadatas.map { $0.lockerRoomLockbox }
        return unencryptedLockboxes + encryptedLockboxes
    }
    
    var enrolledKeys: [LockerRoomEnrolledKey] {
        return lockboxKeys.map{ $0.lockerRoomEnrolledKey }
    }
}
