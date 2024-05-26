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
        
        defer {
            XCTAssertTrue(diskController.destory(name: name), "Failed to destory disk")
        }
        
        let size = 10
        
        guard diskController.create(name: name, size: size) else {
            XCTFail("Failed to create disk image")
            return
        }
    }
    
    func testDiskCreateAttachDetachDestroy() {
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let diskController = LockerRoomDiskController(lockerRoomURLProvider: urlProvider)
        
        defer {
            XCTAssertTrue(diskController.destory(name: name), "Failed to destory disk")
        }
        
        let size = 10
        
        guard diskController.create(name: name, size: size) else {
            XCTFail("Failed to create disk image")
            return
        }
        
        guard diskController.attach(name: name) else {
            XCTFail("Failed to attach disk")
            return
        }
        
        guard diskController.detach(name: name) else {
            XCTFail("Failed to detach disk")
            return
        }
    }
    
    func testDiskCreateAttachUnmountDestroy() {
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let diskController = LockerRoomDiskController(lockerRoomURLProvider: urlProvider)
        
        defer {
            XCTAssertTrue(diskController.destory(name: name), "Failed to destory disk")
        }
        
        let size = 10
        
        guard diskController.create(name: name, size: size) else {
            XCTFail("Failed to create disk image")
            return
        }
        
        guard diskController.attach(name: name) else {
            XCTFail("Failed to attach disk")
            return
        }
        
        guard diskController.unmount(name: name) else {
            XCTFail("Failed to unmount disk")
            return
        }
    }
}
