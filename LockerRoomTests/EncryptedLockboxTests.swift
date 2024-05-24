//
//  EncryptedLockboxTests.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/8/24.
//

import XCTest

final class EncryptedLockboxTests: XCTestCase {
    func testCreateEncryptedLockbox() {
        let id = UUID()
        let size = 10
        let isExternal = false
        
        let lockboxKeyName = "LockboxKey"
        let lockboxKeySerialNumber: UInt32 = 4321
        let lockboxKeySlot = LockboxKey.Slot.digitalSignature
        let lockboxKeyAlgorithm = LockboxKey.Algorithm.RSA2048
        let lockboxKeyPinPolicy = LockboxKey.PinPolicy.never
        let lockboxKeyTouchPolicy = LockboxKey.TouchPolicy.always
        let lockboxKeyManagementKeyString = "ManagementKey"
        
        guard let lockboxPublicKey = LockerRoomTestUtilities.createRandomPublicKey() else {
            XCTFail("Failed to create random public key")
            return
        }
        
        guard let encryptedSymmetricKey = LockerRoomTestUtilities.createRandomData(size: size) else {
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
            id: id,
            name: name,
            size: size,
            isExternal: isExternal,
            encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber,
            encryptionLockboxKeys: encryptionLockboxKeys,
            lockerRoomStore: store
        ) else {
            XCTFail("Failed to create encrypted lockbox")
            return
        }
        
        XCTAssertEqual(encryptedLockbox.metadata.id, id)
        XCTAssertEqual(encryptedLockbox.metadata.name, name)
        XCTAssertEqual(encryptedLockbox.metadata.size, size)
        XCTAssertEqual(encryptedLockbox.metadata.isExternal, isExternal)
        XCTAssertEqual(encryptedLockbox.metadata.encryptedSymmetricKeysBySerialNumber, encryptedSymmetricKeysBySerialNumber)
        XCTAssertEqual(encryptedLockbox.metadata.encryptionLockboxKeys, encryptionLockboxKeys)
        XCTAssertTrue(encryptedLockbox.metadata.isEncrypted)
    }
    
    func testCreateEncryptedLockboxFromLockerRoomLockbox() {
        let id = UUID()
        let size = 10
        let isEncrypted = true
        let isExternal = false
        
        let lockboxKeyName = "LockboxKey"
        let lockboxKeySerialNumber: UInt32 = 4321
        let lockboxKeySlot = LockboxKey.Slot.digitalSignature
        let lockboxKeyAlgorithm = LockboxKey.Algorithm.RSA2048
        let lockboxKeyPinPolicy = LockboxKey.PinPolicy.never
        let lockboxKeyTouchPolicy = LockboxKey.TouchPolicy.always
        let lockboxKeyManagementKeyString = "ManagementKey"
        
        guard let lockboxPublicKey = LockerRoomTestUtilities.createRandomPublicKey() else {
            XCTFail("Failed to create random public key")
            return
        }
        
        guard let encryptedSymmetricKey = LockerRoomTestUtilities.createRandomData(size: size) else {
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
            id: id,
            name: name,
            size: size,
            isEncrypted: isEncrypted,
            isExternal: isExternal,
            encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber,
            encryptionLockboxKeys: encryptionLockboxKeys
        )
        
        let lockerRoomLockbox = LockerRoomLockbox(id: id, name: name, size: size, isEncrypted: isEncrypted, isExternal: isExternal, encryptionKeyNames: [String]())
        
        guard let encryptedLockbox = EncryptedLockbox.create(from: lockerRoomLockbox, lockerRoomStore: store) else {
            XCTFail("Failed to create encrypted lockbox")
            return
        }
        
        XCTAssertEqual(encryptedLockbox.metadata.id, id)
        XCTAssertEqual(encryptedLockbox.metadata.name, name)
        XCTAssertEqual(encryptedLockbox.metadata.size, size)
        XCTAssertEqual(encryptedLockbox.metadata.isExternal, isExternal)
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
        let id = UUID()
        let size = 0
        let isExternal = false
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        
        let encryptedLockbox = EncryptedLockbox.create(
            id: id,
            name: name,
            size: size,
            isExternal: isExternal,
            encryptedSymmetricKeysBySerialNumber: [UInt32:Data](),
            encryptionLockboxKeys: [LockboxKey](),
            lockerRoomStore: store
        )
        
        XCTAssertNil(encryptedLockbox)
    }
    
    func testCreateEncryptedLockboxWriteMetadataFailure() {
        let id = UUID()
        let size = 10
        let isExternal = false
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.failToWriteEncryptedLockboxMetadata = true
        
        let encryptedLockbox = EncryptedLockbox.create(
            id: id,
            name: name,
            size: size,
            isExternal: isExternal,
            encryptedSymmetricKeysBySerialNumber: [UInt32:Data](),
            encryptionLockboxKeys: [LockboxKey](),
            lockerRoomStore: store
        )
        
        XCTAssertNil(encryptedLockbox)
    }
    
    func testCreateEncryptedLockboxFromLockerRoomLockboxIsEncryptedFailure() {
        let id = UUID()
        let size = 10
        let isEncrypted = false
        let isExternal = false
        
        let lockerRoomLockbox = LockerRoomLockbox(id: id, name: name, size: size, isEncrypted: isEncrypted, isExternal: isExternal, encryptionKeyNames: [String]())
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        
        let encryptedLockbox = EncryptedLockbox.create(from: lockerRoomLockbox, lockerRoomStore: store)
        
        XCTAssertNil(encryptedLockbox)
    }
    
    func testCreateEncryptedLockboxFromLockerRoomLockboxReadMetadataFailure() {
        let id = UUID()
        let size = 10
        let isEncrypted = true
        let isExternal = false
        
        let lockerRoomLockbox = LockerRoomLockbox(id: id, name: name, size: size, isEncrypted: isEncrypted, isExternal: isExternal, encryptionKeyNames: [String]())
        
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
