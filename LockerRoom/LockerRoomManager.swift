//
//  LockerRoomManager.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

class LockerRoomManager: ObservableObject {
    @Published var lockboxes = [LockerRoomLockbox]()
    @Published var enrolledKeys = [LockerRoomEnrolledKey]()
    
    static let shared = LockerRoomManager()
    
    private let lockboxCryptor: LockboxCrypting
    private let lockboxKeyCryptor: LockboxKeyCrypting
    private let lockboxKeyGenerator: LockboxKeyGenerating
    private let lockerRoomDiskImage: LockerRoomDiskImaging
    private let lockerRoomStore: LockerRoomStoring
    
    private init(
        lockboxCryptor: LockboxCrypting = LockboxCryptor(),
        lockboxKeyCryptor: LockboxKeyCrypting = LockboxKeyCryptor(),
        lockboxKeyGenerator: LockboxKeyGenerating = LockboxKeyGenerator(),
        lockerRoomDiskImage: LockerRoomDiskImaging = LockerRoomDiskImage(),
        lockerRoomStore: LockerRoomStoring = LockerRoomStore()
    ) {
        self.lockboxCryptor = lockboxCryptor
        self.lockboxKeyCryptor = lockboxKeyCryptor
        self.lockboxKeyGenerator = lockboxKeyGenerator
        self.lockerRoomDiskImage = lockerRoomDiskImage
        self.lockerRoomStore = lockerRoomStore
        
        self.lockboxes = lockerRoomStore.lockboxes
        self.enrolledKeys = lockerRoomStore.enrolledKeys
    }
    
