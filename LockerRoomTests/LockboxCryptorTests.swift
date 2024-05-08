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
        var diskImage = LockerRoomDiskImageMock(lockerRoomURLProvider: urlProvider)
        
        let keyGenerator = LockboxKeyGenerator()
        let symmetricKeyData = keyGenerator.generateSymmetricKeyData()
        
        let fileManager = FileManager.default
        let decryptedContentURL = urlProvider.urlForLockboxUnencryptedContent(name: name)
        let decryptedContentPath = decryptedContentURL.path(percentEncoded: false)
        
        let cryptor = LockboxCryptor()
        
        guard let unencryptedContent = createRandomData(size: size) else {
            XCTFail("Failed to create random unencrypted content")
            return
        }
        
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
        var diskImage = LockerRoomDiskImageMock(lockerRoomURLProvider: urlProvider)
        
        let cryptor = LockboxCryptor()
        let keyGenerator = LockboxKeyGenerator()
        let symmetricKeyData = keyGenerator.generateSymmetricKeyData()
        
        let fileManager = FileManager.default
        let decryptedContentURL = urlProvider.urlForLockboxUnencryptedContent(name: name)
        let decryptedContentPath = decryptedContentURL.path(percentEncoded: false)
        
        guard let unencryptedContent = createRandomData(size: size) else {
            XCTFail("Failed to create random unencrypted content")
            return
        }
        
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
    
    private func createRandomData(size: Int) -> Data? {
        var randomData = Data(count: size)
        
        let randomSuccess = randomData.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                print("Failed to get buffer base address")
                return false
            }
            
            guard SecRandomCopyBytes(kSecRandomDefault, size, baseAddress) == 0 else {
                print("Failed to copy random bytes into buffer")
                return false
            }
            
            return true
        }
        
        guard randomSuccess else {
            print("Failed to generate random data")
            return nil
        }
        
        return randomData
    }
}
