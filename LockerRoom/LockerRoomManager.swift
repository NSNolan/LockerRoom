//
//  LockerRoomManager.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

import os.log

@Observable class LockerRoomManager {
    static let shared = LockerRoomManager()
    
    var lockboxesByID = [UUID:LockerRoomLockbox]()
    var enrolledKeysByID = [UUID:LockerRoomEnrolledKey]()
    
    var eligibleExternalDisksByID: [UUID:LockerRoomExternalDisk] {
        return lockerRoomExternalDiskDiscovery.disksByID
    }
    
    private let lockboxCryptor: LockboxCrypting
    private let lockboxKeyCryptor: LockboxKeyCrypting
    private let lockboxKeyGenerator: LockboxKeyGenerating
    private let lockerRoomDefaults: LockerRoomDefaulting
    private let lockerRoomDiskImage: LockerRoomDiskImaging
    private let lockerRoomExternalDiskDiscovery: LockerRoomExternalDiskDiscovering
    private let lockerRoomRemoteService: LockerRoomRemoteService
    private let lockerRoomStore: LockerRoomStoring
    
    private init(
        lockboxCryptor: LockboxCrypting = LockboxCryptor(),
        lockboxKeyCryptor: LockboxKeyCrypting = LockboxKeyCryptor(),
        lockboxKeyGenerator: LockboxKeyGenerating = LockboxKeyGenerator(),
        lockerRoomDefaults: LockerRoomDefaulting = LockerRoomDefaults(),
        lockerRoomDiskImage: LockerRoomDiskImaging? = nil,
        lockerRoomExternalDiskDiscovery: LockerRoomExternalDiskDiscovering? = nil,
        lockerRoomRemoteService: LockerRoomRemoteService? = nil,
        lockerRoomStore: LockerRoomStoring? = nil,
        lockerRoomURLProvider: LockerRoomURLProviding = LockerRoomURLProvider()
    ) {
        self.lockboxCryptor = lockboxCryptor
        self.lockboxKeyCryptor = lockboxKeyCryptor
        self.lockboxKeyGenerator = lockboxKeyGenerator
        self.lockerRoomDefaults = lockerRoomDefaults
        self.lockerRoomDiskImage = lockerRoomDiskImage ?? LockerRoomDiskImage(
            lockerRoomURLProvider: lockerRoomURLProvider
        )
        self.lockerRoomExternalDiskDiscovery = lockerRoomExternalDiskDiscovery ?? LockerRoomExternalDiskDiscovery(
            lockerRoomDefaults: lockerRoomDefaults,
            lockerRoomURLProvider: lockerRoomURLProvider
        )
        self.lockerRoomRemoteService = lockerRoomRemoteService ?? LockerRoomRemoteService(
            lockerRoomDefaults: lockerRoomDefaults
        )
        self.lockerRoomStore = lockerRoomStore ?? LockerRoomStore(
            lockerRoomURLProvider: lockerRoomURLProvider
        )
        
        self.lockboxesByID = self.lockerRoomStore.lockboxesByID
        self.enrolledKeysByID = self.lockerRoomStore.enrolledKeysByID
        
        LockerRoomAppLifecycle.externalDiskDiscovery = self.lockerRoomExternalDiskDiscovery
        LockerRoomAppLifecycle.remoteService = self.lockerRoomRemoteService
    }
    
    func addUnencryptedLockbox(name: String, size: Int, isExternal: Bool) async -> UnencryptedLockbox? {
        return (try? await Task {
            guard let unencryptedLockbox = UnencryptedLockbox.create(name: name, size: size, isExternal: isExternal, lockerRoomDefaults: lockerRoomDefaults, lockerRoomDiskImage: lockerRoomDiskImage, lockerRoomRemoteService: lockerRoomRemoteService, lockerRoomStore: lockerRoomStore) else {
                Logger.manager.error("Locker room manager failed to add unencrypted lockbox \(name)")
                return nil
            }
            
            lockboxesByID = self.lockerRoomStore.lockboxesByID
            return unencryptedLockbox
        }.result.get()) ?? nil
    }
    
    func removeUnencryptedLockbox(name: String) -> Bool {
        guard UnencryptedLockbox.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            Logger.manager.error("Locker room manager failed to remove unencrypted lockbox \(name)")
            return false
        }
        
