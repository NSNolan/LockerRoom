//
//  LockerRoomLockboxTests.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/8/24.
//

import XCTest

final class LockerRoomLockboxTests: XCTestCase {
    func testUnencryptedLockboxMetadataTransform() {
        let id = UUID()
        let size = 10
        let isEncrypted = false
        let isExternal = false
        let volumeCount = 1
        
        let unencryptedLockboxMetadata = UnencryptedLockbox.Metadata(
            id: id,
            name: name,
            size: size,
            isEncrypted: isEncrypted,
            isExternal: isExternal,
            volumeCount: volumeCount
        )
        let lockerRoomLockbox = unencryptedLockboxMetadata.lockerRoomLockbox
        
        XCTAssertEqual(lockerRoomLockbox.id, id)
        XCTAssertEqual(lockerRoomLockbox.name, name)
        XCTAssertEqual(lockerRoomLockbox.size, size)
        XCTAssertEqual(lockerRoomLockbox.isEncrypted, isEncrypted)
        XCTAssertEqual(lockerRoomLockbox.isExternal, isExternal)
        XCTAssertEqual(lockerRoomLockbox.encryptionKeyNames, [String]())
    }
    
    func testEncryptedLockboxMetadataTransform() {
        let id = UUID()
        let size = 10
        let isEncrypted = true
        let isExternal = false
        let volumeCount = 1
        
        let encryptionComponentsKey = "EncryptionComponent"
        let encryptionComponentsValue = withUnsafeBytes(of: 123) { Data($0) }
        
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
        
        let encryptionComponents = [[
            encryptionComponentsKey: encryptionComponentsValue
        ]]
        
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
        
        let encryptedLockboxMetadata = EncryptedLockbox.Metadata(
            id: id,
            name: name,
            size: size,
            isEncrypted: isEncrypted,
            isExternal: isExternal,
            volumeCount: volumeCount,
            encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber,
            encryptionComponents: encryptionComponents,
            encryptionLockboxKeys: encryptionLockboxKeys
        )
        let lockerRoomLockbox = encryptedLockboxMetadata.lockerRoomLockbox
        
        XCTAssertEqual(lockerRoomLockbox.id, id)
        XCTAssertEqual(lockerRoomLockbox.name, name)
        XCTAssertEqual(lockerRoomLockbox.size, size)
        XCTAssertEqual(lockerRoomLockbox.isEncrypted, isEncrypted)
        XCTAssertEqual(lockerRoomLockbox.isExternal, isExternal)
        XCTAssertEqual(lockerRoomLockbox.encryptionKeyNames, encryptionKeyNames)
    }
}
