//
//  LockboxCryptorTests.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/5/24.
//

import XCTest

final class LockboxCryptorTests: XCTestCase {
    func testLockboxCryptorSmall() {
        let id = UUID()
        let size = 10 // 10 Bytes
        let isExternal = false
        let volumeCount = 1
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStore(lockerRoomURLProvider: urlProvider)
        
        let defaults = LockerRoomDefaultsMock()
        let remoteService = LockerRoomRemoteService(lockerRoomDefaults: defaults)
        
        let keyGenerator = LockboxKeyGenerator()
        let symmetricKeyData = keyGenerator.generateSymmetricKeyData()
        
        let fileManager = FileManager.default
        let decryptedContentURL = urlProvider.urlForLockboxUnencryptedContent(name: name)
        let decryptedContentPath = decryptedContentURL.path(percentEncoded: false)
        
        let cryptor = LockboxCryptor(lockerRoomDefaults: defaults)
        
        guard let unencryptedContent = LockerRoomTestUtilities.createRandomData(size: size) else {
            XCTFail("Failed to create random unencrypted content")
            return
        }
        
        var diskController = LockerRoomDiskControllerMock(lockerRoomURLProvider: urlProvider)
        diskController.unencryptedContent = unencryptedContent
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(id: id, name: name, size: unencryptedContent.count, isExternal: isExternal, volumeCount: volumeCount, lockerRoomDefaults: defaults,  lockerRoomDiskController: diskController, lockerRoomRemoteService: remoteService, lockerRoomStore: store) else {
            XCTFail("Failed to create unencrypted lockbox")
            return
        }
        
        guard cryptor.encrypt(lockbox: unencryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            XCTFail("Failed to encrypt lockbox")
            return
        }
        
        guard let encryptedLockbox = EncryptedLockbox.create(id: id, name: name, size: size, isExternal: isExternal, volumeCount: volumeCount, encryptedSymmetricKeysBySerialNumber: [UInt32:Data](), encryptionComponents: LockboxCryptorComponents(), encryptionLockboxKeys: [LockboxKey](), lockerRoomStore: store) else {
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
        let id = UUID()
        let size = (1 * 1024 * 1024 * 1024) // 1GB
        let isExternal = false
        let volumeCount = 1
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStore(lockerRoomURLProvider: urlProvider)
        
        let defaults = LockerRoomDefaultsMock()
        let remoteService = LockerRoomRemoteService(lockerRoomDefaults: defaults)
        
        let cryptor = LockboxCryptor(lockerRoomDefaults: defaults)
        let keyGenerator = LockboxKeyGenerator()
        let symmetricKeyData = keyGenerator.generateSymmetricKeyData()
        
        let fileManager = FileManager.default
        let decryptedContentURL = urlProvider.urlForLockboxUnencryptedContent(name: name)
        let decryptedContentPath = decryptedContentURL.path(percentEncoded: false)
        
        guard let unencryptedContent = LockerRoomTestUtilities.createRandomData(size: size) else {
            XCTFail("Failed to create random unencrypted content")
            return
        }
        
        var diskController = LockerRoomDiskControllerMock(lockerRoomURLProvider: urlProvider)
        diskController.unencryptedContent = unencryptedContent
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(id: id, name: name, size: unencryptedContent.count, isExternal: isExternal, volumeCount: volumeCount, lockerRoomDefaults: defaults, lockerRoomDiskController: diskController, lockerRoomRemoteService: remoteService, lockerRoomStore: store) else {
            XCTFail("Failed to create unencrypted lockbox")
            return
        }
        
        guard cryptor.encrypt(lockbox: unencryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            XCTFail("Failed to encrypt lockbox")
            return
        }
        
        guard let encryptedLockbox = EncryptedLockbox.create(id: id, name: name, size: size, isExternal: isExternal, volumeCount: volumeCount, encryptedSymmetricKeysBySerialNumber: [UInt32:Data](), encryptionComponents: LockboxCryptorComponents(), encryptionLockboxKeys: [LockboxKey](), lockerRoomStore: store) else {
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
    
    func testLockboxCryptorExtractingComponentsSmall() {
        let id = UUID()
        let size = 10 // 10 Bytes
        let isExternal = false
        let volumeCount = 1
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStore(lockerRoomURLProvider: urlProvider)
        
        let defaults = LockerRoomDefaultsMock()
        let remoteService = LockerRoomRemoteService(lockerRoomDefaults: defaults)
        
        let keyGenerator = LockboxKeyGenerator()
        let symmetricKeyData = keyGenerator.generateSymmetricKeyData()
        
        let fileManager = FileManager.default
        let decryptedContentURL = urlProvider.urlForLockboxUnencryptedContent(name: name)
        let decryptedContentPath = decryptedContentURL.path(percentEncoded: false)
        
        let cryptor = LockboxCryptor(lockerRoomDefaults: defaults)
        
        guard let unencryptedContent = LockerRoomTestUtilities.createRandomData(size: size) else {
            XCTFail("Failed to create random unencrypted content")
            return
        }
        
        var diskController = LockerRoomDiskControllerMock(lockerRoomURLProvider: urlProvider)
        diskController.unencryptedContent = unencryptedContent
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(id: id, name: name, size: unencryptedContent.count, isExternal: isExternal, volumeCount: volumeCount, lockerRoomDefaults: defaults,  lockerRoomDiskController: diskController, lockerRoomRemoteService: remoteService, lockerRoomStore: store) else {
            XCTFail("Failed to create unencrypted lockbox")
            return
        }
        
        guard let components = cryptor.encryptExtractingComponents(lockbox: unencryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            XCTFail("Failed to encrypt lockbox extracting components")
            return
        }
        
        guard let encryptedLockbox = EncryptedLockbox.create(id: id, name: name, size: size, isExternal: isExternal, volumeCount: volumeCount, encryptedSymmetricKeysBySerialNumber: [UInt32:Data](), encryptionComponents: components, encryptionLockboxKeys: [LockboxKey](), lockerRoomStore: store) else {
            XCTFail("Failed to create encrypted lockbox")
            return
        }

        guard cryptor.decryptWithComponents(lockbox: encryptedLockbox, symmetricKeyData: symmetricKeyData, components: components) else {
            XCTFail("Failed to decrypt lockbox with components")
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
    
    func testLockboxCryptorExtractingComponentsLarge() {
        let id = UUID()
        let size = (1 * 1024 * 1024 * 1024) // 1GB
        let isExternal = false
        let volumeCount = 1
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStore(lockerRoomURLProvider: urlProvider)
        
        let defaults = LockerRoomDefaultsMock()
        let remoteService = LockerRoomRemoteService(lockerRoomDefaults: defaults)
        
        let keyGenerator = LockboxKeyGenerator()
        let symmetricKeyData = keyGenerator.generateSymmetricKeyData()
        
        let fileManager = FileManager.default
        let decryptedContentURL = urlProvider.urlForLockboxUnencryptedContent(name: name)
        let decryptedContentPath = decryptedContentURL.path(percentEncoded: false)
        
        let cryptor = LockboxCryptor(lockerRoomDefaults: defaults)
        
        guard let unencryptedContent = LockerRoomTestUtilities.createRandomData(size: size) else {
            XCTFail("Failed to create random unencrypted content")
            return
        }
        
        var diskController = LockerRoomDiskControllerMock(lockerRoomURLProvider: urlProvider)
        diskController.unencryptedContent = unencryptedContent
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(id: id, name: name, size: unencryptedContent.count, isExternal: isExternal, volumeCount: volumeCount, lockerRoomDefaults: defaults,  lockerRoomDiskController: diskController, lockerRoomRemoteService: remoteService, lockerRoomStore: store) else {
            XCTFail("Failed to create unencrypted lockbox")
            return
        }
        
        guard let components = cryptor.encryptExtractingComponents(lockbox: unencryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            XCTFail("Failed to encrypt lockbox extracting components")
            return
        }
        
        guard let encryptedLockbox = EncryptedLockbox.create(id: id, name: name, size: size, isExternal: isExternal, volumeCount: volumeCount, encryptedSymmetricKeysBySerialNumber: [UInt32:Data](), encryptionComponents: components, encryptionLockboxKeys: [LockboxKey](), lockerRoomStore: store) else {
            XCTFail("Failed to create encrypted lockbox")
            return
        }

        guard cryptor.decryptWithComponents(lockbox: encryptedLockbox, symmetricKeyData: symmetricKeyData, components: components) else {
            XCTFail("Failed to decrypt lockbox with components")
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
