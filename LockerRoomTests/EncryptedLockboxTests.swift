//
//  EncryptedLockboxTests.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/8/24.
//

import XCTest

final class EncryptedLockboxTests: XCTestCase {
    func testCreateEncryptedLockbox() {
        let size = 10
        
        let lockboxKeyName = "LockboxKey"
        let lockboxKeySerialNumber: UInt32 = 4321
        let lockboxKeySlot = LockboxKey.Slot.digitalSignature
        let lockboxKeyAlgorithm = LockboxKey.Algorithm.RSA2048
        let lockboxKeyPinPolicy = LockboxKey.PinPolicy.never
        let lockboxKeyTouchPolicy = LockboxKey.TouchPolicy.always
        let lockboxKeyManagementKeyString = "ManagementKey"
        
        guard let lockboxPublicKey = LockerTestUtilities.createRandomPublicKey() else {
            XCTFail("Failed to create random public key")
            return
        }
        
        guard let encryptedSymmetricKey = LockerTestUtilities.createRandomData(size: size) else {
            XCTFail("Failed to create random encrypted symmetric key")
            return
        }
        
        let encryptedSymmetricKeysBySerialNumber = [
            lockboxKeySerialNumber: encryptedSymmetricKey
        ]
        
        let encryptionLockboxKeys = [
            LockboxKey(
                name: lockboxKeyName,
                serialNumber: lockboxKeySerialNumber,
                slot: lockboxKeySlot,
                algorithm: lockboxKeyAlgorithm,
                pinPolicy: lockboxKeyPinPolicy,
                touchPolicy: lockboxKeyTouchPolicy,
                managementKeyString: lockboxKeyManagementKeyString,
                publicKey: lockboxPublicKey
            )
        ]
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        
        guard let encryptedLockbox = EncryptedLockbox.create(
            name: name,
            size: size,
            encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber,
            encryptionLockboxKeys: encryptionLockboxKeys,
            lockerRoomStore: store
        ) else {
            XCTFail("Failed to create encrypted lockbox")
            return
        }
        
        XCTAssertEqual(encryptedLockbox.metadata.name, name)
        XCTAssertEqual(encryptedLockbox.metadata.size, size)
        XCTAssertEqual(encryptedLockbox.metadata.encryptedSymmetricKeysBySerialNumber, encryptedSymmetricKeysBySerialNumber)
        XCTAssertEqual(encryptedLockbox.metadata.encryptionLockboxKeys, encryptionLockboxKeys)
        XCTAssertTrue(encryptedLockbox.metadata.isEncrypted)
    }
    
