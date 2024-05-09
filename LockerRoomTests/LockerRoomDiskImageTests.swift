//
//  LockerRoomDiskImageTests.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/9/24.
//

import XCTest

final class LockerRoomDiskImageTests: XCTestCase {
    func testDiskImageCreateAttachDetachDestroy() {
        let size = 10
        
        let urlProvider = LockerRoomURLProvider(rootURL: .temporaryDirectory)
        let diskImage = LockerRoomDiskImage(lockerRoomURLProvider: urlProvider)
        
        guard diskImage.create(name: name, size: size) else {
            XCTFail("Failed to create disk image")
            return
        }
        
        guard diskImage.attach(name: name) else {
            XCTFail("Failed to attach disk image")
            return
        }
        
        guard diskImage.detach(name: name) else {
            XCTFail("Failed to detach disk image")
            return
        }
        
        guard diskImage.destory(name: name) else {
            XCTFail("Failed to destory disk image")
            return
        }
    }
}
