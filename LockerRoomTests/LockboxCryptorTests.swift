//
//  LockboxCryptorTests.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/5/24.
//

import XCTest

final class LockboxCryptorTests: XCTestCase {
    func testLockboxCryptorSmall() async {
        let id = UUID()
        let size = 10 // 10 Bytes
        let isExternal = false
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStore(lockerRoomURLProvider: urlProvider)
        
        let defaults = LockerRoomDefaultsMock()
        let remoteService = LockerRoomRemoteService(lockerRoomDefaults: defaults)
        
        let keyGenerator = LockboxKeyGenerator()
        let symmetricKeyData = keyGenerator.generateSymmetricKeyData()
        
        let fileManager = FileManager.default
        let decryptedContentURL = urlProvider.urlForLockboxUnencryptedContent(name: name)
        let decryptedContentPath = decryptedContentURL.path(percentEncoded: false)
        
        let cryptor = LockboxCryptor()
        
        guard let unencryptedContent = LockerRoomTestUtilities.createRandomData(size: size) else {
            XCTFail("Failed to create random unencrypted content")
            return
        }
        
        var diskImage = LockerRoomDiskImageMock(lockerRoomURLProvider: urlProvider)
        diskImage.unencryptedContent = unencryptedContent
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(id: id, name: name, size: unencryptedContent.count, isExternal: isExternal, lockerRoomDefaults: defaults,  lockerRoomDiskImage: diskImage, lockerRoomRemoteService: remoteService, lockerRoomStore: store) else {
            XCTFail("Failed to create unencrypted lockbox")
            return
        }
        
        guard await cryptor.encrypt(lockbox: unencryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            XCTFail("Failed to encrypt lockbox")
            return
        }
        
        guard let encryptedLockbox = EncryptedLockbox.create(id: id, name: name, size: size, isExternal: isExternal, encryptedSymmetricKeysBySerialNumber: [UInt32:Data](), encryptionLockboxKeys: [LockboxKey](), lockerRoomStore: store) else {
            XCTFail("Failed to create encrypted lockbox")
            return
        }

        guard await cryptor.decrypt(lockbox: encryptedLockbox, symmetricKeyData: symmetricKeyData) else {
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
    
    func testLockboxCryptorLarge() async {
        let id = UUID()
        let size = (1 * 1024 * 1024 * 1024) // 1GB
        let isExternal = false
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStore(lockerRoomURLProvider: urlProvider)
        
        let defaults = LockerRoomDefaultsMock()
        let remoteService = LockerRoomRemoteService(lockerRoomDefaults: defaults)
        
        let cryptor = LockboxCryptor()
        let keyGenerator = LockboxKeyGenerator()
        let symmetricKeyData = keyGenerator.generateSymmetricKeyData()
        
        let fileManager = FileManager.default
        let decryptedContentURL = urlProvider.urlForLockboxUnencryptedContent(name: name)
        let decryptedContentPath = decryptedContentURL.path(percentEncoded: false)
        
        guard let unencryptedContent = LockerRoomTestUtilities.createRandomData(size: size) else {
            XCTFail("Failed to create random unencrypted content")
            return
        }
        
        var diskImage = LockerRoomDiskImageMock(lockerRoomURLProvider: urlProvider)
        diskImage.unencryptedContent = unencryptedContent
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(id: id, name: name, size: unencryptedContent.count, isExternal: isExternal, lockerRoomDefaults: defaults, lockerRoomDiskImage: diskImage, lockerRoomRemoteService: remoteService, lockerRoomStore: store) else {
            XCTFail("Failed to create unencrypted lockbox")
            return
        }
        
        guard await cryptor.encrypt(lockbox: unencryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            XCTFail("Failed to encrypt lockbox")
            return
        }
        
        guard let encryptedLockbox = EncryptedLockbox.create(id: id, name: name, size: size, isExternal: isExternal, encryptedSymmetricKeysBySerialNumber: [UInt32:Data](), encryptionLockboxKeys: [LockboxKey](), lockerRoomStore: store) else {
            XCTFail("Failed to create encrypted lockbox")
            return
        }

        guard await cryptor.decrypt(lockbox: encryptedLockbox, symmetricKeyData: symmetricKeyData) else {
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
