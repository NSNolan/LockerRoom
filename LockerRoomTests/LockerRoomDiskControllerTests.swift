//
//  LockerRoomDiskControllerTests.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/9/24.
//

import XCTest

final class LockerRoomDiskControllerTests: XCTestCase {
    func testDiskCreateDestroy() {
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let diskController = LockerRoomDiskController(lockerRoomURLProvider: urlProvider)
        let store = LockerRoomStore(lockerRoomURLProvider: urlProvider)
        
        defer {
            XCTAssertTrue(diskController.destory(name: name), "Failed to destory disk")
            XCTAssertTrue(store.removeLockbox(name: name), "Failed to remove lockbox")
        }
        
        let size = 10
        
        XCTAssertTrue(diskController.create(name: name, size: size), "Failed to create disk image")
    }
    
    func testDiskCreateAttachOpenDetachDestroy() {
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let diskController = LockerRoomDiskController(lockerRoomURLProvider: urlProvider)
        let store = LockerRoomStore(lockerRoomURLProvider: urlProvider)
        
        defer {
            XCTAssertTrue(diskController.destory(name: name), "Failed to destory disk")
            XCTAssertTrue(store.removeLockbox(name: name), "Failed to remove lockbox")
        }
        
        let size = 10
        
        XCTAssertTrue(diskController.create(name: name, size: size), "Failed to create disk image")
        XCTAssertTrue(diskController.attach(name: name), "Failed to attach disk")
        XCTAssertTrue(diskController.open(name: name), "Failed to open disk")
        XCTAssertTrue(diskController.detach(name: name), "Failed to detach disk")
    }
    
    func testDiskCreateAttachVerifyDetachDestroy() {
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let diskController = LockerRoomDiskController(lockerRoomURLProvider: urlProvider)
        let store = LockerRoomStore(lockerRoomURLProvider: urlProvider)
        
        defer {
            XCTAssertTrue(diskController.destory(name: name), "Failed to destory disk")
            XCTAssertTrue(store.removeLockbox(name: name), "Failed to remove lockbox")
        }
        
        let size = 10
        
        XCTAssertTrue(diskController.create(name: name, size: size), "Failed to create disk image")
        XCTAssertTrue(diskController.attach(name: name), "Failed to attach disk")
        XCTAssertTrue(diskController.verify(name: name, usingMountedVolume: true), "Failed to verify disk")
        XCTAssertTrue(diskController.detach(name: name), "Failed to detach disk")
    }
}