        lockboxesByID = lockerRoomStore.lockboxesByID
        return true
    }
    
    func removeEncryptedLockbox(name: String) -> Bool {
        guard EncryptedLockbox.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            Logger.manager.error("Locker room manager failed to remove encrypted lockbox \(name)")
            return false
        }
        
        lockboxesByID = lockerRoomStore.lockboxesByID
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
            Logger.manager.error("Locker room manager failed to generate public key from data for key \(name)")
            return nil
        }
        
        let publicKey = result.publicKey
        let serialNumber = result.serialNumber
        
        guard let lockboxKey = LockboxKey.create(name: name, serialNumber: serialNumber, slot: slot, algorithm: algorithm, pinPolicy: pinPolicy, touchPolicy: touchPolicy, managementKeyString: managementKeyString, publicKey: publicKey, lockerRoomStore: lockerRoomStore) else {
            Logger.manager.error("Locker room manager failed to add key \(name) with serial number \(serialNumber)")
            return nil
        }
        
        enrolledKeysByID = lockerRoomStore.enrolledKeysByID
        return lockboxKey
    }
    
    func removeLockboxKey(name: String) -> Bool {
        guard LockboxKey.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            Logger.manager.error("Locker room manager failed to remove key \(name)")
            return false
        }
        
        enrolledKeysByID = lockerRoomStore.enrolledKeysByID
        return true
    }
    
    var lockboxKeySlots: [LockboxKey.Slot] {
        let experimentalPIVSlotsEnabled = lockerRoomDefaults.experimentalPIVSlotsEnabled
        return LockboxKey.Slot.allCases.filter{ !$0.isExperimental || experimentalPIVSlotsEnabled }
    }
    
    func encrypt(lockbox: LockerRoomLockbox, usingEnrolledKeys enrolledKeysToUse: [LockerRoomEnrolledKey]) async -> Bool {
        _ = detachFromDiskImage(name: lockbox.name) // Non-fatal; it may already be detached
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(from: lockbox, lockerRoomStore: lockerRoomStore) else {
            Logger.manager.log("Locker room manager failed to create unencrypted lockbox \(lockbox.name)")
            return false
        }
        
        let name = unencryptedLockbox.metadata.name
        let size = unencryptedLockbox.metadata.size
        let isExternal = unencryptedLockbox.metadata.isExternal
        let symmetricKeyData = lockboxKeyGenerator.generateSymmetricKeyData()
        
        var encryptedSymmetricKeysBySerialNumber = [UInt32:Data]()
        var encryptionLockboxKeys = [LockboxKey]()
        
        let lockboxKeysToUse: [LockboxKey]
        if enrolledKeysToUse.isEmpty {
            lockboxKeysToUse = lockerRoomStore.lockboxKeys
        } else {
            let keyNamesToUse = Set(enrolledKeysToUse.map { $0.name })
            lockboxKeysToUse = lockerRoomStore.lockboxKeys.filter { keyNamesToUse.contains($0.name) }
        }
        Logger.manager.log("Locker room manager encrypting using lockbox keys \(lockboxKeysToUse.map { $0.name })")
        
        for lockboxKey in lockboxKeysToUse {
            guard let encryptedSymmetricKeyData = lockboxKeyCryptor.encrypt(symmetricKeyData: symmetricKeyData, lockboxKey: lockboxKey) else {
                Logger.manager.error("Locker room manager failed to encrypt a symmetric key with lockbox key \(lockboxKey.name) for \(name)")
                continue
            }
            encryptedSymmetricKeysBySerialNumber[lockboxKey.serialNumber] = encryptedSymmetricKeyData
            encryptionLockboxKeys.append(lockboxKey)
        }
        
        guard !encryptedSymmetricKeysBySerialNumber.isEmpty else {
            Logger.manager.error("Locker room manager failed to encrypt a symmetric key for \(name)")
            return false
        }
        Logger.manager.log("Locker room manager encrypted a symmetric key for \(name)")
        
        guard await lockboxCryptor.encrypt(lockbox: unencryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            Logger.manager.error("Locker room manager failed to encrypt an unencrypted lockbox \(name)")
            return false
        }
        Logger.manager.log("Locker room manager encrypted an unencrypted lockbox \(name)")
        
        let encryptedLockboxMetdata = EncryptedLockbox.Metadata(name: name, size: size, isEncrypted: true, isExternal: isExternal, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionLockboxKeys: encryptionLockboxKeys)
        guard lockerRoomStore.writeEncryptedLockboxMetadata(encryptedLockboxMetdata) else {
            Logger.manager.error("Locker room manager failed to write encrypted lockbox metadata \(encryptedLockboxMetdata)")
            return false
        }
        Logger.manager.log("Locker room manager wrote encrypted lockbox metadata \(encryptedLockboxMetdata)")
        
        guard lockerRoomStore.removeUnencryptedContent(name: name) else {
            Logger.manager.error("Locker room manager failed to removed unencrypted lockbox content \(name)")
            return false
        }
        Logger.manager.log("Locker room manager removed unencrypted lockbox content \(name)")
        
        lockboxesByID = lockerRoomStore.lockboxesByID
        return true
    }
    
    func decryptKey(forLockbox lockbox: LockerRoomLockbox) async -> Data? {
        let name = lockbox.name
        let encryptedSymmetricKeysBySerialNumber = lockerRoomStore.readEncryptedLockboxMetadata(name: name)?.encryptedSymmetricKeysBySerialNumber
        
        guard let encryptedSymmetricKeysBySerialNumber, !encryptedSymmetricKeysBySerialNumber.isEmpty else {
            Logger.manager.error("Locker room manager is missing encrypted symmetric keys for \(name)")
            return nil
        }
        
        var lockboxKeysBySerialNumber = [UInt32:LockboxKey]()
        for lockboxKey in lockerRoomStore.lockboxKeys {
            lockboxKeysBySerialNumber[lockboxKey.serialNumber] = lockboxKey
        }
        
        guard let symmetricKeyData = await lockboxKeyCryptor.decrypt(encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, lockboxKeysBySerialNumber: lockboxKeysBySerialNumber) else {
            Logger.manager.error("Locker room manager failed to decrypt an encrypted symmetric key for \(name)")
            return nil
        }
        Logger.manager.log("Locker room manager decrypted an encrypted symmetric key for \(name)")
        
        return symmetricKeyData
    }
    
    func decrypt(lockbox: LockerRoomLockbox, symmetricKeyData: Data) async -> Bool {
        guard let encryptedLockbox = EncryptedLockbox.create(from: lockbox, lockerRoomStore: lockerRoomStore) else {
            Logger.manager.log("Locker room manager failed to created encrypted lockbox \(lockbox.name)")
            return false
        }
        
        let name = encryptedLockbox.metadata.name
        let size = encryptedLockbox.metadata.size
        let isExternal = encryptedLockbox.metadata.isExternal
        
        guard await lockboxCryptor.decrypt(lockbox: encryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            Logger.manager.error("Locker room manager failed to decrypt an encrypted lockbox \(name)")
            return false
        }
        Logger.manager.log("Locker room manager decrypted an encrypted lockbox \(name)")
        
        let unencryptedLockboxMetdata = UnencryptedLockbox.Metadata(name: name, size: size, isEncrypted: false, isExternal: isExternal)
        guard lockerRoomStore.writeUnencryptedLockboxMetadata(unencryptedLockboxMetdata) else {
            Logger.manager.error("Locker room manager failed to write unencrypted lockbox metadata \(unencryptedLockboxMetdata)")
            return false
        }
        Logger.manager.log("Locker room manager wrote unencrypted lockbox metadata \(unencryptedLockboxMetdata)")
        
        guard lockerRoomStore.removeEncryptedContent(name: name) else {
            Logger.manager.error("Locker room manager failed to removed encrypted lockbox content \(name)")
            return false
        }
        Logger.manager.log("Locker room manager removed encrypted lockbox content \(name)")
        
        guard attachToDiskImage(name: name) else {
            return false
        }
        
        lockboxesByID = lockerRoomStore.lockboxesByID
        return true
    }
    
    func attachToDiskImage(name: String) -> Bool {
        if lockerRoomDefaults.remoteServiceEnabled {
            guard lockerRoomRemoteService.attachToDiskImage(name: name, rootURL: lockerRoomStore.lockerRoomURLProvider.rootURL) else {
                Logger.manager.error("Locker room manager failed to attach lockbox \(name)")
                return false
            }
        } else {
            guard lockerRoomDiskImage.attach(name: name) else {
                Logger.manager.error("Locker room manager failed to attach lockbox \(name)")
                return false
            }
        }
        
        return true
    }
    
    func detachFromDiskImage(name: String) -> Bool {
        if lockerRoomDefaults.remoteServiceEnabled {
            guard lockerRoomRemoteService.detachFromDiskImage(name: name, rootURL: lockerRoomStore.lockerRoomURLProvider.rootURL) else {
                Logger.manager.error("Locker room manager failed to detach lockbox \(name)")
                return false
            }
        } else {
            guard lockerRoomDiskImage.detach(name: name) else {
                Logger.manager.error("Locker room manager failed to detach lockbox \(name)")
                return false
            }
        }
        
        return true
    }
}

extension LockerRoomStoring {
    var lockboxesByID: [UUID:LockerRoomLockbox] {
        let unencryptedLockboxes = unencryptedLockboxMetdatas.map { $0.lockerRoomLockbox }
        let encryptedLockboxes = encryptedLockboxMetadatas.map { $0.lockerRoomLockbox }
        let lockboxes = unencryptedLockboxes + encryptedLockboxes
        return lockboxes.reduce(into: [UUID:LockerRoomLockbox]()) { $0[$1.id] = $1 }
    }
    
    var enrolledKeysByID: [UUID:LockerRoomEnrolledKey] {
        let enrolledKeys = lockboxKeys.map{ $0.lockerRoomEnrolledKey }
        return enrolledKeys.reduce(into: [UUID:LockerRoomEnrolledKey]()) { $0[$1.id] = $1 }
    }
}