    func addUnencryptedLockbox(name: String, size: Int) -> UnencryptedLockbox? {
        guard let unencryptedLockbox = UnencryptedLockbox.create(name: name, size: size, lockerRoomDiskImage: lockerRoomDiskImage, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add unencrypted lockbox \(name)")
            return nil
        }
        
        guard lockerRoomDiskImage.attach(name: name) else {
            print("[Error] Locker room manager failed to attach lockbox \(name) as disk image")
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
        slot: LockboxKey.Slot,
        algorithm: LockboxKey.Algorithm,
        pinPolicy: LockboxKey.PinPolicy,
        touchPolicy: LockboxKey.TouchPolicy,
        managementKeyString: String
    ) async -> LockboxKey? {
        guard let result = await lockboxKeyGenerator.generatePublicKeyDataFromDevice(
            slot: slot,
            algorithm: algorithm,
            pinPolicy: pinPolicy,
            touchPolicy: touchPolicy,
            managementKeyString: managementKeyString
        ) else {
            print("[Error] Locker room manager failed to generate public key from data for key \(name)")
            return nil
        }
        
        let publicKey = result.publicKey
        let serialNumber = result.serialNumber
        
        guard let lockboxKey = LockboxKey.create(name: name, serialNumber: serialNumber, slot: slot, algorithm: algorithm, pinPolicy: pinPolicy, touchPolicy: touchPolicy, managementKeyString: managementKeyString, publicKey: publicKey, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Locker room manager failed to add key \(name) with serial number \(serialNumber)")
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
    
    func encrypt(lockbox: LockerRoomLockbox) -> Bool {
        _ = lockerRoomDiskImage.detach(name: lockbox.name) // Non-fatal; it may already be detached
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(from: lockbox, lockerRoomStore: lockerRoomStore) else {
            print("[Default] Locker room manager failed to created unencrypted lockbox \(lockbox.name)")
            return false
        }
        
        let name = unencryptedLockbox.metadata.name
        let size = unencryptedLockbox.metadata.size
        let symmetricKeyData = lockboxKeyGenerator.generateSymmetricKeyData()
        
        var encryptedSymmetricKeysBySerialNumber = [UInt32:Data]()
        var encryptionLockboxKeys = [LockboxKey]()
        
        for lockboxKey in lockerRoomStore.lockboxKeys {
            guard let encryptedSymmetricKeyData = lockboxKeyCryptor.encrypt(symmetricKeyData: symmetricKeyData, lockboxKey: lockboxKey) else {
                print("[Error] Locker room manager failed to encrypt a symmetric key with lockbox key \(lockboxKey.name) for \(name)")
                continue
            }
            encryptedSymmetricKeysBySerialNumber[lockboxKey.serialNumber] = encryptedSymmetricKeyData
            encryptionLockboxKeys.append(lockboxKey)
        }
        
        guard !encryptedSymmetricKeysBySerialNumber.isEmpty else {
            print("[Error] Locker room manager failed to encrypt a symmetric key for \(name)")
            return false
        }
        print("[Default] Locker room manager encrypted a symmetric key for \(name)")
        
        guard lockboxCryptor.encrypt(lockbox: unencryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            print("[Error] Locker room manager failed to encrypt an unencrypted lockbox \(name)")
            return false
        }
        print("[Default] Locker room manager encrypted an unencrypted lockbox \(name)")
        
        let encryptedLockboxMetdata = EncryptedLockbox.Metadata(name: name, size: size, isEncrypted: true, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionLockboxKeys: encryptionLockboxKeys)
        guard lockerRoomStore.writeEncryptedLockboxMetadata(encryptedLockboxMetdata) else {
            print("[Error] Locker room manager failed to write encrypted lockbox metadata \(encryptedLockboxMetdata)")
            return false
        }
        print("[Default] Locker room manager wrote encrypted lockbox metadata \(encryptedLockboxMetdata)")
        
        guard lockerRoomStore.removeUnencryptedContent(name: name) else {
            print("[Error] Locker room manager failed to removed unencrypted lockbox content \(name)")
            return false
        }
        print("[Default] Locker room manager removed unencrypted lockbox content \(name)")
        
        lockboxes = lockerRoomStore.lockboxes
        return true
    }
    
    func decryptKey(forLockbox lockbox: LockerRoomLockbox) async -> Data? {
        let name = lockbox.name
        let encryptedSymmetricKeysBySerialNumber = lockerRoomStore.readEncryptedLockboxMetadata(name: name)?.encryptedSymmetricKeysBySerialNumber
        
        guard let encryptedSymmetricKeysBySerialNumber, !encryptedSymmetricKeysBySerialNumber.isEmpty else {
            print("[Error] Locker room manager is missing encrypted symmetric keys for \(name)")
            return nil
        }
        
        var lockboxKeysBySerialNumber = [UInt32:LockboxKey]()
        for lockboxKey in lockerRoomStore.lockboxKeys {
            lockboxKeysBySerialNumber[lockboxKey.serialNumber] = lockboxKey
        }
        
        guard let symmetricKeyData = await lockboxKeyCryptor.decrypt(encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, lockboxKeysBySerialNumber: lockboxKeysBySerialNumber) else {
            print("[Error] Locker room manager failed to decrypt an encrypted symmetric key for \(name)")
            return nil
        }
        print("[Default] Locker room manager decrypted an encrypted symmetric key for \(name)")
        
        return symmetricKeyData
    }
    
    func decrypt(lockbox: LockerRoomLockbox, symmetricKeyData: Data) -> Bool {
        guard let encryptedLockbox = EncryptedLockbox.create(from: lockbox, lockerRoomStore: lockerRoomStore) else {
            print("[Default] Locker room manager failed to created encrypted lockbox \(lockbox.name)")
            return false
        }
        
        let name = encryptedLockbox.metadata.name
        let size = encryptedLockbox.metadata.size
        
        guard lockboxCryptor.decrypt(lockbox: encryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            print("[Error] Locker room manager failed to decrypt an encrypted lockbox \(name)")
            return false
        }
        print("[Default] Locker room manager decrypted an encrypted lockbox \(name)")
        
        let unencryptedLockboxMetdata = UnencryptedLockbox.Metadata(name: name, size: size, isEncrypted: false)
        guard lockerRoomStore.writeUnencryptedLockboxMetadata(unencryptedLockboxMetdata) else {
            print("[Error] Locker room manager failed to write unencrypted lockbox metadata \(unencryptedLockboxMetdata)")
            return false
        }
        print("[Default] Locker room manager wrote unencrypted lockbox metadata \(unencryptedLockboxMetdata)")
        
        guard lockerRoomStore.removeEncryptedContent(name: name) else {
            print("[Error] Locker room manager failed to removed encrypted lockbox content \(name)")
            return false
        }
        print("[Default] Locker room manager removed encrypted lockbox content \(name)")
        
        guard lockerRoomDiskImage.attach(name: name) else {
            print("[Error] Locker room manager failed to attach lockbox \(name) as disk image")
            return false
        }
        
        lockboxes = lockerRoomStore.lockboxes
        return true
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
