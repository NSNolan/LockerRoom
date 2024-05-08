//
//  UnencryptedLockboxTests.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/8/24.
//

import XCTest

final class UnencryptedLockboxTests: XCTestCase {
    func testCreateUnencryptedLockbox() {
        let size = 10
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        let diskImage = LockerRoomDiskImageMock(lockerRoomURLProvider: urlProvider)
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(
            name: name, 
            size: size,
            lockerRoomDiskImage: diskImage,
            lockerRoomStore: store
        ) else {
            XCTFail("Failed to create unencrypted lockbox")
            return
        }
        
        XCTAssertEqual(unencryptedLockbox.metadata.name, name)
        XCTAssertEqual(unencryptedLockbox.metadata.size, size)
        XCTAssertFalse(unencryptedLockbox.metadata.isEncrypted)
    }
    
    func testCreateUnencryptedLockboxFromLockerRoomLockbox() {
        let size = 10
        let isEncrypted = false
        
        let lockerRoomLockbox = LockerRoomLockbox(name: name, size: size, isEncrypted: isEncrypted, encryptionKeyNames: [String]())
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.unencryptedLockboxMetadata = UnencryptedLockbox.Metadata(name: name, size: size, isEncrypted: isEncrypted)
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(from: lockerRoomLockbox, lockerRoomStore: store) else {
            XCTFail("Failed to create unencrypted lockbox")
            return
        }
        
        XCTAssertEqual(unencryptedLockbox.metadata.name, name)
        XCTAssertEqual(unencryptedLockbox.metadata.size, size)
        XCTAssertEqual(unencryptedLockbox.metadata.isEncrypted, isEncrypted)
    }
    
    func testDestroyUnencryptedLockbox() {
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        
        guard UnencryptedLockbox.destroy(name: name, lockerRoomStore: store) else {
            XCTFail("Failed to destroy unencrypted lockbox")
            return
        }
    }
    
    func testCreateUnencryptedLockboxInvalidSizeFailure() {
        let size = 0
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        let diskImage = LockerRoomDiskImageMock(lockerRoomURLProvider: urlProvider)
        
        let unencryptedLockbox = UnencryptedLockbox.create(
            name: name,
            size: size,
            lockerRoomDiskImage: diskImage,
            lockerRoomStore: store
        )
        
        XCTAssertNil(unencryptedLockbox)
    }
    
    func testCreateUnencryptedLockboxDiskImageFailure() {
        let size = 10
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        var diskImage = LockerRoomDiskImageMock(lockerRoomURLProvider: urlProvider)
        diskImage.failToCreate = true
        
        let unencryptedLockbox = UnencryptedLockbox.create(
            name: name,
            size: size,
            lockerRoomDiskImage: diskImage,
            lockerRoomStore: store
        )
        
        XCTAssertNil(unencryptedLockbox)
    }
    
    func testCreateUnencryptedLockboxWriteMetadataFailure() {
        let size = 10
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.failToWriteUnencryptedLockboxMetadata = true
        let diskImage = LockerRoomDiskImageMock(lockerRoomURLProvider: urlProvider)
        
        let unencryptedLockbox = UnencryptedLockbox.create(
            name: name,
            size: size,
            lockerRoomDiskImage: diskImage,
            lockerRoomStore: store
        )
        
        XCTAssertNil(unencryptedLockbox)
    }
    
    func testCreateUnencryptedLockboxFromLockerRoomLockboxIsEncryptedFailure() {
        let size = 10
        let isEncrypted = true
        
        let lockerRoomLockbox = LockerRoomLockbox(name: name, size: size, isEncrypted: isEncrypted, encryptionKeyNames: [String]())
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        
        let unencryptedLockbox = UnencryptedLockbox.create(from: lockerRoomLockbox, lockerRoomStore: store)
        
        XCTAssertNil(unencryptedLockbox)
    }
    
    func testCreateUnencryptedLockboxFromLockerRoomLockboxReadMetadataFailure() {
        let size = 10
        let isEncrypted = false
        
        let lockerRoomLockbox = LockerRoomLockbox(name: name, size: size, isEncrypted: isEncrypted, encryptionKeyNames: [String]())
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.failToReadUnencryptedLockboxMetadata = true
        
        let unencryptedLockbox = UnencryptedLockbox.create(from: lockerRoomLockbox, lockerRoomStore: store)
        
        XCTAssertNil(unencryptedLockbox)
    }
    
    func testDestroyUnencryptedLockboxRemoveFailure() {
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.failToRemoveLockbox = true
        
        let destroySuccess = UnencryptedLockbox.destroy(name: name, lockerRoomStore: store)
        
        XCTAssertFalse(destroySuccess)
    }
}
