//
//  UnencryptedLockboxTests.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/8/24.
//

import XCTest

final class UnencryptedLockboxTests: XCTestCase {
    func testCreateUnencryptedLockbox() {
        let id = UUID()
        let size = 10
        let isExternal = false
        let volumeCount = 1
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        let defaults = LockerRoomDefaultsMock()
        let diskController = LockerRoomDiskControllerMock(lockerRoomURLProvider: urlProvider)
        let remoteService = LockerRoomRemoteService(lockerRoomDefaults: defaults)
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(
            id: id,
            name: name,
            size: size,
            isExternal: isExternal,
            volumeCount: volumeCount,
            lockerRoomDefaults: defaults,
            lockerRoomDiskController: diskController,
            lockerRoomRemoteService: remoteService,
            lockerRoomStore: store
        ) else {
            XCTFail("Failed to create unencrypted lockbox")
            return
        }
        
        XCTAssertEqual(unencryptedLockbox.metadata.id, id)
        XCTAssertEqual(unencryptedLockbox.metadata.name, name)
        XCTAssertEqual(unencryptedLockbox.metadata.size, size)
        XCTAssertEqual(unencryptedLockbox.metadata.isExternal, isExternal)
        XCTAssertEqual(unencryptedLockbox.metadata.volumeCount, volumeCount)
        XCTAssertFalse(unencryptedLockbox.metadata.isEncrypted)
    }
    
    func testCreateUnencryptedLockboxFromLockerRoomLockbox() {
        let id = UUID()
        let size = 10
        let isEncrypted = false
        let isExternal = false
        let volumeCount = 1
        
        let lockerRoomLockbox = LockerRoomLockbox(id: id, name: name, size: size, isEncrypted: isEncrypted, isExternal: isExternal, encryptionKeyNames: [String]())
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.unencryptedLockboxMetadata = UnencryptedLockbox.Metadata(
            id: id,
            name: name,
            size: size,
            isEncrypted: isEncrypted,
            isExternal: isExternal,
            volumeCount: volumeCount
        )
                
        guard let unencryptedLockbox = UnencryptedLockbox.create(from: lockerRoomLockbox,  lockerRoomStore: store) else {
            XCTFail("Failed to create unencrypted lockbox")
            return
        }
        
        XCTAssertEqual(unencryptedLockbox.metadata.id, id)
        XCTAssertEqual(unencryptedLockbox.metadata.name, name)
        XCTAssertEqual(unencryptedLockbox.metadata.size, size)
        XCTAssertEqual(unencryptedLockbox.metadata.isEncrypted, isExternal)
        XCTAssertEqual(unencryptedLockbox.metadata.isExternal, isExternal)
        XCTAssertEqual(unencryptedLockbox.metadata.volumeCount, volumeCount)
    }
    
    func testDestroyUnencryptedLockbox() {
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        
        guard UnencryptedLockbox.destroy(name: name, lockerRoomStore: store) else {
            XCTFail("Failed to destroy unencrypted lockbox")
            return
        }
    }
    
    func testCreateUnencryptedLockboxAlreadyExistsFailure() {
        let id = UUID()
        let size = 10
        let isExternal = false
        let volumeCount = 1
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let defaults = LockerRoomDefaultsMock()
        let diskController = LockerRoomDiskControllerMock(lockerRoomURLProvider: urlProvider)
        let remoteService = LockerRoomRemoteService(lockerRoomDefaults: defaults)
        
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.lockboxExists = true
        
        let unencryptedLockbox = UnencryptedLockbox.create(
            id: id,
            name: name,
            size: size,
            isExternal: isExternal,
            volumeCount: volumeCount,
            lockerRoomDefaults: defaults,
            lockerRoomDiskController: diskController,
            lockerRoomRemoteService: remoteService,
            lockerRoomStore: store
        )
        
        XCTAssertNil(unencryptedLockbox)
    }
    
    func testCreateUnencryptedLockboxInvalidSizeFailure() {
        let id = UUID()
        let size = 0
        let isExternal = false
        let volumeCount = 1
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        let defaults = LockerRoomDefaultsMock()
        let diskController = LockerRoomDiskControllerMock(lockerRoomURLProvider: urlProvider)
        let remoteService = LockerRoomRemoteService(lockerRoomDefaults: defaults)
        
        let unencryptedLockbox = UnencryptedLockbox.create(
            id: id,
            name: name,
            size: size,
            isExternal: isExternal,
            volumeCount: volumeCount,
            lockerRoomDefaults: defaults,
            lockerRoomDiskController: diskController,
            lockerRoomRemoteService: remoteService,
            lockerRoomStore: store
        )
        
        XCTAssertNil(unencryptedLockbox)
    }
    
    func testCreateUnencryptedLockboxDiskControllerFailure() {
        let id = UUID()
        let size = 10
        let isExternal = false
        let volumeCount = 1
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        let defaults = LockerRoomDefaultsMock()
        let remoteService = LockerRoomRemoteService(lockerRoomDefaults: defaults)
        
        var diskController = LockerRoomDiskControllerMock(lockerRoomURLProvider: urlProvider)
        diskController.failToCreate = true
        
        let unencryptedLockbox = UnencryptedLockbox.create(
            id: id,
            name: name,
            size: size,
            isExternal: isExternal,
            volumeCount: volumeCount,
            lockerRoomDefaults: defaults,
            lockerRoomDiskController: diskController,
            lockerRoomRemoteService: remoteService,
            lockerRoomStore: store
        )
        
        XCTAssertNil(unencryptedLockbox)
    }
    
    func testCreateUnencryptedLockboxWriteMetadataFailure() {
        let id = UUID()
        let size = 10
        let isExternal = false
        let volumeCount = 1
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let defaults = LockerRoomDefaultsMock()
        let diskController = LockerRoomDiskControllerMock(lockerRoomURLProvider: urlProvider)
        let remoteService = LockerRoomRemoteService(lockerRoomDefaults: defaults)
        
        var store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        store.failToWriteUnencryptedLockboxMetadata = true
        
        let unencryptedLockbox = UnencryptedLockbox.create(
            id: id,
            name: name,
            size: size,
            isExternal: isExternal,
            volumeCount: volumeCount,
            lockerRoomDefaults: defaults,
            lockerRoomDiskController: diskController,
            lockerRoomRemoteService: remoteService,
            lockerRoomStore: store
        )
        
        XCTAssertNil(unencryptedLockbox)
    }
    
    func testCreateUnencryptedLockboxFromLockerRoomLockboxIsEncryptedFailure() {
        let id = UUID()
        let size = 10
        let isEncrypted = true
        let isExternal = false
        
        let lockerRoomLockbox = LockerRoomLockbox(id: id, name: name, size: size, isEncrypted: isEncrypted, isExternal: isExternal, encryptionKeyNames: [String]())
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let store = LockerRoomStoreMock(lockerRoomURLProvider: urlProvider)
        
        let unencryptedLockbox = UnencryptedLockbox.create(from: lockerRoomLockbox, lockerRoomStore: store)
        
        XCTAssertNil(unencryptedLockbox)
    }
    
    func testCreateUnencryptedLockboxFromLockerRoomLockboxReadMetadataFailure() {
        let id = UUID()
        let size = 10
        let isEncrypted = false
        let isExternal = false
        
        let lockerRoomLockbox = LockerRoomLockbox(id: id, name: name, size: size, isEncrypted: isEncrypted, isExternal: isExternal, encryptionKeyNames: [String]())
        
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
