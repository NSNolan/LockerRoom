//
//  LockboxCryptorTests.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/5/24.
//

import XCTest

final class LockboxCryptorTests: XCTestCase {
    func testLockboxCryptorSmall() {
        let size = 10 // 10 Bytes
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStore(lockerRoomURLProvider: urlProvider)
        
        let keyGenerator = LockboxKeyGenerator()
        let symmetricKeyData = keyGenerator.generateSymmetricKeyData()
        
        let fileManager = FileManager.default
        let decryptedContentURL = urlProvider.urlForLockboxUnencryptedContent(name: name)
        let decryptedContentPath = decryptedContentURL.path(percentEncoded: false)
        
        let cryptor = LockboxCryptor()
        
        guard let unencryptedContent = LockerTestUtilities.createRandomData(size: size) else {
            XCTFail("Failed to create random unencrypted content")
            return
        }
        
        var diskImage = LockerRoomDiskImageMock(lockerRoomURLProvider: urlProvider)
        diskImage.unencryptedContent = unencryptedContent
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(name: name, size: unencryptedContent.count, lockerRoomDiskImage: diskImage, lockerRoomStore: store) else {
            XCTFail("Failed to create unencrypted lockbox")
            return
        }
        
        guard cryptor.encrypt(lockbox: unencryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            XCTFail("Failed to encrypt lockbox")
            return
        }
        
        guard let encryptedLockbox = EncryptedLockbox.create(name: name, size: size, encryptedSymmetricKeysBySerialNumber: [UInt32:Data](), encryptionLockboxKeys: [LockboxKey](), lockerRoomStore: store) else {
            XCTFail("Failed to create encrypted lockbox")
            return
        }

        guard cryptor.decrypt(lockbox: encryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            XCTFail("Failed to decrypt lockbox")
            return
        }
        
        guard let decryptedContent = fileManager.contents(atPath: decryptedContentPath) else {
            XCTFail("Failed to read decrypted content at path \(decryptedContentPath)")
            return
        }
        
        XCTAssertEqual(unencryptedContent, decryptedContent, "Unencrypted content does not match decrypted content")
        
        guard store.removeLockbox(name: name) else {
            XCTFail("Failed to remove lockbox")
            return
        }
    }
    
    func testLockboxCryptorLarge() {
        let size = (1 * 1024 * 1024 * 1024) // 1GB
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStore(lockerRoomURLProvider: urlProvider)
        
        let cryptor = LockboxCryptor()
        let keyGenerator = LockboxKeyGenerator()
        let symmetricKeyData = keyGenerator.generateSymmetricKeyData()
        
        let fileManager = FileManager.default
        let decryptedContentURL = urlProvider.urlForLockboxUnencryptedContent(name: name)
        let decryptedContentPath = decryptedContentURL.path(percentEncoded: false)
        
        guard let unencryptedContent = LockerTestUtilities.createRandomData(size: size) else {
            XCTFail("Failed to create random unencrypted content")
            return
        }
        
        var diskImage = LockerRoomDiskImageMock(lockerRoomURLProvider: urlProvider)
        diskImage.unencryptedContent = unencryptedContent
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(name: name, size: unencryptedContent.count, lockerRoomDiskImage: diskImage, lockerRoomStore: store) else {
            XCTFail("Failed to create unencrypted lockbox")
            return
        }
        
        guard cryptor.encrypt(lockbox: unencryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            XCTFail("Failed to encrypt lockbox")
            return
        }
        
        guard let encryptedLockbox = EncryptedLockbox.create(name: name, size: size, encryptedSymmetricKeysBySerialNumber: [UInt32:Data](), encryptionLockboxKeys: [LockboxKey](), lockerRoomStore: store) else {
            XCTFail("Failed to create encrypted lockbox")
            return
        }

        guard cryptor.decrypt(lockbox: encryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            XCTFail("Failed to decrypt lockbox")
            return
        }
        
        guard let decryptedContent = fileManager.contents(atPath: decryptedContentPath) else {
            XCTFail("Failed to read decrypted content at path \(decryptedContentPath)")
            return
        }
        
        XCTAssertEqual(unencryptedContent, decryptedContent, "Unencrypted content does not match decrypted content")
        
        guard store.removeLockbox(name: name) else {
            XCTFail("Failed to remove lockbox")
            return
        }
    }
}
