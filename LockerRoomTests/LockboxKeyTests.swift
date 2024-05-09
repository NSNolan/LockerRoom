//
//  LockboxKeyTests.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/7/24.
//

import XCTest

final class LockboxKeyTests: XCTestCase {
    func testCreateLockboxKey() {
        let serialNumber: UInt32 = 4321
        let slot = LockboxKey.Slot.digitalSignature
        let algorithm = LockboxKey.Algorithm.RSA2048
        let pinPolicy = LockboxKey.PinPolicy.never
        let touchPolicy = LockboxKey.TouchPolicy.always
        let managementKeyString = "ManagementKey"
        
        guard let publicKey = LockerRoomTestUtilities.createRandomPublicKey() else {
            XCTFail("Failed to create random public key")
            return
        }
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        
        guard let lockboxKey = LockboxKey.create(
            name: name,
            serialNumber: serialNumber,
            slot: slot,
            algorithm: algorithm,
            pinPolicy: pinPolicy,
            touchPolicy: touchPolicy,
            managementKeyString: managementKeyString,
            publicKey: publicKey,
            lockerRoomStore: store
        ) else {
            XCTFail("Failed to create lockbox key")
            return
        }
        
        XCTAssertEqual(lockboxKey.name, name)
        XCTAssertEqual(lockboxKey.serialNumber, serialNumber)
        XCTAssertEqual(lockboxKey.slot, slot)
        XCTAssertEqual(lockboxKey.algorithm, algorithm)
        XCTAssertEqual(lockboxKey.pinPolicy, pinPolicy)
        XCTAssertEqual(lockboxKey.touchPolicy, touchPolicy)
        XCTAssertEqual(lockboxKey.publicKey?.data, publicKey.data)
        XCTAssertFalse(lockboxKey.publicKeyData.isEmpty)
    }
    
    func testDestoryLockboxKey() {
        let serialNumber: UInt32 = 4321
        let keyName = String(serialNumber) // Keys are indexed by their serial number
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        
        guard LockboxKey.destroy(name: keyName, lockerRoomStore: store) else {
            XCTFail("Failed to destroy lockbox key")
            return
        }
    }
    
    func testCreateLockboxKeyExistsFailure() {
        let serialNumber: UInt32 = 4321
        let slot = LockboxKey.Slot.digitalSignature
        let algorithm = LockboxKey.Algorithm.RSA2048
        let pinPolicy = LockboxKey.PinPolicy.never
        let touchPolicy = LockboxKey.TouchPolicy.always
        let managementKeyString = "ManagementKey"
        
        guard let publicKey = LockerRoomTestUtilities.createRandomPublicKey() else {
            XCTFail("Failed to create random public key")
            return
        }
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.lockboxKeyExists = true
        
        let lockboxKey = LockboxKey.create(
            name: name,
            serialNumber: serialNumber,
            slot: slot,
            algorithm: algorithm,
            pinPolicy: pinPolicy,
            touchPolicy: touchPolicy,
            managementKeyString: managementKeyString,
            publicKey: publicKey,
            lockerRoomStore: store
        )
        
        XCTAssertNil(lockboxKey)
    }
    
    func testCreateLockboxKeyWriteFailure() {
        let serialNumber: UInt32 = 4321
        let slot = LockboxKey.Slot.digitalSignature
        let algorithm = LockboxKey.Algorithm.RSA2048
        let pinPolicy = LockboxKey.PinPolicy.never
        let touchPolicy = LockboxKey.TouchPolicy.always
        let managementKeyString = "ManagementKey"
        
        guard let publicKey = LockerRoomTestUtilities.createRandomPublicKey() else {
            XCTFail("Failed to create random public key")
            return
        }
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.failToWriteLockboxKey = true
        
        let lockboxKey = LockboxKey.create(
            name: name,
            serialNumber: serialNumber,
            slot: slot,
            algorithm: algorithm,
            pinPolicy: pinPolicy,
            touchPolicy: touchPolicy,
            managementKeyString: managementKeyString,
            publicKey: publicKey,
            lockerRoomStore: store
        )
        
        XCTAssertNil(lockboxKey)
    }
    
    func testDestroyLockboxKeyRemoveFailure() {
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.failToRemoveLockboxKey = true
        
        let destroySuccess = LockboxKey.destroy(name: name, lockerRoomStore: store)
        
        XCTAssertFalse(destroySuccess)
    }
    
    func testLockboxKeyExperimentalStatus() {
        XCTAssertFalse(LockboxKey.Slot.pivAuthentication.isExperimental)
        XCTAssertFalse(LockboxKey.Slot.digitalSignature.isExperimental)
        XCTAssertFalse(LockboxKey.Slot.keyManagement.isExperimental)
        XCTAssertFalse(LockboxKey.Slot.cardAuthentication.isExperimental)
        XCTAssertFalse(LockboxKey.Slot.attestation.isExperimental)
        
        XCTAssertTrue(LockboxKey.Slot.experimental82.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental83.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental84.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental85.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental86.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental87.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental88.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental89.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental8a.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental8b.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental8c.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental8d.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental8e.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental8f.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental90.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental91.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental92.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental93.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental94.isExperimental)
        XCTAssertTrue(LockboxKey.Slot.experimental95.isExperimental)
    }
}
