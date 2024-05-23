//
//  LockerRoomLockboxTests.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/8/24.
//

import XCTest

final class LockerRoomLockboxTests: XCTestCase {
    func testUnencryptedLockboxMetadataTransform() {
        let size = 10
        let isEncrypted = false
        let isExternal = false
        
        let unencryptedLockboxMetadata = UnencryptedLockbox.Metadata(name: name, size: size, isEncrypted: isEncrypted, isExternal: isExternal)
        let lockerRoomLockbox = unencryptedLockboxMetadata.lockerRoomLockbox
        
        XCTAssertNotNil(lockerRoomLockbox.id)
        XCTAssertEqual(lockerRoomLockbox.name, name)
        XCTAssertEqual(lockerRoomLockbox.size, size)
        XCTAssertEqual(lockerRoomLockbox.isEncrypted, isEncrypted)
        XCTAssertEqual(lockerRoomLockbox.encryptionKeyNames, [String]())
    }
    
    func testEncryptedLockboxMetadataTransform() {
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
        let encryptionKeyNames = encryptionLockboxKeys.map { $0.name }
        
        let encryptedLockboxMetadata = EncryptedLockbox.Metadata(name: name, size: size, isEncrypted: isEncrypted, isExternal: isExternal, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionLockboxKeys: encryptionLockboxKeys)
        let lockerRoomLockbox = encryptedLockboxMetadata.lockerRoomLockbox
        
        XCTAssertNotNil(lockerRoomLockbox.id)
        XCTAssertEqual(lockerRoomLockbox.name, name)
        XCTAssertEqual(lockerRoomLockbox.size, size)
        XCTAssertEqual(lockerRoomLockbox.isEncrypted, isEncrypted)
        XCTAssertEqual(lockerRoomLockbox.encryptionKeyNames, encryptionKeyNames)
    }
}
