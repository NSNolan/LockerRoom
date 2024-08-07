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
    
    private let lockboxCryptor: LockboxCrypting
    private let lockboxKeyCryptor: LockboxKeyCrypting
    private let lockboxKeyGenerator: LockboxKeyGenerating
    private let lockerRoomDefaults: LockerRoomDefaulting
    private let lockerRoomDiskController: LockerRoomDiskControlling
    private let lockerRoomExternalDiskDiscovery: LockerRoomExternalDiskDiscovering
    private let lockerRoomRemoteService: LockerRoomRemoteService
    private let lockerRoomStore: LockerRoomStoring
    
    private init(
        lockboxCryptor: LockboxCrypting? = nil,
        lockboxKeyCryptor: LockboxKeyCrypting = LockboxKeyCryptor(),
        lockboxKeyGenerator: LockboxKeyGenerating = LockboxKeyGenerator(),
        lockerRoomDefaults: LockerRoomDefaulting = LockerRoomDefaults(),
        lockerRoomDiskController: LockerRoomDiskControlling? = nil,
        lockerRoomExternalDiskDiscovery: LockerRoomExternalDiskDiscovering? = nil,
        lockerRoomRemoteService: LockerRoomRemoteService? = nil,
        lockerRoomStore: LockerRoomStoring? = nil,
        lockerRoomURLProvider: LockerRoomURLProviding = LockerRoomURLProvider()
    ) {
        self.lockboxCryptor = lockboxCryptor ?? LockboxCryptor(
            lockerRoomDefaults: lockerRoomDefaults
        )
        self.lockboxKeyCryptor = lockboxKeyCryptor
        self.lockboxKeyGenerator = lockboxKeyGenerator
        self.lockerRoomDefaults = lockerRoomDefaults
        self.lockerRoomDiskController = lockerRoomDiskController ?? LockerRoomDiskController(
            lockerRoomURLProvider: lockerRoomURLProvider
        )
        self.lockerRoomExternalDiskDiscovery = lockerRoomExternalDiskDiscovery ?? LockerRoomExternalDiskDiscovery(
            lockerRoomDefaults: lockerRoomDefaults
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
    
    var eligibleExternalDisksByID: [UUID:LockerRoomExternalDisk] {
        return lockerRoomExternalDiskDiscovery.externalDisksByID.filter { externalDiskEntry in
            let externalDiskID = externalDiskEntry.value.id
            return (lockboxesByID[externalDiskID] == nil)
        }
    }
    
    var presentExternalLockboxDisksByID: [UUID:LockerRoomExternalDisk] {
        return lockerRoomExternalDiskDiscovery.externalDisksByID.filter { externalDiskEntry in
            let externalDiskID = externalDiskEntry.value.id
            return (lockboxesByID[externalDiskID] != nil)
        }
    }
    
    func addUnencryptedLockbox(id: UUID, name: String, size: Int, isExternal: Bool, volumeCount: Int = 1) async -> UnencryptedLockbox? {
        guard let unencryptedLockbox = UnencryptedLockbox.create(
            id: id,
            name: name,
            size: size,
            isExternal: isExternal,
            volumeCount: volumeCount,
            lockerRoomDefaults: lockerRoomDefaults,
            lockerRoomDiskController: lockerRoomDiskController,
            lockerRoomRemoteService: lockerRoomRemoteService,
            lockerRoomStore: lockerRoomStore
        ) else {
            Logger.manager.error("Locker room manager failed to add unencrypted lockbox \(name)")
            return nil
        }
        
        lockboxesByID = self.lockerRoomStore.lockboxesByID
        return unencryptedLockbox
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
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(from: lockbox, lockerRoomStore: lockerRoomStore) else {
            Logger.manager.log("Locker room manager failed to create unencrypted lockbox \(lockbox.name)")
            return false
        }
        
        let id = unencryptedLockbox.metadata.id
        let name = unencryptedLockbox.metadata.name
        let size = unencryptedLockbox.metadata.size
        let isExternal = unencryptedLockbox.metadata.isExternal
        let volumeCount = unencryptedLockbox.metadata.volumeCount
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
        Logger.manager.log("Locker room manager encrypting using lockbox keys \(lockboxKeysToUse.map { $0.name }) for \(name)")
        
        for lockboxKey in lockboxKeysToUse {
            guard let encryptedSymmetricKeyData = lockboxKeyCryptor.encrypt(symmetricKeyData: symmetricKeyData, lockboxKey: lockboxKey) else {
                Logger.manager.error("Locker room manager failed to encrypt a symmetric key with lockbox key \(lockboxKey.name) for \(name)")
                continue
            }
            encryptedSymmetricKeysBySerialNumber[lockboxKey.serialNumber] = encryptedSymmetricKeyData
            encryptionLockboxKeys.append(lockboxKey)
        }
        
        let encryptedSymmetricKeysCount = encryptedSymmetricKeysBySerialNumber.count
        guard encryptedSymmetricKeysCount > 0 else {
            Logger.manager.error("Locker room manager failed to encrypt a symmetric key for \(name)")
            return false
        }
        Logger.manager.log("Locker room manager encrypted symmetric key using \(encryptedSymmetricKeysCount) lockbox keys for \(name)")
        
        var encryptionComponents: LockboxCryptorComponents? = nil
        
        if isExternal {
            guard lockerRoomDefaults.externalDisksEnabled else {
                Logger.manager.error("Locker room manager will not encrypt an unencrypted external lockbox \(name) with external disk disabled")
                return false
            }
            
            guard lockerRoomDefaults.remoteServiceEnabled else {
                Logger.manager.error("Locker room manager cannot encrypt an unencrypted external lockbox \(name) with remote service disabled")
                return false
            }
            
            guard let externalDisk = presentExternalLockboxDisksByID[id] else {
                Logger.manager.error("Locker room manager failed to find external disk \(name) with id \(id)")
                return false
            }
            let bsdName = externalDisk.bsdName
            let volumes = externalDisk.volumes
            let currentVolumeCount = volumes.count
            
            guard volumeCount == currentVolumeCount else {
                Logger.manager.error("Locker room manager detected change in external lockbox volume count with expected (\(volumes)) vs current (\(currentVolumeCount))")
                return false
            }
            
            for volume in volumes {
                _ = unmountVolume(name: volume) // Non-fatal; it may already be unmounted
            }
            
            let deviceURL = lockerRoomStore.lockerRoomURLProvider.urlForConnectedCharacterDevice(name: bsdName)
            let devicePath = deviceURL.path(percentEncoded: false)
            
            encryptionComponents = lockerRoomRemoteService.encryptExtractingComponents(inputPath: devicePath, outputPath: devicePath, symmetricKeyData: symmetricKeyData)
            guard encryptionComponents != nil else {
                Logger.manager.error("Locker room manager failed to encrypt an unencrypted external lockbox \(name) with BSD name \(bsdName)")
                return false
            }
        } else {
            _ = detachFromDiskImage(name: lockbox.name) // Non-fatal; it may already be detached
            
            guard lockboxCryptor.encrypt(lockbox: unencryptedLockbox, symmetricKeyData: symmetricKeyData) else {
                Logger.manager.error("Locker room manager failed to encrypt an unencrypted lockbox \(name)")
                return false
            }
        }
        
        logStatistics(startTime: startTime, totalBytes: size, encrypt: true)
        
        let encryptedLockboxMetdata = EncryptedLockbox.Metadata(
            id: id,
            name: name,
            size: size,
            isEncrypted: true,
            isExternal: isExternal,
            volumeCount: volumeCount,
            encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber,
            encryptionComponents: encryptionComponents,
            encryptionLockboxKeys: encryptionLockboxKeys
        )
        
        guard lockerRoomStore.writeEncryptedLockboxMetadata(encryptedLockboxMetdata, name: name) else {
            Logger.manager.error("Locker room manager failed to write encrypted lockbox metadata \(encryptedLockboxMetdata)")
            return false
        }
        Logger.manager.log("Locker room manager wrote encrypted lockbox metadata \(encryptedLockboxMetdata)")
        
        guard lockerRoomStore.writeUnencryptedLockboxMetadata(nil, name: name) else {
            Logger.manager.error("Locker room manager failed to remove unencrypted lockbox metadata \(name)")
            return false
        }
        Logger.manager.log("Locker room manager removed unencrypted lockbox metadata for \(name)")
        
        if !isExternal {
            guard lockerRoomStore.removeUnencryptedContent(name: name) else {
                Logger.manager.error("Locker room manager failed to removed unencrypted lockbox content \(name)")
                return false
            }
            Logger.manager.log("Locker room manager removed unencrypted lockbox content \(name)")
        }
        
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
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard let encryptedLockbox = EncryptedLockbox.create(from: lockbox, lockerRoomStore: lockerRoomStore) else {
            Logger.manager.log("Locker room manager failed to created encrypted lockbox \(lockbox.name)")
            return false
        }
        
        let id = encryptedLockbox.metadata.id
        let name = encryptedLockbox.metadata.name
        let size = encryptedLockbox.metadata.size
        let isExternal = encryptedLockbox.metadata.isExternal
        let volumeCount = encryptedLockbox.metadata.volumeCount
        let encryptionComponents = encryptedLockbox.metadata.encryptionComponents
        
        if isExternal {
            guard lockerRoomDefaults.externalDisksEnabled else {
                Logger.manager.error("Locker room manager will not decrypt an encrypted external lockbox \(name) with external disk disabled")
                return false
            }
            
            guard lockerRoomDefaults.remoteServiceEnabled else {
                Logger.manager.error("Locker room manager cannot decrypt an encrypted external lockbox \(name) with remote service disabled")
                return false
            }
            
            guard let externalDisk = presentExternalLockboxDisksByID[id] else {
                Logger.manager.error("Locker room manager failed to find external disk \(name) with id \(id)")
                return false
            }
            let bsdName = externalDisk.bsdName
            
            let deviceURL = lockerRoomStore.lockerRoomURLProvider.urlForConnectedCharacterDevice(name: bsdName)
            let devicePath = deviceURL.path(percentEncoded: false)
            
            guard let encryptionComponents else {
                Logger.manager.error("Locker room manager is missing lockbox components for encrypted external lockbox \(name)")
                return false
            }
            
            guard lockerRoomRemoteService.decryptWithComponents(inputPath: devicePath, outputPath: devicePath, symmetricKeyData: symmetricKeyData, components: encryptionComponents) else {
                Logger.manager.error("Locker room manager failed to decrypt an encrypted external lockbox \(name) with BSD name \(bsdName)")
                return false
            }
        } else {
            guard lockboxCryptor.decrypt(lockbox: encryptedLockbox, symmetricKeyData: symmetricKeyData) else {
                Logger.manager.error("Locker room manager failed to decrypt an encrypted lockbox \(name)")
                return false
            }
        }
        
        logStatistics(startTime: startTime, totalBytes: size, encrypt: false)
        
        let unencryptedLockboxMetdata = UnencryptedLockbox.Metadata(
            id: id,
            name: name,
            size: size,
            isEncrypted: false,
            isExternal: isExternal,
            volumeCount: volumeCount
        )
        
        guard lockerRoomStore.writeUnencryptedLockboxMetadata(unencryptedLockboxMetdata, name: name) else {
            Logger.manager.error("Locker room manager failed to write unencrypted lockbox metadata \(unencryptedLockboxMetdata)")
            return false
        }
        Logger.manager.log("Locker room manager wrote unencrypted lockbox metadata \(unencryptedLockboxMetdata)")
        
        guard lockerRoomStore.writeEncryptedLockboxMetadata(nil, name: name) else {
            Logger.manager.error("Locker room manager failed to remove encrypted lockbox metadata \(name)")
            return false
        }
        Logger.manager.log("Locker room manager removed encrypted lockbox metadata for \(name)")
        
        if isExternal {
            guard let externalDiskDevice = await lockerRoomExternalDiskDiscovery.waitForExternalDiskDeviceToAppear(
                id: id,
                volumeCount: volumeCount,
                timeoutInSeconds: 10
            ) else {
                Logger.manager.error("Locker room manager failed to find \(volumeCount) volumes for external disk \(name) with id \(id)")
                return false
            }
            
            guard let externalDisk = externalDiskDevice.lockerRoomExternalDisk else {
                return false
            }
            
            let bsdName = externalDisk.bsdName
            guard !lockerRoomDefaults.diskVerificationEnabled || verifyVolume(name: bsdName, usingMountedVolume: false) else {
                Logger.manager.error("Locker room manager failed to verify an unencrypted external lockbox \(name) with BSD name \(bsdName)")
                return false
            }
            
            for volume in externalDisk.volumes {
                guard openVolume(name: volume) else {
                    Logger.manager.error("Locker room manager failed to open volume \(volume) for an unencrypted external lockbox \(name)")
                    return false
                }
            }
        } else {
            guard attachToDiskImage(name: name) else {
                Logger.manager.error("Locker room manager failed to attach to unencrypted lockbox \(name)")
                return false
            }
            
            guard !lockerRoomDefaults.diskVerificationEnabled || verifyVolume(name: name, usingMountedVolume: true) else {
                Logger.manager.error("Locker room manager failed to verify an unencrypted lockbox \(name)")
                return false
            }
            
            guard lockerRoomStore.removeEncryptedContent(name: name) else {
                Logger.manager.error("Locker room manager failed to removed encrypted lockbox content \(name)")
                return false
            }
            Logger.manager.log("Locker room manager removed encrypted lockbox content \(name)")
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
            guard lockerRoomDiskController.attach(name: name) else {
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
            guard lockerRoomDiskController.detach(name: name) else {
                Logger.manager.error("Locker room manager failed to detach lockbox \(name)")
                return false
            }
        }
        
        return true
    }
    
    func openVolume(name: String) -> Bool {
        if lockerRoomDefaults.remoteServiceEnabled {
            guard lockerRoomRemoteService.openVolume(name: name, rootURL: lockerRoomStore.lockerRoomURLProvider.rootURL) else {
                Logger.manager.error("Locker room manager failed to open lockbox \(name)")
                return false
            }
        } else {
            guard lockerRoomDiskController.open(name: name) else {
                Logger.manager.error("Locker room manager failed to open lockbox \(name)")
                return false
            }
        }
        
        return true
    }
    
    func mountVolume(name: String) -> Bool {
        if lockerRoomDefaults.remoteServiceEnabled {
            guard lockerRoomRemoteService.mountVolume(name: name, rootURL: lockerRoomStore.lockerRoomURLProvider.rootURL) else {
                Logger.manager.error("Locker room manager failed to mount lockbox \(name)")
                return false
            }
        } else {
            guard lockerRoomDiskController.mount(name: name) else {
                Logger.manager.error("Locker room manager failed to mount lockbox \(name)")
                return false
            }
        }
        
        return true
    }
    
    func unmountVolume(name: String) -> Bool {
        if lockerRoomDefaults.remoteServiceEnabled {
            guard lockerRoomRemoteService.unmountVolume(name: name, rootURL: lockerRoomStore.lockerRoomURLProvider.rootURL) else {
                Logger.manager.error("Locker room manager failed to unmount lockbox \(name)")
                return false
            }
        } else {
            guard lockerRoomDiskController.unmount(name: name) else {
                Logger.manager.error("Locker room manager failed to unmount lockbox \(name)")
                return false
            }
        }
        
        return true
    }
    
    func verifyVolume(name: String, usingMountedVolume: Bool) -> Bool {
        if lockerRoomDefaults.remoteServiceEnabled {
            guard lockerRoomRemoteService.verifyVolume(name: name, usingMountedVolume: usingMountedVolume, rootURL: lockerRoomStore.lockerRoomURLProvider.rootURL) else {
                Logger.manager.error("Locker room manager failed to verify lockbox \(name)")
                return false
            }
        } else {
            guard lockerRoomDiskController.verify(name: name, usingMountedVolume: usingMountedVolume) else {
                Logger.manager.error("Locker room manager failed to verify lockbox \(name)")
                return false
            }
        }
        
        return true
    }
    
    private func logStatistics(startTime: CFAbsoluteTime, totalBytes: Int, encrypt: Bool) {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .brief
        formatter.zeroFormattingBehavior = .pad
        
        let durationInSeconds = Int(CFAbsoluteTimeGetCurrent() - startTime)
        if let durationString = formatter.string(from: TimeInterval(durationInSeconds)) {
            Logger.manager.log("Locker room manager \(encrypt ? "encrypted" : "decrypted") \(totalBytes) megabytes in \(durationString)")
        }
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

extension LockerRoomExternalDiskDiscovering {
    var externalDisksByID: [UUID:LockerRoomExternalDisk] {
        externalDiskDevicesByDeviceUnit.reduce(into: [UUID:LockerRoomExternalDisk]()) { result, externalDiskDeviceEntry in
            guard let externalDisk = externalDiskDeviceEntry.value.lockerRoomExternalDisk else {
                return
            }
            result[externalDisk.id] = externalDisk
        }
    }
}