    func testCreateEncryptedLockboxFromLockerRoomLockbox() {
        let size = 10
        let isEncrypted = true
        
        let lockboxKeyName = "LockboxKey"
        let lockboxKeySerialNumber: UInt32 = 4321
        let lockboxKeySlot = LockboxKey.Slot.digitalSignature
        let lockboxKeyAlgorithm = LockboxKey.Algorithm.RSA2048
        let lockboxKeyPinPolicy = LockboxKey.PinPolicy.never
        let lockboxKeyTouchPolicy = LockboxKey.TouchPolicy.always
        let lockboxKeyManagementKeyString = "ManagementKey"
        
        guard let lockboxPublicKey = LockerTestUtilities.createRandomPublicKey() else {
            XCTFail("Failed to create random public key")
            return
        }
        
        guard let encryptedSymmetricKey = LockerTestUtilities.createRandomData(size: size) else {
            XCTFail("Failed to create random encrypted symmetric key")
            return
        }
        
        let encryptedSymmetricKeysBySerialNumber = [
            lockboxKeySerialNumber: encryptedSymmetricKey
        ]
        
        let encryptionLockboxKeys = [
            LockboxKey(
                name: lockboxKeyName,
                serialNumber: lockboxKeySerialNumber,
                slot: lockboxKeySlot,
                algorithm: lockboxKeyAlgorithm,
                pinPolicy: lockboxKeyPinPolicy,
                touchPolicy: lockboxKeyTouchPolicy,
                managementKeyString: lockboxKeyManagementKeyString,
                publicKey: lockboxPublicKey
            )
        ]
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.encryptedLockboxMetadata = EncryptedLockbox.Metadata(
            name: name,
            size: size,
            isEncrypted: isEncrypted,
            encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber,
            encryptionLockboxKeys: encryptionLockboxKeys
        )
        
        let lockerRoomLockbox = LockerRoomLockbox(name: name, size: size, isEncrypted: isEncrypted, encryptionKeyNames: [String]())
        
        guard let encryptedLockbox = EncryptedLockbox.create(from: lockerRoomLockbox, lockerRoomStore: store) else {
            XCTFail("Failed to create encrypted lockbox")
            return
        }
        
        XCTAssertEqual(encryptedLockbox.metadata.name, name)
        XCTAssertEqual(encryptedLockbox.metadata.size, size)
        XCTAssertEqual(encryptedLockbox.metadata.encryptedSymmetricKeysBySerialNumber, encryptedSymmetricKeysBySerialNumber)
        XCTAssertEqual(encryptedLockbox.metadata.encryptionLockboxKeys, encryptionLockboxKeys)
        XCTAssertTrue(encryptedLockbox.metadata.isEncrypted)
    }
    
    func testDestroyEncryptedLockbox() {
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        
        guard EncryptedLockbox.destroy(name: name, lockerRoomStore: store) else {
            XCTFail("Failed to destroy encrypted lockbox")
            return
        }
    }
    
    func testCreateEncryptedLockboxInvalidSizeFailure() {
        let size = 0
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        
        let encryptedLockbox = EncryptedLockbox.create(
            name: name,
            size: size,
            encryptedSymmetricKeysBySerialNumber: [UInt32:Data](),
            encryptionLockboxKeys: [LockboxKey](),
            lockerRoomStore: store
        )
        
        XCTAssertNil(encryptedLockbox)
    }
    
    func testCreateEncryptedLockboxWriteMetadataFailure() {
        let size = 10
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.failToWriteEncryptedLockboxMetadata = true
        
        let encryptedLockbox = EncryptedLockbox.create(
            name: name,
            size: size,
            encryptedSymmetricKeysBySerialNumber: [UInt32:Data](),
            encryptionLockboxKeys: [LockboxKey](),
            lockerRoomStore: store
        )
        
        XCTAssertNil(encryptedLockbox)
    }
    
    func testCreateEncryptedLockboxFromLockerRoomLockboxIsEncryptedFailure() {
        let size = 10
        let isEncrypted = false
        
        let lockerRoomLockbox = LockerRoomLockbox(name: name, size: size, isEncrypted: isEncrypted, encryptionKeyNames: [String]())
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        
        let encryptedLockbox = EncryptedLockbox.create(from: lockerRoomLockbox, lockerRoomStore: store)
        
        XCTAssertNil(encryptedLockbox)
    }
    
    func testCreateEncryptedLockboxFromLockerRoomLockboxReadMetadataFailure() {
        let size = 10
        let isEncrypted = true
        
        let lockerRoomLockbox = LockerRoomLockbox(name: name, size: size, isEncrypted: isEncrypted, encryptionKeyNames: [String]())
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.failToReadEncryptedLockboxMetadata = true
        
        let encryptedLockbox = EncryptedLockbox.create(from: lockerRoomLockbox, lockerRoomStore: store)
        
        XCTAssertNil(encryptedLockbox)
    }
    
    func testDestroyEncryptedLockboxRemoveFailure() {
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.failToRemoveLockbox = true
        
        let destroySuccess = EncryptedLockbox.destroy(name: name, lockerRoomStore: store)
        
        XCTAssertFalse(destroySuccess)
    }
}
